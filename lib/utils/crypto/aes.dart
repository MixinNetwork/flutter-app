import 'package:common_crypto/common_crypto.dart' as cc;
import 'package:flutter/foundation.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/padded_block_cipher/padded_block_cipher_impl.dart';
import 'package:pointycastle/paddings/pkcs7.dart';
import 'package:pointycastle/pointycastle.dart';

import '../platform.dart';

typedef OnCipherCallback = void Function(Uint8List data);

abstract class AesCipher {
  factory AesCipher({
    required Uint8List key,
    required Uint8List iv,
    required bool encrypt,
  }) {
    if (kPlatformIsDarwin) {
      return AesCipherCommonCryptoImpl(key: key, iv: iv, encrypt: encrypt);
    } else {
      return AesCipherPointyCastleImpl(key: key, iv: iv, encrypt: encrypt);
    }
  }

  static Uint8List _crypt({
    required Uint8List key,
    required Uint8List iv,
    required Uint8List data,
    required bool encrypt,
  }) {
    final cipher = AesCipher(key: key, iv: iv, encrypt: encrypt);
    return Uint8List.fromList([
      ...cipher.update(data),
      ...cipher.finish(),
    ]);
  }

  static Uint8List encrypt({
    required Uint8List key,
    required Uint8List iv,
    required Uint8List data,
  }) =>
      _crypt(key: key, iv: iv, data: data, encrypt: true);

  static Uint8List decrypt({
    required Uint8List key,
    required Uint8List iv,
    required Uint8List data,
  }) =>
      _crypt(key: key, iv: iv, data: data, encrypt: false);

  Uint8List update(Uint8List data);

  Uint8List finish();
}

@visibleForTesting
class AesCipherCommonCryptoImpl implements AesCipher {
  AesCipherCommonCryptoImpl({
    required Uint8List key,
    required Uint8List iv,
    required bool encrypt,
  }) : _aesCrypto = cc.AesCryptor(key: key, iv: iv, encrypt: encrypt);

  final cc.AesCryptor _aesCrypto;

  var _disposed = false;

  @override
  Uint8List update(Uint8List data) {
    if (_disposed) {
      throw StateError('AesCipherCommonCryptoImpl has been disposed.');
    }
    return _aesCrypto.update(data);
  }

  @override
  Uint8List finish() {
    if (_disposed) {
      throw StateError('AesCipherCommonCryptoImpl has been disposed.');
    }
    final bytes = _aesCrypto.finalize();
    _aesCrypto.dispose();
    _disposed = true;
    return bytes;
  }
}

class AesCipherPointyCastleImpl implements AesCipher {
  AesCipherPointyCastleImpl({
    required Uint8List key,
    required Uint8List iv,
    required bool encrypt,
  }) : _cipher = _createAESCipher(aesKey: key, iv: iv, encrypt: encrypt);

  static PaddedBlockCipherImpl _createAESCipher({
    required Uint8List aesKey,
    required Uint8List iv,
    required bool encrypt,
  }) {
    final cbcCipher = CBCBlockCipher(AESEngine());
    return PaddedBlockCipherImpl(PKCS7Padding(), cbcCipher)
      ..init(
        encrypt,
        PaddedBlockCipherParameters(
          ParametersWithIV(KeyParameter(aesKey), iv),
          null,
        ),
      );
  }

  final PaddedBlockCipherImpl _cipher;
  Uint8List? _carry;
  List<int>? _preBytes;

  @override
  Uint8List update(Uint8List bytes) {
    final toProcess = _preBytes;
    _preBytes = Uint8List.fromList(bytes);
    if (toProcess == null) {
      return Uint8List(0);
    }
    final Uint8List data;
    if (_carry == null) {
      data = Uint8List.fromList(toProcess);
    } else {
      data = Uint8List.fromList(_carry! + toProcess);
      _carry = null;
    }
    final length = data.length - (data.length % 1024);
    if (length < data.length) {
      _carry = data.sublist(length);
    } else {
      _carry = null;
    }
    final encryptedData = Uint8List(length);
    var offset = 0;
    while (offset < length) {
      offset += _cipher.processBlock(data, offset, encryptedData, offset);
    }
    return encryptedData;
  }

  @override
  Uint8List finish() {
    final Uint8List lastBlock;
    if (_carry == null) {
      lastBlock = Uint8List.fromList(_preBytes ?? []);
    } else {
      lastBlock = Uint8List.fromList(_carry! + _preBytes!);
    }
    if (lastBlock.isEmpty) {
      return Uint8List(0);
    }
    final encryptedData = _cipher.process(lastBlock);
    return encryptedData;
  }
}
