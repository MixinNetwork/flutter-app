import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as cr;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter_app/crypto/bot_signature.dart';
import 'package:flutter_app/utils/crypto_util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

void main() {
  const accountId = '773e5e77-4107-45c2-b648-8fc722ed77f5';
  final user = ed.generateKey();
  final bot = ed.generateKey();

  List<int> sessionPublicKey(ed.KeyPair pair) =>
      publicKeyToCurve25519(Uint8List.fromList(pair.publicKey.bytes));

  // How a bot verifies it: the agreement of its key with the user's session
  // public key, then the HMAC of the same content.
  List<int> verify(String payload, String content) {
    final bytes = base64Url.decode(base64Url.normalize(payload));
    expect(utf8.decode(bytes.sublist(0, 36)), accountId);
    final sharedKey = calculateAgreement(
      sessionPublicKey(user),
      privateKeyToCurve25519(Uint8List.fromList(bot.privateKey.bytes)),
    );
    expect(
      bytes.sublist(36),
      cr.Hmac(cr.sha256, sharedKey).convert(utf8.encode(content)).bytes,
    );
    return bytes;
  }

  test('signs timestamp, method, path and body', () {
    final payload = signBotRequest(
      accountId: accountId,
      privateKey: user.privateKey,
      botPublicKey: sessionPublicKey(bot),
      timestamp: 1700000000,
      method: 'POST',
      path: '/web3/swap',
      body: '{"a":1}',
    );
    expect(payload, isNot(contains('=')));
    verify(payload, '1700000000POST/web3/swap{"a":1}');
  });

  test('leaves out a blank body', () {
    final payload = signBotRequest(
      accountId: accountId,
      privateKey: user.privateKey,
      botPublicKey: sessionPublicKey(bot),
      timestamp: 1700000000,
      method: 'GET',
      path: '/me',
      body: '  ',
    );
    verify(payload, '1700000000GET/me');
  });
}
