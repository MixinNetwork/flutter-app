import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as cr;
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/padded_block_cipher/padded_block_cipher_impl.dart';
import 'package:pointycastle/paddings/pkcs7.dart';
import 'package:tuple/tuple.dart';

import '../../utils/load_balancer_utils.dart';
import '../../utils/logger.dart';

class AttachmentOutputCipher {
  AttachmentOutputCipher(this._inputStream, List<int> keys, List<int> iv) {
    final aesKey = keys.sublist(0, 32);
    final macKey = keys.sublist(32, 64);
    final mac = cr.Hmac(cr.sha256, macKey);
    _macOutput = AccumulatorSink<cr.Digest>();
    _macSink = mac.startChunkedConversion(_macOutput);

    final cbcCipher = CBCBlockCipher(AESFastEngine());
    final ivParams = ParametersWithIV<KeyParameter>(
        KeyParameter(Uint8List.fromList(aesKey)), Uint8List.fromList(iv));
    final paddingParams =
        // ignore: prefer_void_to_null
        PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
            ivParams, null);
    _aesCipher = PaddedBlockCipherImpl(PKCS7Padding(), cbcCipher)
      ..init(true, paddingParams);

    _digestOutput = AccumulatorSink<cr.Digest>();
    _digestSink = cr.sha256.startChunkedConversion(_digestOutput);

    _macSink.add(iv);
    _digestSink.add(iv);
    _streamController = StreamController<List<int>>(onCancel: () {
      _macSink.close();
      _digestSink.close();
    })
      ..add(iv);
  }

  Stream<List<int>> get stream => _streamController.stream;

  Future<List<int>> process() async {
    d('cipher stream start');
    await _streamController.addStream(
      _inputStream.asyncMap((List<int> event) async {
        final uint8list =
            await runLoadBalancer(_process, Tuple2(_aesCipher, event));
        _macSink.add(uint8list);
        _digestSink.add(uint8list);

        return uint8list.toList();
      }),
      cancelOnError: true,
    );

    _macSink.close();

    final mac = _macOutput.events.single.bytes;
    _digestSink
      ..add(mac)
      ..close();
    _streamController.add(mac);
    await _streamController.close();
    d('cipher stream closed');
    final digest = _digestOutput.events.single.bytes;
    return digest;
  }

  late final StreamController<List<int>> _streamController;
  final Stream<List<int>> _inputStream;
  late final PaddedBlockCipher _aesCipher;
  late final AccumulatorSink<cr.Digest> _macOutput;
  late final ByteConversionSink _macSink;
  late final AccumulatorSink<cr.Digest> _digestOutput;
  late final ByteConversionSink _digestSink;

  static int getCiphertextLength(int plaintextLength) =>
      (16 + (((plaintextLength ~/ 16) + 1) * 16) + 32).toInt();
}

Uint8List _process(Tuple2<PaddedBlockCipher, List<int>> argument) {
  final stopwatch = Stopwatch()..start();
  final uint8list = argument.item1.process(Uint8List.fromList(argument.item2));
  stopwatch.stop();
  d('_process: ${stopwatch.elapsedMilliseconds}');
  return uint8list;
}

Uint8List _processBlocks(Tuple2<PaddedBlockCipher, List<int>> argument) =>
    _processBlock(argument.item1, Uint8List.fromList(argument.item2));

Uint8List _processBlock(PaddedBlockCipher cipher, Uint8List input) {
  final stopwatch = Stopwatch()..start();
  final output = Uint8List(input.lengthInBytes);
  for (var offset = 0; offset < input.lengthInBytes;) {
    offset += cipher.processBlock(input, offset, output, offset);
  }
  stopwatch.stop();
  d('_processBlock: ${stopwatch.elapsedMilliseconds}');
  return output;
}

PaddedBlockCipher getAesCipher(
    CBCBlockCipher cbcCipher, List<int> aesKey, List<int> iv) {
  final ivParams = ParametersWithIV<KeyParameter>(
      KeyParameter(Uint8List.fromList(aesKey)), Uint8List.fromList(iv));
  final paddingParams =
      // ignore: prefer_void_to_null
      PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
          ivParams, null);
  return PaddedBlockCipherImpl(PKCS7Padding(), cbcCipher)
    ..init(true, paddingParams);
}

extension EncryptStreamExtension on Stream<List<int>> {
  Stream<List<int>> encrypt(
    List<int> keys,
    List<int> iv,
    void Function(List<int>) digestCallback,
  ) {
    if (isBroadcast) throw ArgumentError('Stream must be not broadcast.');

    final aesKey = keys.sublist(0, 32);
    final macKey = keys.sublist(32, 64);
    final mac = cr.Hmac(cr.sha256, macKey);
    final macOutput = AccumulatorSink<cr.Digest>();
    final macSink = mac.startChunkedConversion(macOutput);

    final cbcCipher = CBCBlockCipher(AESFastEngine());
    var _aesCipher = getAesCipher(cbcCipher, aesKey, iv);

    final digestOutput = AccumulatorSink<cr.Digest>();
    final digestSink = cr.sha256.startChunkedConversion(digestOutput);

    macSink.add(iv);
    digestSink.add(iv);

    final controller = StreamController<List<int>>()..add(iv);

    void close() {
      macSink.close();
      digestSink.close();
    }

    void addError(Object error, [StackTrace? stackTrace]) {
      close();
      controller.addError(error, stackTrace);
    }

    controller.onListen = () {
      final subscription = listen(
        null, onError: addError, // Avoid Zone error replacement.
        onDone: () {
          macSink.close();
          final mac = macOutput.events.single.bytes;
          digestSink
            ..add(mac)
            ..close();
          controller
            ..add(mac)
            ..close();
          digestCallback(digestOutput.events.single.bytes);
        },
      );

      final pause = subscription.pause;
      final resume = subscription.resume;

      var lastBlock = iv;
      Future<List<int>> process(List<int> event) async {
        Uint8List ciphertext;
        _aesCipher = getAesCipher(cbcCipher, aesKey, lastBlock);
        if (event.length < 65536) {
          ciphertext =
              await runLoadBalancer(_process, Tuple2(_aesCipher, event));
        } else {
          ciphertext =
              await runLoadBalancer(_processBlocks, Tuple2(_aesCipher, event));
        }
        final stopwatch = Stopwatch()..start();
        macSink.add(ciphertext);
        digestSink.add(ciphertext);
        stopwatch.stop();

        d('add ${stopwatch.elapsedMilliseconds}');

        final result = ciphertext.toList();
        lastBlock = result.sublist(result.length - 16, result.length);
        return result;
      }

      subscription.onData((List<int> event) {
        pause();
        process(event)
            .then(controller.add, onError: addError)
            .whenComplete(resume);
      });
      controller
        ..onCancel = () {
          close();
          subscription.cancel();
        }
        ..onPause = pause
        ..onResume = resume;
    };
    return controller.stream;
  }
}
