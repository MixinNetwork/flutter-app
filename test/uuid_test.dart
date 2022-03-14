import 'dart:convert';

import 'package:flutter_app/crypto/uuid/uuid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test generate conversationId', () {
    const a = '80f5130e-a5f5-47e4-80a1-535563687709';
    const b = '508c75a2-ddce-4858-9e66-cf6d58db15cf';
    final result = generateConversationId(a, b);
    final otherResult = generateConversationId(b, a);
    expect(result, 'a59c170e-02e6-3aa6-8ff1-6cb9350fa8fc');
    expect(result, otherResult);
  });

  test('test generate uuid with same bytes', () {
    final value = nameUuidFromBytes(utf8.encode('test'));
    expect(value.toString(), '098f6bcd-4621-3373-8ade-4e832627b4f6');
  });
}
