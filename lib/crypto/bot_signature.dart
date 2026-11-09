import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as cr;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../utils/crypto_util.dart';

/// Signs a request to a bot as the account, as `signBotSignature` does on
/// Android and iOS: the account id followed by an HMAC-SHA256 of
/// `timestamp + method + path + body`, keyed with the X25519 agreement of the
/// session key and the bot's session public key. Base64url without padding.
String signBotRequest({
  required String accountId,
  required ed.PrivateKey privateKey,
  required List<int> botPublicKey,
  required int timestamp,
  required String method,
  required String path,
  String? body,
}) {
  final private = privateKeyToCurve25519(Uint8List.fromList(privateKey.bytes));
  final sharedKey = calculateAgreement(botPublicKey, private);
  var content = '$timestamp$method$path';
  if (body != null && body.trim().isNotEmpty) content += body;
  final mac = cr.Hmac(cr.sha256, sharedKey).convert(utf8.encode(content));
  return [...utf8.encode(accountId), ...mac.bytes].base64RawUrlEncode();
}
