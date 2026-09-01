@TestOn('linux || mac-os')
library;

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/provider/multi_auth_provider.dart';
import 'package:flutter_app/ui/provider/setting_provider.dart';
import 'package:flutter_app/widgets/user_selector/conversation_filter_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    show ConversationCategory, ConversationStatus, UserRelationship;

void main() {
  test('filters quit groups unless selected', () async {
    final database = Database(
      MixinDatabase(NativeDatabase.memory()),
      FtsDatabase(NativeDatabase.memory()),
    );
    addTearDown(database.dispose);

    final now = DateTime(2026);
    await database.mixinDatabase.batch((batch) {
      batch
        ..insertAll(database.mixinDatabase.users, [
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
            relationship: UserRelationship.friend,
          ),
          const User(
            userId: 'other-quit-owner',
            identityNumber: '7004',
            fullName: 'Other Quit Group Owner',
            relationship: UserRelationship.friend,
          ),
        ])
        ..insertAll(database.mixinDatabase.conversations, [
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
            conversationId: 'other-quit-group',
            ownerId: 'other-quit-owner',
            category: ConversationCategory.group,
            name: 'Other Quit Group',
            createdAt: now,
            status: ConversationStatus.quit,
          ),
          Conversation(
            conversationId: 'quit-contact',
            ownerId: 'quit-contact-owner',
            category: ConversationCategory.contact,
            name: 'Quit Contact',
            createdAt: now,
            status: ConversationStatus.quit,
          ),
        ]);
    });

    final accountServer = AccountServer(
      multiAuthNotifier: MultiAuthStateNotifier(const MultiAuthState()),
      settingChangeNotifier: SettingChangeNotifier(),
      database: database,
      currentConversationId: () => null,
    );
    final initialized = Completer<ConversationFilterState>();
    final notifier = ConversationFilterNotifier(
      accountServer,
      false,
      const [],
      initialized.complete,
    );
    addTearDown(notifier.dispose);

    final state = await initialized.future;

    final ids = state.recentConversations
        .map((item) => item.conversationId)
        .toList();
    expect(ids, contains('active-group'));
    expect(ids, contains('quit-contact'));
    expect(ids, isNot(contains('quit-group')));
    expect(ids, isNot(contains('other-quit-group')));

    final selectedInitialized = Completer<ConversationFilterState>();
    final selectedNotifier = ConversationFilterNotifier(
      accountServer,
      false,
      const [],
      selectedInitialized.complete,
      selectedConversationIds: const ['quit-group'],
    );
    addTearDown(selectedNotifier.dispose);

    final selectedIds = (await selectedInitialized.future).recentConversations
        .map((item) => item.conversationId);
    expect(selectedIds, contains('quit-group'));
    expect(selectedIds, isNot(contains('other-quit-group')));
  });
}
