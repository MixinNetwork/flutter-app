import 'package:flutter/widgets.dart';
import 'package:flutter_app/ui/home/chat/chat_history_viewport.dart';
import 'package:flutter_app/ui/home/chat/chat_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'handleForceLatestChatJump delegates non-null signals to latest jump',
    () {
      var jumpCount = 0;

      handleForceLatestChatJump(null, () async => jumpCount++);
      expect(jumpCount, 0);

      handleForceLatestChatJump(Object(), () async => jumpCount++);
      expect(jumpCount, 1);
    },
  );

  test(
    'syncMessageGlobalKeys preserves current keys and removes stale keys',
    () {
      final existingKey = GlobalKey(debugLabel: 'existing');
      final keysByMessageId = <String, GlobalKey>{
        'old': GlobalKey(debugLabel: 'old'),
        'existing': existingKey,
      };

      syncMessageGlobalKeys(keysByMessageId, {'existing', 'new'});

      expect(keysByMessageId.keys, unorderedEquals(['existing', 'new']));
      expect(keysByMessageId['existing'], same(existingKey));
      expect(keysByMessageId['new'], isA<GlobalKey>());
    },
  );
}
