@TestOn('linux || mac-os')
library;

import 'package:drift/native.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    show ConversationCategory, ConversationStatus;

void main() {
  test(
    'loads group avatar users for multiple conversations in one query',
    () async {
      final database = MixinDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      final now = DateTime(2026);
      await database.batch((batch) {
        batch
          ..insertAll(database.users, [
            for (var index = 0; index < 8; index++)
              User(
                userId: 'u$index',
                identityNumber: '700$index',
                fullName: 'User $index',
              ),
          ])
          ..insertAll(database.conversations, [
            Conversation(
              conversationId: 'c1',
              ownerId: 'u0',
              category: ConversationCategory.group,
              createdAt: now,
              status: ConversationStatus.success,
            ),
            Conversation(
              conversationId: 'c2',
              ownerId: 'u5',
              category: ConversationCategory.group,
              createdAt: now,
              status: ConversationStatus.success,
            ),
          ])
          ..insertAll(database.participants, [
            for (var index = 0; index < 6; index++)
              Participant(
                conversationId: 'c1',
                userId: 'u$index',
                createdAt: now.add(Duration(minutes: index)),
              ),
            for (var index = 6; index < 8; index++)
              Participant(
                conversationId: 'c2',
                userId: 'u$index',
                createdAt: now.add(Duration(minutes: index)),
              ),
          ]);
      });

      final avatars = await database.participantDao
          .participantsAvatarByConversationIds(['c1', 'c2', 'missing']);

      expect(avatars['c1']?.map((user) => user.userId), [
        'u0',
        'u1',
        'u2',
        'u3',
      ]);
      expect(avatars['c2']?.map((user) => user.userId), ['u6', 'u7']);
      expect(avatars['missing'], isEmpty);
    },
  );
}
