@TestOn('linux || mac-os')
library;

import 'package:drift/native.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    show ConversationCategory, ConversationStatus, UserRelationship;

void main() {
  test('conversation searches include quit groups', () async {
    final database = MixinDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final now = DateTime(2026);
    await database.batch((batch) {
      batch
        ..insertAll(database.users, [
          const User(
            userId: 'active-owner',
            identityNumber: '7001',
            fullName: 'Active Group Owner',
            relationship: UserRelationship.friend,
          ),
          const User(
            userId: 'quit-owner',
            identityNumber: '7002',
            fullName: 'Quit Group Owner',
            relationship: UserRelationship.friend,
          ),
          const User(
            userId: 'quit-contact-owner',
            identityNumber: '7003',
            fullName: 'Quit Contact Owner',
            relationship: UserRelationship.stranger,
          ),
        ])
        ..insertAll(database.conversations, [
          Conversation(
            conversationId: 'active-group',
            ownerId: 'active-owner',
            category: ConversationCategory.group,
            name: 'Active Group',
            createdAt: now,
            status: ConversationStatus.success,
          ),
          Conversation(
            conversationId: 'quit-group',
            ownerId: 'quit-owner',
            category: ConversationCategory.group,
            name: 'Quit Group',
            createdAt: now,
            status: ConversationStatus.quit,
          ),
          Conversation(
            conversationId: 'quit-contact',
            ownerId: 'quit-contact-owner',
            category: ConversationCategory.contact,
            createdAt: now,
            status: ConversationStatus.quit,
          ),
        ]);
    });

    final typedPaletteResults = await database.conversationDao
        .fuzzySearchConversationItem('Group')
        .get();
    expect(
      typedPaletteResults.map((item) => item.id).toSet(),
      {'active-group', 'quit-group', 'quit-contact'},
    );

    final recentPaletteResults = await database.conversationDao
        .fuzzySearchConversationItemByIds([
          'quit-group',
          'active-group',
          'quit-contact',
        ])
        .get();
    expect(
      recentPaletteResults.map((item) => item.id).toSet(),
      {'active-group', 'quit-group', 'quit-contact'},
    );

    final quitContactResults = await database.conversationDao
        .fuzzySearchConversationItem('Quit Contact')
        .get();
    expect(
      quitContactResults.map((item) => item.id).toSet(),
      {'active-group', 'quit-group', 'quit-contact'},
    );

    final regularSearchResults = await database.conversationDao
        .fuzzySearchConversation('Group', 32)
        .get();
    expect(
      regularSearchResults.map((item) => item.conversationId).toSet(),
      {'active-group', 'quit-group'},
    );

    final regularQuitContactResults = await database.conversationDao
        .fuzzySearchConversation('Quit Contact', 32)
        .get();
    expect(
      regularQuitContactResults.map((item) => item.conversationId).toSet(),
      {'quit-contact'},
    );
  });
}
