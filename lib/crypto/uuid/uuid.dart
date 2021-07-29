import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../utils/extension/extension.dart';

String generateConversationId(String senderId, String recipientId) {
  final mix = minOf(senderId, recipientId) + maxOf(senderId, recipientId);
  final bytes = md5.convert(utf8.encode(mix)).bytes;
  bytes[6] = (bytes[6] & 0x0f) | 0x30;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final digest = bytes.map((byte) {
    final b = '0${(byte & 0xff).toRadixString(16)}';
    return b.substring(b.length - 2, b.length);
  }).join('');

  return '${digest.substring(0, 8)}-${digest.substring(8, 12)}-${digest.substring(12, 16)}-${digest.substring(16, 20)}-${digest.substring(20, 32)}';
}
