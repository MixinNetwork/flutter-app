import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'crypto_decryptor.dart';
import '../../utils/crypto_util.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/padded_block_cipher/padded_block_cipher_impl.dart';
import 'package:pointycastle/paddings/pkcs7.dart';

class CryptoEncryptor {
  CryptoEncryptor(this._sink, List<int> keys, { List<int>? iv }) {
    final aesKey = keys.sublist(0, aesKeySize);
    final macKey = keys.sublist(aesKeySize, aesKeySize + macKeySize);

    final cbcCipher = CBCBlockCipher(AESFastEngine());
    final nonce = iv ?? generateRandomKey(16);
    final ivParams = ParametersWithIV<KeyParameter>(
        KeyParameter(Uint8List.fromList(aesKey)), Uint8List.fromList(nonce));
    final paddingParams =
    // ignore: prefer_void_to_null
    PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
        ivParams, null);
    _cipher = PaddedBlockCipherImpl(PKCS7Padding(), cbcCipher)
      ..init(true, paddingParams);
    final hmac = crypto.Hmac(crypto.sha256, macKey);
    final digester = crypto.sha256;
    _macOutput = AccumulatorSink<crypto.Digest>();
    _macInput = hmac.startChunkedConversion(_macOutput);
    _macInput.add(nonce);
    _hashOutput = AccumulatorSink<crypto.Digest>();
    _hashInput = digester.startChunkedConversion(_hashOutput);
    _hashInput.add(nonce);
    _sink.add(nonce);
  }

  late PaddedBlockCipherImpl _cipher;
  final EventSink _sink;

  late AccumulatorSink<crypto.Digest> _macOutput;
  late ByteConversionSink _macInput;

  late AccumulatorSink<crypto.Digest> _hashOutput;
  late ByteConversionSink _hashInput;

  void process(Uint8List data) {
    final ciphertext = _cipher.process(data);
    debugPrint('process data: ${data.length}, ciphertext: ${ciphertext.length}');
    _macInput.add(ciphertext);
    _hashInput.add(ciphertext);
    _sink.add(ciphertext);
  }

  List<int> close() {
    debugPrint('close');
    _macInput.close();
    final mac = _macOutput.events.single.bytes;
    _hashInput.close();
    final digest = _hashOutput.events.single.bytes;
    _sink.add(mac);
    _sink.close();
    return digest;
  }
}