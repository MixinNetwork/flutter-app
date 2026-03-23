import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'conversation provider uses replaceState instead of direct state write',
    () async {
      final file = File(
        '/Users/yeungkc/coding/work/mixin/flutter-app/lib/ui/provider/conversation_provider.dart',
      );
      final content = await file.readAsString();

      expect(content, contains('void replaceState(ConversationState? next)'));
      expect(content, isNot(contains('conversationNotifier.state =')));
    },
  );
}
