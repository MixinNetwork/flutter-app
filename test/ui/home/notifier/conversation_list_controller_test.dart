@TestOn('linux || mac-os')
library;

import 'dart:async';
import 'dart:io';

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
  final badgeCalls = <MethodCall>[];
  setUpAll(() {
    EventBus.initialize();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_app_icon_badge'),
          (call) async {
            badgeCalls.add(call);
            return null;
          },
        );
  });

  test(
    'disposing the controller removes the unread badge',
    () async {
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
        mentionCache.dispose();
        categories.dispose();
        await store.close();
        await database.dispose();
      });
      await mixinDatabase.batch(
        (batch) => batch
          ..insert(
            mixinDatabase.users,
            const User(userId: 'friend', identityNumber: '1', fullName: 'F'),
          )
          ..insert(
            mixinDatabase.conversations,
            Conversation(
              conversationId: 'friend-chat',
              ownerId: 'friend',
              category: ConversationCategory.contact,
              createdAt: DateTime(2026),
              status: ConversationStatus.success,
              unseenMessageCount: 3,
            ),
          ),
      );

      controller.init();
      final initialized = controller.addListenerCompleter();
      await store.start();
      await initialized.future;
      await pumpEventQueue();
      expect(badgeCalls.last.method, 'updateBadge');
      expect(badgeCalls.last.arguments, {'count': 3});

      controller.dispose();
      await pumpEventQueue();

      expect(badgeCalls.last.method, 'removeBadge');
    },
    skip: Platform.isMacOS ? false : 'the unread badge is macOS only',
  );

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
            fullName: '主好友',
            relationship: UserRelationship.friend,
          ),
          const User(
            userId: 'stranger',
            identityNumber: '2',
            fullName: '主陌生人',
            relationship: UserRelationship.stranger,
          ),
          const User(
            userId: 'group-owner',
            identityNumber: '3',
            fullName: 'Group owner',
          ),
          const User(
            userId: 'quit-group-owner',
            identityNumber: '4',
            fullName: 'Quit group owner',
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
            name: '主',
            createdAt: now,
            status: ConversationStatus.success,
          ),
          Conversation(
            conversationId: 'quit-group-chat',
            ownerId: 'quit-group-owner',
            category: ConversationCategory.group,
            name: '主退出群',
            createdAt: now.subtract(const Duration(minutes: 1)),
            status: ConversationStatus.quit,
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

    controller.init();
    expect(controller.search('主', filterUnseen: false), isNull);

    final initialized = controller.addListenerCompleter();
    await store.start();
    await initialized.future;
    expect(controller.state.count, 4);
    expect(
      controller
          .search('主', filterUnseen: false)!
          .map((item) => item.conversationId)
          .toSet(),
      {'group-chat', 'quit-group-chat', 'stranger-chat'},
    );

    final contactsChanged = controller.addListenerCompleter();
    categories.select(SlideCategoryType.contacts);
    await contactsChanged.future;
    expect(
      controller.state.items.map((item) => item.conversationId),
      ['friend-chat'],
    );
    expect(controller.search('主', filterUnseen: false), isEmpty);

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
      ['group-chat', 'friend-chat', 'stranger-chat', 'quit-group-chat'],
    );
  });

  test('a snapshot waits only for the first rows to warm', () async {
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
    )..limit = 1;
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
        ..insert(
          mixinDatabase.users,
          const User(userId: 'member', identityNumber: '1', fullName: 'M'),
        )
        ..insertAll(mixinDatabase.conversations, [
          for (final (index, id) in ['first', 'second'].indexed)
            Conversation(
              conversationId: id,
              ownerId: 'member',
              category: ConversationCategory.group,
              createdAt: now.subtract(Duration(minutes: index)),
              status: ConversationStatus.success,
            ),
        ])
        ..insertAll(mixinDatabase.participants, [
          for (final id in ['first', 'second'])
            Participant(conversationId: id, userId: 'member', createdAt: now),
        ]);
    });

    controller.init();
    final cached = <String, bool>{};
    final initialized = Completer<void>();
    void listener() {
      controller.removeListener(listener);
      for (final id in ['first', 'second']) {
        cached[id] = controller.avatarCache.usersFor(id) != null;
      }
      initialized.complete();
    }

    controller.addListener(listener);
    await store.start();
    await initialized.future;
    expect(cached, {'first': true, 'second': false});

    await pumpEventQueue();
    expect(controller.avatarCache.usersFor('second'), isNotNull);
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
