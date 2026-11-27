// ignore_for_file: implementation_imports

import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:common_crypto/src/common_crypto_bindings_generated.dart';
import 'package:common_crypto/src/tools.dart';
import 'package:ffi/ffi.dart';
import 'package:webcrypto/webcrypto.dart';

import '../platform.dart';

const _kKeyLength = 32;

/// PBKDF2-HMAC-SHA256, on another isolate because the native call blocks.
// webcrypto ships its native library only for Linux and Windows.
Future<Uint8List> pbkdf2Sha256(
  String password,
  Uint8List salt,
  int iterations,
) => Isolate.run(
  () async => kPlatformIsDarwin
      ? _commonCrypto(utf8.encode(password), salt, iterations)
      : await (await Pbkdf2SecretKey.importRawKey(
          utf8.encode(password),
        )).deriveBits(_kKeyLength * 8, Hash.sha256, salt, iterations),
);

Uint8List _commonCrypto(Uint8List password, Uint8List salt, int iterations) =>
    using((arena) {
      final passwordPointer = arena<Uint8>(password.length)
        ..asTypedList(password.length).setAll(0, password);
      final saltPointer = arena<Uint8>(salt.length)
        ..asTypedList(salt.length).setAll(0, salt);
      final key = arena<Uint8>(_kKeyLength);
      final status = bindings.CCKeyDerivationPBKDF(
        kCCPBKDF2,
        passwordPointer.cast(),
        password.length,
        saltPointer,
        salt.length,
        kCCPRFHmacAlgSHA256,
        iterations,
        key,
        _kKeyLength,
      );
      if (status != kCCSuccess) {
        throw StateError('CCKeyDerivationPBKDF failed: $status');
      }
      return Uint8List.fromList(key.asTypedList(_kKeyLength));
    });
