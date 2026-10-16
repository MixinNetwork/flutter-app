import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/ui/home/notifier/message_controller.dart';
import 'package:flutter_app/ui/provider/conversation_provider.dart';
import 'package:flutter_app/ui/provider/mention_cache_provider.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' show MessageStatus;

const _conversationId = 'conversation';

class _FakeAccountServer extends Fake implements AccountServer {
  @override
  Future<void> markRead(String conversationId) async {}
}

class _FakeConversationNotifier extends Fake
    implements ConversationStateNotifier {
  _FakeConversationNotifier(this._state);

  final _controller = StreamController<ConversationState?>.broadcast();
  ConversationState? _state;

  @override
  ConversationState? get state => _state;

  @override
  set state(ConversationState? value) {
    _state = value;
    _controller.add(value);
  }

  @override
  Stream<ConversationState?> get stream => _controller.stream;
}

String _id(int index) => 'm${index.toString().padLeft(2, '0')}';

void main() {
  test('does not expose a database read point as an unread boundary', () {
    expect(
      resolveMessageWindowLastReadMessageId(
        requestedLastReadMessageId: null,
        unseenMessageCount: 0,
        conversationLastReadMessageId: 'read-point',
      ),
      isNull,
    );
  });

  test('uses the conversation read point when there are unread messages', () {
    expect(
      resolveMessageWindowLastReadMessageId(
        requestedLastReadMessageId: null,
        unseenMessageCount: 1,
        conversationLastReadMessageId: 'read-point',
      ),
      'read-point',
    );
  });

  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(EventBus.initialize);

  group('page loads', () {
    late MixinDatabase mixinDatabase;
    late MessageController controller;
    late _FakeConversationNotifier conversation;
    // A page query waits for this gate after it reads the database.
    Completer<void>? gate;

    Future<void> until(bool Function() test) async {
      for (var i = 0; i < 200 && !test(); i++) {
        await pumpEventQueue();
      }
      expect(test(), isTrue);
    }

    List<String> ids() => [
      for (final message in controller.value.list)
        if (message.type != MessageCategory.secret) message.messageId,
    ];

    setUp(() async {
      mixinDatabase = MixinDatabase(NativeDatabase.memory());
      final database = Database(
        mixinDatabase,
        FtsDatabase(NativeDatabase.memory()),
      );
      await mixinDatabase.batch(
        (batch) => batch
          ..insert(
            mixinDatabase.users,
            const User(userId: 'user', identityNumber: '1', fullName: 'User'),
          )
          ..insertAll(mixinDatabase.messages, [
            for (var i = 1; i <= 20; i++)
              Message(
                messageId: _id(i),
                conversationId: _conversationId,
                userId: 'user',
                category: MessageCategory.plainText,
                content: 'message $i',
                status: MessageStatus.read,
                createdAt: DateTime(2026, 1, 1, 12, i),
              ),
          ]),
      );

      final real = MessageWindowLoader.fromDao(database.messageDao);
      gate = null;
      final mentionCache = MentionCache(mixinDatabase.userDao);
      conversation = _FakeConversationNotifier(
        ConversationState(
          conversationId: _conversationId,
          refreshKey: Object(),
          initIndexMessageId: _id(10),
        ),
      );
      controller = MessageController(
        conversationNotifier: conversation,
        limit: 4,
        database: database,
        mentionCache: mentionCache,
        accountServer: _FakeAccountServer(),
        messageWindowLoader: MessageWindowLoader(
          recentMessages: real.recentMessages,
          messageOrderInfo: real.messageOrderInfo,
          beforeMessages: (anchor, conversationId, limit) async {
            final messages = await real.beforeMessages(
              anchor,
              conversationId,
              limit,
            );
            await gate?.future;
            return messages;
          },
          afterMessages: (anchor, conversationId, limit) async {
            final messages = await real.afterMessages(
              anchor,
              conversationId,
              limit,
            );
            await gate?.future;
            return messages;
          },
          beforeMessageIds: real.beforeMessageIds,
          afterMessageIds: real.afterMessageIds,
          messagesByIds: real.messagesByIds,
        ),
      );
      addTearDown(() async {
        controller.dispose();
        mentionCache.dispose();
        await database.dispose();
      });
      await until(() => ids().contains(_id(10)));
    });

    test('loads older and newer pages in order to both ends', () async {
      final first = ids();
      expect(first, [for (var i = 8; i <= 12; i++) _id(i)]);

      while (!controller.value.isOldest) {
        final length = ids().length;
        controller.before();
        await until(() => ids().length > length || controller.value.isOldest);
      }
      while (!controller.value.isLatest) {
        final length = ids().length;
        controller.after();
        await until(() => ids().length > length || controller.value.isLatest);
      }

      expect(ids(), [for (var i = 1; i <= 20; i++) _id(i)]);
      expect(controller.value.top.first.type, MessageCategory.secret);
    });

    test('keeps a delete that arrives while an older page loads', () async {
      gate = Completer();
      controller.before();
      await pumpEventQueue();

      await mixinDatabase.messageDao.deleteMessage(_conversationId, _id(11));
      await until(() => !ids().contains(_id(11)));

      gate!.complete();
      await until(() => ids().contains(_id(4)));
      expect(ids(), [
        for (var i = 4; i <= 12; i++)
          if (i != 11) _id(i),
      ]);
    });

    test('keeps an edit that arrives while a newer page loads', () async {
      gate = Completer();
      controller.after();
      await pumpEventQueue();

      await mixinDatabase.messageDao.updateMessageContent(_id(9), 'edited');
      await until(
        () => controller.value.list.any(
          (message) =>
              message.messageId == _id(9) && message.content == 'edited',
        ),
      );

      gate!.complete();
      await until(() => ids().contains(_id(16)));
      expect(ids(), [for (var i = 8; i <= 16; i++) _id(i)]);
      expect(
        controller.value.list.singleWhere((m) => m.messageId == _id(9)).content,
        'edited',
      );
    });

    test('drops an incoming message deleted while its page loads', () async {
      gate = Completer();
      controller.before();
      await pumpEventQueue();

      await mixinDatabase.messageDao.deleteMessage(_conversationId, _id(5));
      await pumpEventQueue();

      gate!.complete();
      await until(() => ids().contains(_id(4)));
      expect(ids(), [
        for (var i = 4; i <= 12; i++)
          if (i != 5) _id(i),
      ]);
      expect(controller.value.isOldest, isFalse);
    });

    test('shows an incoming message edited while its page loads', () async {
      gate = Completer();
      controller.after();
      await pumpEventQueue();

      await mixinDatabase.messageDao.updateMessageContent(_id(14), 'edited');
      await pumpEventQueue();

      gate!.complete();
      await until(() => ids().contains(_id(16)));
      expect(ids(), [for (var i = 8; i <= 16; i++) _id(i)]);
      expect(
        controller.value.list
            .singleWhere((m) => m.messageId == _id(14))
            .content,
        'edited',
      );
    });

    test(
      'adds the older page when its anchor is deleted during the load',
      () async {
        gate = Completer();
        controller.before();
        await pumpEventQueue();

        await mixinDatabase.messageDao.deleteMessage(_conversationId, _id(8));
        await until(() => !ids().contains(_id(8)));

        gate!.complete();
        await until(() => ids().contains(_id(4)));
        expect(ids(), [
          for (var i = 4; i <= 12; i++)
            if (i != 8) _id(i),
        ]);
      },
    );

    test(
      'drops the page when the conversation changes during the load',
      () async {
        gate = Completer();
        controller.before();
        await pumpEventQueue();

        conversation.state = const ConversationState(
          conversationId: 'other',
          refreshKey: 'other',
        );
        await until(() => controller.value.conversationId == 'other');

        gate!.complete();
        await pumpEventQueue(times: 50);
        expect(controller.value.conversationId, 'other');
        expect(ids(), isEmpty);
      },
    );
  });
}
