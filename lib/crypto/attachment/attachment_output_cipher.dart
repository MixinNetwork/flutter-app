import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as cr;
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/padded_block_cipher/padded_block_cipher_impl.dart';
import 'package:pointycastle/paddings/pkcs7.dart';

class AttachmentOutputCipher {
  AttachmentOutputCipher(
      this._inputStream, File outFile, List<int> keys, List<int> iv) {
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
    _fileSink = outFile.openWrite(mode: FileMode.append);
    _fileSink.add(iv);
  }

  final ChunkedStreamReader<int> _inputStream;
  late IOSink _fileSink;
  late PaddedBlockCipher _aesCipher;
  late AccumulatorSink<cr.Digest> _macOutput;
  late ByteConversionSink _macSink;
  late AccumulatorSink<cr.Digest> _digestOutput;
  late ByteConversionSink _digestSink;

  Future<List<int>> process() async {
    List<int> digest;
    while (true) {
      final plaintext = await _inputStream.readBytes(8192);
      if (plaintext.length < 8192) {
        final lastCipher = _aesCipher.process(plaintext);
        _macSink
          ..add(lastCipher)
          ..close();
        final mac = _macOutput.events.single.bytes;
        _digestSink
          ..add(lastCipher)
          ..add(mac)
          ..close();
        digest = _digestOutput.events.single.bytes;
        _fileSink
          ..add(lastCipher)
          ..add(mac);
        await _fileSink.flush();
        await _fileSink.close();
        break;
      }
      await write(plaintext);
    }
    return digest;
  }

  Future<void> write(Uint8List plaintext) async {
    final ciphertext = _aesCipher.process(plaintext);
    _macSink.add(ciphertext);
    _digestSink.add(ciphertext);
    _fileSink.add(ciphertext);
  }

  static int getCiphertextLength(int plaintextLength) =>
      (16 + (((plaintextLength / 16) + 1) * 16) + 32).toInt();
}
