import 'package:flutter/foundation.dart';
import 'package:flutter_app/crypto/uuid/uuid.dart';
import 'package:flutter_app/utils/string_extension.dart';

void main() {
  testGenerateConversationId();
  textUuidHashcode();
  debugPrint('Done!');
}

void testGenerateConversationId() {
  const a = '80f5130e-a5f5-47e4-80a1-535563687709';
  const b = '508c75a2-ddce-4858-9e66-cf6d58db15cf';
  final result = generateConversationId(a, b);
  final otherResult = generateConversationId(b, a);
  assert(result == 'a59c170e-02e6-3aa6-8ff1-6cb9350fa8fc');
  assert(result == otherResult);
}

void textUuidHashcode() {
  assert('ea91421a-98bb-41d2-abcf-af013d8b874b'.uuidHashcode() == -462541950);
  assert('0364f490-49cc-4988-88c2-481707687e5b'.uuidHashcode() == -989689004);
  assert('8df4972f-702f-4ae9-bc76-68e489351357'.uuidHashcode() == -929520011);
}
