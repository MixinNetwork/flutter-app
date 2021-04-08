import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/crypto/uuid/uuid.dart';

void main() {
  testGenerateConversationId();
  debugPrint('Done!');
}

void testGenerateConversationId(){
  const a = '80f5130e-a5f5-47e4-80a1-535563687709';
  const b = '508c75a2-ddce-4858-9e66-cf6d58db15cf';
  final result = generateConversationId(a, b);
  assert(result == 'a59c170e-02e6-3aa6-8ff1-6cb9350fa8fc');
}