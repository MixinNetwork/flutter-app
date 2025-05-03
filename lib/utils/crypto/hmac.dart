import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:common_crypto/common_crypto.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/pointycastle.dart';

import '../platform.dart';
import 'web_crypto.dart';

Uint8List calculateHMac(Uint8List key, Uint8List data) {
  final calculator = HMacCalculator(key)..addBytes(data);
  return calculator.result;
}

abstract class HMacCalculator {
  factory HMacCalculator(Uint8List key) {
    if (kPlatformIsDarwin) {
      return _HMacCalculatorCommonCrypto(key);
    }
    if (Platform.isLinux || Platform.isWindows) {
      return HMacCalculator.webCrypto(key);
    }
    return _HMacCalculatorPointyCastleImpl(key);
  }

  @visibleForTesting
  factory HMacCalculator.commonCrypto(Uint8List key) =>
      _HMacCalculatorCommonCrypto(key);

  @visibleForTesting
  factory HMacCalculator.pointyCastle(Uint8List key) =>
      _HMacCalculatorPointyCastleImpl(key);

  @visibleForTesting
  factory HMacCalculator.webCrypto(Uint8List key) =>
      _HMacCalculatorWebCrypto(key);

  void addBytes(Uint8List data);

  Uint8List get result;
}

class _HMacCalculatorPointyCastleImpl implements HMacCalculator {
  _HMacCalculatorPointyCastleImpl(this._hMacKey)
    : _hmac = HMac(SHA256Digest(), 64) {
    _hmac.init(KeyParameter(_hMacKey));
  }

  final Uint8List _hMacKey;
  final HMac _hmac;

  @override
  void addBytes(Uint8List data) {
    _hmac.update(data, 0, data.length);
  }

  @override
  Uint8List get result {
    final bytes = Uint8List(_hmac.macSize);
    final len = _hmac.doFinal(bytes, 0);
    return bytes.sublist(0, len);
  }
}

class _HMacCalculatorCommonCrypto implements HMacCalculator {
  _HMacCalculatorCommonCrypto(Uint8List key) : _hmac = HMacSha256(key);

  final HMacSha256 _hmac;
  var _isDisposed = false;

  @override
  void addBytes(Uint8List data) {
    if (_isDisposed) {
      throw StateError('HMacCalculator is disposed');
    }
    _hmac.update(data);
  }

  @override
  Uint8List get result {
    if (_isDisposed) {
      throw StateError('HMacCalculator is disposed');
    }
    final result = _hmac.finalize();
    _hmac.dispose();
    _isDisposed = true;
    return result;
  }
}

class _HMacCalculatorWebCrypto implements HMacCalculator {
  _HMacCalculatorWebCrypto(Uint8List key) {
    _ctx = ssl.HMAC_CTX_new();
    final keyPtr = key.toNative();
    try {
      checkOpIsOne(
        ssl.HMAC_Init_ex(
          _ctx,
          keyPtr.cast(),
          key.length,
          ssl.EVP_sha256(),
          nullptr,
        ),
      );
    } finally {
      malloc.free(keyPtr);
    }
  }

  late Pointer<HMAC_CTX> _ctx;
  var _isDisposed = false;

  static const _bufferSize = 4096;
  final _inBuffer = malloc<Uint8>(_bufferSize);

  @override
  void addBytes(Uint8List data) {
    if (_isDisposed) {
      throw StateError('HMacCalculator is disposed');
    }
    var offset = 0;
    while (offset < data.length) {
      final len = data.length - offset;
      final size = len > _bufferSize ? _bufferSize : len;
      _inBuffer
          .asTypedList(size)
          .setAll(0, Uint8List.sublistView(data, offset, offset + size));
      checkOpIsOne(ssl.HMAC_Update(_ctx, _inBuffer, size));
      offset += size;
    }
  }

  @override
  Uint8List get result {
    if (_isDisposed) {
      throw StateError('HMacCalculator is disposed');
    }
    _isDisposed = true;
    final size = ssl.HMAC_size(_ctx);
    checkOp(size > 0);
    final psize = malloc<UnsignedInt>()..value = size;

    final out = malloc<Uint8>(size);
    try {
      checkOpIsOne(ssl.HMAC_Final(_ctx, out, psize));
      return out.asTypedList(psize.value, finalizer: malloc.nativeFree);
    } finally {
      malloc.free(psize);
      ssl.HMAC_CTX_free(_ctx);
      malloc.free(_inBuffer);
    }
  }
}
