@TestOn('linux || mac-os')
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_app/core/conversation/conversation_list_store.dart';
import 'package:flutter_app/db/database_event_bus.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    show ConversationCategory, ConversationStatus, MessageStatus;

void main() {
  setUpAll(EventBus.initialize);

  test('publishes a snapshot then deltas for conversation writes', () async {
    final database = MixinDatabase(NativeDatabase.memory());
    final store = ConversationListStore(database);
    addTearDown(() async {
      await store.close();
      await database.close();
    });

    final now = DateTime(2026);
    await database.batch((batch) {
      batch
        ..insertAll(database.users, [
          const User(
            userId: 'owner-1',
            identityNumber: '1',
            fullName: 'Owner 1',
          ),
          const User(
            userId: 'owner-2',
            identityNumber: '2',
            fullName: 'Owner 2',
          ),
        ])
        ..insertAll(database.conversations, [
          Conversation(
            conversationId: 'newer',
            ownerId: 'owner-1',
            category: ConversationCategory.contact,
            createdAt: now.add(const Duration(minutes: 1)),
            status: ConversationStatus.success,
          ),
          Conversation(
            conversationId: 'older',
            ownerId: 'owner-2',
            category: ConversationCategory.contact,
            createdAt: now,
            status: ConversationStatus.success,
          ),
        ]);
    });

    await store.start();

    final snapshot = await store.events.first;
    expect(snapshot, isA<ConversationListSnapshot>());
    expect(store.items.map((item) => item.conversationId), ['newer', 'older']);

    final pinDeltaFuture = store.events
        .where((event) => event is ConversationListDelta)
        .cast<ConversationListDelta>()
        .first;
    await database.conversationDao.pin('older');
    final pinDelta = await pinDeltaFuture;

    expect(pinDelta.changedIds, {'older'});
    expect(store.items.map((item) => item.conversationId), ['older', 'newer']);

    final deleteDeltaFuture = store.events
        .where((event) => event is ConversationListDelta)
        .cast<ConversationListDelta>()
        .first;
    await database.conversationDao.deleteConversation('older');
    final deleteDelta = await deleteDeltaFuture;

    expect(deleteDelta.removedIds, {'older'});
    expect(store.items.map((item) => item.conversationId), ['newer']);
  });

  test('publishes one delta for a batch of conversation changes', () async {
    final database = MixinDatabase(NativeDatabase.memory());
    final store = ConversationListStore(database);
    addTearDown(() async {
      await store.close();
      await database.close();
    });

    final now = DateTime(2026);
    await database.batch((batch) {
      batch
        ..insertAll(database.users, [
          const User(userId: 'owner-1', identityNumber: '1', fullName: 'One'),
          const User(userId: 'owner-2', identityNumber: '2', fullName: 'Two'),
        ])
        ..insertAll(database.conversations, [
          Conversation(
            conversationId: 'one',
            ownerId: 'owner-1',
            category: ConversationCategory.contact,
            createdAt: now,
            status: ConversationStatus.success,
          ),
          Conversation(
            conversationId: 'two',
            ownerId: 'owner-2',
            category: ConversationCategory.contact,
            createdAt: now,
            status: ConversationStatus.success,
          ),
        ]);
    });
    await store.start();

    final deltaFuture = store.events
        .where((event) => event is ConversationListDelta)
        .cast<ConversationListDelta>()
        .first;
    await (database.update(database.conversations)..where(
          (row) => row.conversationId.isIn(['one', 'two']),
        ))
        .write(const ConversationsCompanion(draft: Value('draft')));
    DataBaseEventBus.instance.updateConversations(['one', 'two']);

    final delta = await deltaFuture;
    expect(delta.changedIds, {'one', 'two'});
  });

  test('publishes an incoming message delta without a fixed delay', () async {
    final database = MixinDatabase(NativeDatabase.memory());
    final store = ConversationListStore(database);
    addTearDown(() async {
      await store.close();
      await database.close();
    });

    final now = DateTime(2026);
    await database.batch((batch) {
      batch
        ..insertAll(database.users, [
          const User(
            userId: 'me',
            identityNumber: '1',
            fullName: 'Me',
          ),
          const User(
            userId: 'sender',
            identityNumber: '2',
            fullName: 'Sender',
          ),
        ])
        ..insert(
          database.conversations,
          Conversation(
            conversationId: 'conversation',
            ownerId: 'sender',
            category: ConversationCategory.contact,
            createdAt: now,
            status: ConversationStatus.success,
          ),
        );
    });
    await store.start();

    final deltaFuture = store.events
        .where((event) => event is ConversationListDelta)
        .cast<ConversationListDelta>()
        .first;
    final stopwatch = Stopwatch()..start();
    await database.messageDao.insert(
      Message(
        messageId: 'message',
        conversationId: 'conversation',
        userId: 'sender',
        category: 'PLAIN_TEXT',
        content: 'hello',
        status: MessageStatus.delivered,
        createdAt: now.add(const Duration(minutes: 1)),
      ),
      'me',
      silent: true,
    );
    await deltaFuture;

    expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 200)));
    expect(store.items.single.content, 'hello');
    expect(store.items.single.unseenMessageCount, 1);
  });

  test('coalesces an incoming message burst into one projection', () async {
    final database = MixinDatabase(NativeDatabase.memory());
    final store = ConversationListStore(database);
    addTearDown(() async {
      await store.close();
      await database.close();
    });

    final now = DateTime(2026);
    await database.batch((batch) {
      batch
        ..insertAll(database.users, [
          const User(userId: 'me', identityNumber: '1', fullName: 'Me'),
          const User(
            userId: 'sender',
            identityNumber: '2',
            fullName: 'Sender',
          ),
        ])
        ..insert(
          database.conversations,
          Conversation(
            conversationId: 'conversation',
            ownerId: 'sender',
            category: ConversationCategory.contact,
            createdAt: now,
            status: ConversationStatus.success,
          ),
        );
    });
    await store.start();

    var projectionEvents = 0;
    final subscription = DataBaseEventBus.instance.updateConversationIdStream
        .where((ids) => ids.contains('conversation'))
        .listen((_) => projectionEvents++);
    addTearDown(subscription.cancel);
    final deltaFuture = store.events
        .where((event) => event is ConversationListDelta)
        .cast<ConversationListDelta>()
        .first
        .timeout(const Duration(milliseconds: 200));

    await Future.wait([
      for (var index = 0; index < 3; index++)
        database.messageDao.insert(
          Message(
            messageId: 'message-$index',
            conversationId: 'conversation',
            userId: 'sender',
            category: 'PLAIN_TEXT',
            content: 'message $index',
            status: MessageStatus.delivered,
            createdAt: now.add(Duration(minutes: index + 1)),
          ),
          'me',
          silent: true,
        ),
    ]);
    await deltaFuture;

    expect(projectionEvents, 1);
    expect(store.items.single.content, 'message 2');
    expect(store.items.single.unseenMessageCount, 3);
  });

  test('updates a group before the message sender user arrives', () async {
    final database = MixinDatabase(NativeDatabase.memory());
    final store = ConversationListStore(database);
    addTearDown(() async {
      await store.close();
      await database.close();
    });

    final now = DateTime(2026);
    await database.batch((batch) {
      batch
        ..insert(
          database.users,
          const User(
            userId: 'owner',
            identityNumber: '1',
            fullName: 'Owner',
          ),
        )
        ..insert(
          database.conversations,
          Conversation(
            conversationId: 'group',
            ownerId: 'owner',
            category: ConversationCategory.group,
            createdAt: now,
            status: ConversationStatus.success,
          ),
        );
    });
    await store.start();

    final deltaFuture = store.events
        .where((event) => event is ConversationListDelta)
        .cast<ConversationListDelta>()
        .first
        .timeout(const Duration(milliseconds: 200));
    await database.messageDao.insert(
      Message(
        messageId: 'message',
        conversationId: 'group',
        userId: 'missing-sender',
        category: 'PLAIN_TEXT',
        content: 'hello',
        status: MessageStatus.delivered,
        createdAt: now,
      ),
      'me',
      silent: true,
    );
    await deltaFuture;

    expect(store.items.single.content, 'hello');
    expect(store.items.single.unseenMessageCount, 1);
  });

  test('refreshes the last-message preview from message events', () async {
    final database = MixinDatabase(NativeDatabase.memory());
    final store = ConversationListStore(database);
    addTearDown(() async {
      await store.close();
      await database.close();
    });

    final now = DateTime(2026);
    await database.batch((batch) {
      batch
        ..insert(
          database.users,
          const User(
            userId: 'owner',
            identityNumber: '1',
            fullName: 'Owner',
          ),
        )
        ..insert(
          database.conversations,
          Conversation(
            conversationId: 'conversation',
            ownerId: 'owner',
            category: ConversationCategory.contact,
            createdAt: now,
            status: ConversationStatus.success,
          ),
        );
    });
    await database.messageDao.insert(
      Message(
        messageId: 'message',
        conversationId: 'conversation',
        userId: 'owner',
        category: 'PLAIN_TEXT',
        content: 'hello',
        status: MessageStatus.sent,
        createdAt: now,
      ),
      'me',
      silent: true,
    );
    await store.start();

    final deltaFuture = store.events
        .where((event) => event is ConversationListDelta)
        .cast<ConversationListDelta>()
        .first
        .timeout(const Duration(milliseconds: 200));
    await database.messageDao.updateMessageStatusById(
      'message',
      MessageStatus.delivered,
    );
    await deltaFuture;

    expect(store.items.single.messageStatus, MessageStatus.delivered);

    final mediaDeltaFuture = store.events
        .where((event) => event is ConversationListDelta)
        .cast<ConversationListDelta>()
        .first
        .timeout(const Duration(milliseconds: 200));
    await database.messageDao.updateGiphyMessage(
      'message',
      'media-url',
      1,
      null,
    );
    await mediaDeltaFuture;

    expect(store.items.single.mediaUrl, 'media-url');
  });

  test('refreshes contact metadata from user events', () async {
    final database = MixinDatabase(NativeDatabase.memory());
    final store = ConversationListStore(database);
    addTearDown(() async {
      await store.close();
      await database.close();
    });

    final now = DateTime(2026);
    await database.batch((batch) {
      batch
        ..insert(
          database.users,
          const User(
            userId: 'owner',
            identityNumber: '1',
            fullName: 'Before',
          ),
        )
        ..insert(
          database.conversations,
          Conversation(
            conversationId: 'conversation',
            ownerId: 'owner',
            category: ConversationCategory.contact,
            createdAt: now,
            status: ConversationStatus.success,
          ),
        );
    });
    await store.start();

    final deltaFuture = store.events
        .where((event) => event is ConversationListDelta)
        .cast<ConversationListDelta>()
        .first
        .timeout(const Duration(milliseconds: 200));
    await database.userDao.insert(
      const User(
        userId: 'owner',
        identityNumber: '1',
        fullName: 'After',
      ),
    );
    await deltaFuture;

    expect(store.items.single.name, 'After');
  });

  test('adds a conversation when its owner arrives later', () async {
    final database = MixinDatabase(NativeDatabase.memory());
    final store = ConversationListStore(database);
    addTearDown(() async {
      await store.close();
      await database.close();
    });

    await database
        .into(database.conversations)
        .insert(
          Conversation(
            conversationId: 'conversation',
            ownerId: 'owner',
            category: ConversationCategory.contact,
            createdAt: DateTime(2026),
            status: ConversationStatus.success,
          ),
        );
    await store.start();
    expect(store.items, isEmpty);

    final deltaFuture = store.events
        .where((event) => event is ConversationListDelta)
        .cast<ConversationListDelta>()
        .first
        .timeout(const Duration(milliseconds: 200));
    await database.userDao.insert(
      const User(
        userId: 'owner',
        identityNumber: '1',
        fullName: 'Owner',
      ),
    );
    await deltaFuture;

    expect(store.items.single.conversationId, 'conversation');
  });

  test('refreshes mention count when a conversation is cleared', () async {
    final database = MixinDatabase(NativeDatabase.memory());
    final store = ConversationListStore(database);
    addTearDown(() async {
      await store.close();
      await database.close();
    });

    final now = DateTime(2026);
    await database.batch((batch) {
      batch
        ..insert(
          database.users,
          const User(
            userId: 'owner',
            identityNumber: '1',
            fullName: 'Owner',
          ),
        )
        ..insert(
          database.conversations,
          Conversation(
            conversationId: 'conversation',
            ownerId: 'owner',
            category: ConversationCategory.contact,
            createdAt: now,
            status: ConversationStatus.success,
          ),
        )
        ..insert(
          database.messageMentions,
          const MessageMention(
            messageId: 'message',
            conversationId: 'conversation',
            hasRead: false,
          ),
        );
    });
    await store.start();
    expect(store.items.single.mentionCount, 1);

    final deltaFuture = store.events
        .where((event) => event is ConversationListDelta)
        .cast<ConversationListDelta>()
        .first
        .timeout(const Duration(milliseconds: 200));
    final mentionEventFuture = DataBaseEventBus
        .instance
        .updateMessageMentionStream
        .where(
          (events) => events.any(
            (event) => event.conversationId == 'conversation',
          ),
        )
        .first
        .timeout(const Duration(milliseconds: 200));
    await database.messageMentionDao.clearMessageMentionByConversationId(
      'conversation',
    );
    await Future.wait([deltaFuture, mentionEventFuture]);

    expect(store.items.single.mentionCount, 0);
  });
}
