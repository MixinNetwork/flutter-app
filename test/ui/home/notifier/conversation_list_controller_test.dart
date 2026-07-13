@TestOn('linux || mac-os')
library;

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/conversation/conversation_list_store.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/notifier/conversation_list_controller.dart';
import 'package:flutter_app/ui/provider/mention_cache_provider.dart';
import 'package:flutter_app/ui/provider/slide_category_provider.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    show ConversationCategory, ConversationStatus, UserRelationship;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    EventBus.initialize();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_app_icon_badge'),
          (_) async => null,
        );
  });

  test('adapts store snapshots and deltas to the active category', () async {
    final mixinDatabase = MixinDatabase(NativeDatabase.memory());
    final database = Database(
      mixinDatabase,
      FtsDatabase(NativeDatabase.memory()),
    );
    final store = ConversationListStore(mixinDatabase);
    final categories = SlideCategoryStateNotifier();
    final mentionCache = MentionCache(mixinDatabase.userDao);
    final controller = ConversationListController(
      categories,
      database,
      mentionCache,
      store,
    );
    addTearDown(() async {
      controller.dispose();
      mentionCache.dispose();
      categories.dispose();
      await store.close();
      await database.dispose();
    });

    final now = DateTime(2026);
    await mixinDatabase.batch((batch) {
      batch
        ..insertAll(mixinDatabase.users, [
          const User(
            userId: 'friend',
            identityNumber: '1',
            fullName: 'Friend',
            relationship: UserRelationship.friend,
          ),
          const User(
            userId: 'stranger',
            identityNumber: '2',
            fullName: 'Stranger',
            relationship: UserRelationship.stranger,
          ),
          const User(
            userId: 'group-owner',
            identityNumber: '3',
            fullName: 'Group owner',
          ),
        ])
        ..insertAll(mixinDatabase.conversations, [
          Conversation(
            conversationId: 'friend-chat',
            ownerId: 'friend',
            category: ConversationCategory.contact,
            createdAt: now.add(const Duration(minutes: 2)),
            status: ConversationStatus.success,
          ),
          Conversation(
            conversationId: 'stranger-chat',
            ownerId: 'stranger',
            category: ConversationCategory.contact,
            createdAt: now.add(const Duration(minutes: 1)),
            status: ConversationStatus.success,
          ),
          Conversation(
            conversationId: 'group-chat',
            ownerId: 'group-owner',
            category: ConversationCategory.group,
            createdAt: now,
            status: ConversationStatus.success,
          ),
        ])
        ..insert(
          mixinDatabase.circleConversations,
          CircleConversation(
            conversationId: 'friend-chat',
            circleId: 'circle',
            createdAt: now,
          ),
        );
    });

    await store.start();
    controller.init();
    expect(controller.state.count, 3);

    final contactsChanged = controller.addListenerCompleter();
    categories.select(SlideCategoryType.contacts);
    await contactsChanged.future;
    expect(
      controller.state.items.map((item) => item.conversationId),
      ['friend-chat'],
    );

    final circleChanged = controller.addListenerCompleter();
    categories.select(SlideCategoryType.circle, 'circle');
    await circleChanged.future;
    expect(
      controller.state.items.map((item) => item.conversationId),
      ['friend-chat'],
    );

    final circleMembershipChanged = controller.addListenerCompleter();
    await mixinDatabase.circleConversationDao.insert(
      CircleConversation(
        conversationId: 'group-chat',
        circleId: 'circle',
        createdAt: now,
      ),
    );
    await circleMembershipChanged.future;
    expect(
      controller.state.items.map((item) => item.conversationId),
      ['friend-chat', 'group-chat'],
    );

    final chatsChanged = controller.addListenerCompleter();
    categories.select(SlideCategoryType.chats);
    await chatsChanged.future;
    final changed = controller.addListenerCompleter();
    await mixinDatabase.conversationDao.pin('group-chat');
    await changed.future;
    expect(
      controller.state.items.map((item) => item.conversationId),
      ['group-chat', 'friend-chat', 'stranger-chat'],
    );
  });
}

extension on ConversationListController {
  Completer<void> addListenerCompleter() {
    final completer = Completer<void>();
    void listener() {
      removeListener(listener);
      completer.complete();
    }

    addListener(listener);
    return completer;
  }
}
