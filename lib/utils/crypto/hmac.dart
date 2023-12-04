import 'dart:typed_data';

import 'package:common_crypto/common_crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/pointycastle.dart';

import '../platform.dart';

Uint8List calculateHMac(Uint8List key, Uint8List data) {
  final calculator = HMacCalculator(key)..addBytes(data);
  return calculator.result;
}

abstract class HMacCalculator {
  factory HMacCalculator(Uint8List key) {
    if (kPlatformIsDarwin) {
      return _HMacCalculatorCommonCrypto(key);
    }
    return _HMacCalculatorPointyCastleImpl(key);
  }

  @visibleForTesting
  factory HMacCalculator.commonCrypto(Uint8List key) =>
      _HMacCalculatorCommonCrypto(key);

  @visibleForTesting
  factory HMacCalculator.pointyCastle(Uint8List key) =>
      _HMacCalculatorPointyCastleImpl(key);

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
