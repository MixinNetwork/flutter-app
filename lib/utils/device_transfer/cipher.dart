import 'dart:convert';
import 'dart:typed_data';

// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/kdf/hkdfv3.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/pointycastle.dart';

import '../crypto_util.dart';

final _kInfo = Uint8List.fromList(utf8.encode('Mixin Device Transfer'));

class TransferSecretKey {
  TransferSecretKey(this.secretKey)
      : aesKey = Uint8List.sublistView(secretKey, 0, 32),
        hMacKey = Uint8List.sublistView(secretKey, 32, 64);

  final Uint8List secretKey;

  final Uint8List aesKey;
  final Uint8List hMacKey;
}

TransferSecretKey generateTransferKey() {
  final keys = generateRandomKey();
  final bytes = HKDFv3().deriveSecrets(Uint8List.fromList(keys), _kInfo, 64);
  return TransferSecretKey(bytes);
}

Uint8List calculateHMac(Uint8List key, Uint8List data) {
  final calculator = HMacCalculator(key)..addBytes(data);
  return calculator.result;
}

Uint8List generateTransferIv() {
  const _kIVBytesCount = 16;
  return Uint8List.fromList(generateRandomKey(_kIVBytesCount));
}

class HMacCalculator {
  HMacCalculator(this._hMacKey) : _hmac = HMac.withDigest(SHA256Digest()) {
    _hmac.init(KeyParameter(_hMacKey));
  }

  final Uint8List _hMacKey;
  final HMac _hmac;

  void addBytes(Uint8List data) {
    _hmac.update(data, 0, data.length);
  }

  Uint8List get result {
    final bytes = Uint8List(_hmac.macSize);
    final len = _hmac.doFinal(bytes, 0);
    return bytes.sublist(0, len);
  }
}
