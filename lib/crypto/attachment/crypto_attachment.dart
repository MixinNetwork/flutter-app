import 'dart:async';
import 'dart:core';
import 'dart:typed_data';

import 'package:async/async.dart';
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
import '../../utils/logger.dart';

const int _blockSize = 64 * 1024;
const int _macSize = 32;
const int _cbcBlockSize = 16;

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
  bool forEncryption,
) {
  final ivParams = ParametersWithIV<KeyParameter>(
      KeyParameter(Uint8List.fromList(aesKey)), Uint8List.fromList(iv));
  final paddingParams =
      // ignore: prefer_void_to_null
      PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
          ivParams, null);
  return PaddedBlockCipherImpl(PKCS7Padding(), cbcCipher)
    ..init(forEncryption, paddingParams);
}

extension _StreamExtension on Stream<List<int>> {
  Stream<List<int>> chunkSize([int chunkSize = _blockSize]) {
    final streamController = StreamController<List<int>>();
    final chunkedStreamReader = ChunkedStreamReader(this);

    Future<void>? future;
    late Future<void> Function() addChunk;
    var pending = false;

    void updateFuture() => future = addChunk();

    addChunk = () async {
      if (streamController.isClosed) return;
      if (pending) return;

      pending = true && !streamController.isPaused;

      final chunk = await chunkedStreamReader.readChunk(chunkSize);
      if (streamController.isClosed) return;
      streamController.add(chunk);
      pending = false;

      future = null;
      if (chunk.length < chunkSize) {
        await streamController.close();
        return;
      }
      if (streamController.isPaused) return;
      updateFuture();
    };

    streamController
      ..onResume = (() {
        if (pending) return;
        if (future == null) return updateFuture();
        future?.whenComplete(updateFuture);
      })
      ..onListen = updateFuture;

    return streamController.stream;
  }
}

extension DecryptAttachmentStreamExtension on Stream<List<int>> {
  Stream<List<int>> decrypt(
    List<int> keys,
    List<int> iv,
    int total,
  ) =>
      chunkSize(_blockSize)._decrypt(keys, iv, total);

  Stream<List<int>> _decrypt(
    List<int> keys,
    List<int> digest,
    int total,
  ) {
    if (isBroadcast) throw ArgumentError('Stream must be not broadcast.');

    final aesKey = keys.sublist(0, 32);
    final macKey = keys.sublist(32, 64);
    final mac = cr.Hmac(cr.sha256, macKey);
    final macOutput = AccumulatorSink<cr.Digest>();
    final macSink = mac.startChunkedConversion(macOutput);

    final cbcCipher = CBCBlockCipher(AESFastEngine());

    final digestOutput = AccumulatorSink<cr.Digest>();
    final digestSink = cr.sha256.startChunkedConversion(digestOutput);

    final controller = StreamController<List<int>>();

    void close() {
      macSink.close();
      digestSink.close();
    }

    void addError(Object error, [StackTrace? stackTrace]) {
      close();
      controller.addError(error, stackTrace);
    }

    controller.onListen = () {
      List<int>? theirMac;

      final subscription = listen(
        null,
        onError: addError,
        onDone: () {
          macSink.close();
          final mac = macOutput.events.single.bytes;
          if (!listEquals(theirMac, mac)) {
            i('MAC doesn\'t match!');
            // TODO delete local file or make file disabled
            return;
          }

          digestSink
            ..add(mac)
            ..close();
          final ourDigest = digestOutput.events.single.bytes;
          if (!listEquals(ourDigest, digest)) {
            i('Digest doesn\'t match!');
            // TODO delete local file or make file disabled
            return;
          }

          controller.close();
        },
      );

      final pause = subscription.pause;
      final resume = subscription.resume;

      List<int>? iv;
      PaddedBlockCipher _aesCipher;
      var fileRemain = total - _macSize;
      List<int>? firstPartTheirMac;
      Future<List<int>> process(List<int> event) async {
        i('event: ${event.length}');
        var ciphertext = event;
        if (iv == null) {
          if (event.length < _cbcBlockSize) {
            // TODO invalid stream should throw exception or end this download
            return event;
          }
          iv = event.sublist(0, _cbcBlockSize);
          macSink.add(iv!);
          digestSink.add(iv!);
          ciphertext = event.sublist(_cbcBlockSize, event.length);
        }

        Uint8List plaintext;
        _aesCipher = _getAesCipher(cbcCipher, aesKey, iv!, false);

        fileRemain -= _blockSize;
        i('event length: ${event.length}, fileRemain: $fileRemain');
        if (event.length == _blockSize && fileRemain >= 0) {
          final input = Uint8List.fromList(ciphertext);
          plaintext = Uint8List(input.lengthInBytes);
          for (var offset = 0; offset < input.lengthInBytes;) {
            offset += _aesCipher.processBlock(input, offset, plaintext, offset);
          }
          macSink.add(ciphertext);
          digestSink.add(ciphertext);
          iv = ciphertext.sublist(
              ciphertext.length - _cbcBlockSize, ciphertext.length);
        } else if (event.length == _blockSize && fileRemain < 0) {
          firstPartTheirMac =
              event.sublist(event.length + fileRemain, event.length);
          final nonMac = ciphertext.sublist(0, ciphertext.length + fileRemain);
          plaintext = _aesCipher.process(Uint8List.fromList(nonMac));
          macSink.add(nonMac);
          digestSink.add(nonMac);
          iv = nonMac.sublist(nonMac.length - _cbcBlockSize, nonMac.length);
        } else if (event.length < _blockSize && fileRemain >= 0) {
          final nonMac = ciphertext.sublist(0, ciphertext.length - _macSize);
          plaintext = _aesCipher.process(Uint8List.fromList(nonMac));
          macSink.add(nonMac);
          digestSink.add(nonMac);
          iv = nonMac.sublist(nonMac.length - _cbcBlockSize, nonMac.length);
        } else {
          if (firstPartTheirMac != null) {
            theirMac = List.from(firstPartTheirMac!)..addAll(ciphertext);
            plaintext = Uint8List.fromList([]);
          } else {
            final len = ciphertext.length;
            theirMac = ciphertext.sublist(len - _macSize, len);
            final nonMac = ciphertext.sublist(0, len - _macSize);
            plaintext = _aesCipher.process(Uint8List.fromList(nonMac));
            macSink.add(nonMac);
            digestSink.add(nonMac);
            iv = nonMac.sublist(nonMac.length - _cbcBlockSize, nonMac.length);
          }
        }

        return plaintext.toList();
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

extension EncryptAttachmentStreamExtension on Stream<List<int>> {
  Stream<List<int>> encrypt(
    List<int> keys,
    List<int> iv,
    void Function(List<int>) digestCallback,
  ) =>
      chunkSize(_blockSize)._encrypt(keys, iv, digestCallback);

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
    var _aesCipher = _getAesCipher(cbcCipher, aesKey, iv, true);

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
        _aesCipher = _getAesCipher(cbcCipher, aesKey, lastBlock, true);
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
        lastBlock =
            result.sublist(result.length - _cbcBlockSize, result.length);
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
