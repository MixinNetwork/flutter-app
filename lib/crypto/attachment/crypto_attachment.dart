import 'dart:async';
import 'dart:core';
import 'dart:typed_data';

import 'package:chunked_stream/chunked_stream.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as cr;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/padded_block_cipher/padded_block_cipher_impl.dart';
import 'package:pointycastle/paddings/pkcs7.dart';
import 'package:tuple/tuple.dart';

import '../../utils/crypto_util.dart';

const int _blockSize = 64 * 1024;

class CryptoAttachment {
  List<int> decryptAttachment(
      List<int> encryptedBin, List<int> keys, List<int> theirDigest) {
    final digest = _calculateDigest(encryptedBin);
    if (!listEquals(digest, theirDigest)) {
      throw Exception('Invalid digest');
    }

    final aesKey = keys.sublist(0, 32);
    final macKey = keys.sublist(32, 64);

    final iv = encryptedBin.sublist(0, 16);
    final cipherText = encryptedBin.sublist(16, encryptedBin.length - 32);
    final ivAndCipherText = encryptedBin.sublist(0, encryptedBin.length - 32);
    final mac =
        encryptedBin.sublist(encryptedBin.length - 32, encryptedBin.length);
    final verify = _sign(macKey, ivAndCipherText);
    if (!listEquals(verify, mac)) {
      throw Exception('Verification does not pass');
    }
    return aesDecrypt(aesKey, iv, cipherText);
  }

  List<int> _calculateDigest(List<int> data) {
    final digest = sha256.convert(data);
    return digest.bytes;
  }

  List<int> _sign(List<int> key, List<int> data) {
    final digest = Hmac(sha256, key).convert(data);
    return digest.bytes;
  }

  Tuple2<List<int>, List<int>> encryptAttachment(
      List<int> plainText, List<int> keys, List<int> iv) {
    final aesKey = keys.sublist(0, 32);
    final macKey = keys.sublist(32, 64);
    final ivAndCipherText = aesEncrypt(aesKey, plainText, iv);
    final mac = Hmac(sha256, macKey).convert(ivAndCipherText).bytes;
    final encryptedBin = [...ivAndCipherText, ...mac];
    final digest = _calculateDigest(encryptedBin);
    return Tuple2(encryptedBin, digest);
  }
}

PaddedBlockCipher _getAesCipher(
  CBCBlockCipher cbcCipher,
  List<int> aesKey,
  List<int> iv,
) {
  final ivParams = ParametersWithIV<KeyParameter>(
      KeyParameter(Uint8List.fromList(aesKey)), Uint8List.fromList(iv));
  final paddingParams =
      // ignore: prefer_void_to_null
      PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
          ivParams, null);
  return PaddedBlockCipherImpl(PKCS7Padding(), cbcCipher)
    ..init(true, paddingParams);
}

extension EncryptAttachmentStreamExtension on Stream<List<int>> {
  Stream<List<int>> encrypt(
    List<int> keys,
    List<int> iv,
    void Function(List<int>) digestCallback,
  ) =>
      bufferChunkedStream(this, bufferSize: _blockSize)
          ._encrypt(keys, iv, digestCallback);

  Stream<List<int>> _encrypt(
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
    var _aesCipher = _getAesCipher(cbcCipher, aesKey, iv);

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
        null,
        onError: addError,
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
        _aesCipher = _getAesCipher(cbcCipher, aesKey, lastBlock);
        final input = Uint8List.fromList(event);
        if (event.length < _blockSize) {
          ciphertext = _aesCipher.process(input);
        } else {
          ciphertext = Uint8List(input.lengthInBytes);
          for (var offset = 0; offset < input.lengthInBytes;) {
            offset +=
                _aesCipher.processBlock(input, offset, ciphertext, offset);
          }
        }
        macSink.add(ciphertext);
        digestSink.add(ciphertext);

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
