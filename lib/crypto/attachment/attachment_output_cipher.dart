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
    d('cipher stream start done');
    // await _streamController.done;
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
      (16 + (((plaintextLength / 16) + 1) * 16) + 32).toInt();
}

Uint8List _process(Tuple2<PaddedBlockCipher, List<int>> argument) =>
    argument.item1.process(Uint8List.fromList(argument.item2));
