import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';
import 'package:x509/x509.dart';

class BearerClient extends http.BaseClient {
  BearerClient(this.userId, this.sessionId, this._inner);

  final String userId;
  final String sessionId;
  final http.Client _inner;

  void auth(userId, sessionId) {
    final claims = JsonWebTokenClaims.fromJson({
      'exp': const Duration(hours: 4).inSeconds,
      'iss': 'alice',
    });

    final builder = JsonWebSignatureBuilder()..jsonContent = claims.toJson();

    // add a key to sign, can only add one for JWT
    final key = _readPrivateKey('example/jwtRS512.key');
    builder.addRecipient(key, algorithm: 'RS512');

    final jws = builder.build();
    debugPrint('jwt compact serialization: ${jws.toCompactSerialization()}');
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['user-agent'] = 'Mixin/0.0.1 Flutter';
    request.headers['Accept-Language'] = 'en';
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer ';
    return _inner.send(request);
  }

  JsonWebKey _readPrivateKey(String pem) {
    final v = parsePem(pem).first;
    final keyPair = (v is PrivateKeyInfo) ? v.keyPair : v as KeyPair;
    final pKey = keyPair.privateKey as RsaPrivateKey;
    debugPrint('$pKey');

    String _bytesToBase64(List<int> bytes) {
      return base64Url.encode(bytes).replaceAll('=', '');
    }

    String _intToBase64(BigInt v) {
      return _bytesToBase64(v
          .toRadixString(16)
          .replaceAllMapped(RegExp('[0-9a-f]{2}'), (m) => '${m.group(0)},')
          .split(',')
          .where((v) => v.isNotEmpty)
          .map((v) => int.parse(v, radix: 16))
          .toList());
    }

    return JsonWebKey.fromJson({
      'kty': 'RSA',
      'n': _intToBase64(pKey.modulus),
      'd': _intToBase64(pKey.privateExponent),
      'p': _intToBase64(pKey.firstPrimeFactor),
      'q': _intToBase64(pKey.secondPrimeFactor),
      'alg': 'RS512',
      'kid': 'some_id'
    });
  }
}
