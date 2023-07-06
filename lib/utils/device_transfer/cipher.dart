// ignore_for_file: implementation_imports
import 'dart:convert';
import 'dart:typed_data';

import 'package:libsignal_protocol_dart/src/kdf/hkdfv3.dart';

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

Uint8List generateTransferIv() {
  const _kIVBytesCount = 16;
  return Uint8List.fromList(generateRandomKey(_kIVBytesCount));
}
