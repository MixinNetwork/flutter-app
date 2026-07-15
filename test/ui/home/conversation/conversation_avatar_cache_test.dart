@TestOn('linux || mac-os')
library;

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/conversation/conversation_avatar_cache.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    show ConversationCategory, ConversationStatus;

void main() {
  setUpAll(EventBus.initialize);

  test(
    'refreshes a loaded group avatar when a participant user changes',
    () async {
      final mixinDatabase = MixinDatabase(NativeDatabase.memory());
      final database = Database(
        mixinDatabase,
        FtsDatabase(NativeDatabase.memory()),
      );
      final cache = ConversationAvatarCache(database);
      addTearDown(() async {
        cache.dispose();
        await database.dispose();
      });

      final now = DateTime(2026);
      await mixinDatabase.batch((batch) {
        batch
          ..insert(
            mixinDatabase.users,
            const User(
              userId: 'participant',
              identityNumber: '1',
              fullName: 'Participant',
              avatarUrl: 'before',
            ),
          )
          ..insert(
            mixinDatabase.conversations,
            Conversation(
              conversationId: 'group',
              ownerId: 'participant',
              category: ConversationCategory.group,
              createdAt: now,
              status: ConversationStatus.success,
            ),
          )
          ..insert(
            mixinDatabase.participants,
            Participant(
              conversationId: 'group',
              userId: 'participant',
              createdAt: now,
            ),
          );
      });
      final conversation = await mixinDatabase.conversationDao
          .conversationItem('group')
          .getSingle();
      await cache.warm([conversation]);

      final changed = Completer<void>();
      cache.addListener(changed.complete);
      await mixinDatabase.userDao.insert(
        const User(
          userId: 'participant',
          identityNumber: '1',
          fullName: 'Participant',
          avatarUrl: 'after',
        ),
      );
      await changed.future.timeout(const Duration(milliseconds: 200));

      expect(cache.usersFor('group')!.single.avatarUrl, 'after');
    },
  );
}
