import 'package:flutter/widgets.dart';
import 'package:flutter_app/ui/home/chat/chat_history_viewport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
