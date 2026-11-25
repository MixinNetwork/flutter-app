@TestOn('linux || mac-os')
library;

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter_app/account/send_message_helper.dart';
import 'package:flutter_app/blaze/blaze_message.dart';
import 'package:flutter_app/blaze/vo/message_result.dart';
import 'package:flutter_app/constants/constants.dart';
import 'package:flutter_app/crypto/signal/signal_protocol.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/extension/job.dart';
import 'package:flutter_app/db/extension/message.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/utils/attachment/attachment_util.dart';
import 'package:flutter_app/workers/job/sending_job.dart';
import 'package:flutter_app/workers/sender.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    hide Conversation, User;

void main() {
  late Database database;

  setUp(() async {
    database = Database(
      MixinDatabase(NativeDatabase.memory()),
      FtsDatabase(NativeDatabase.memory()),
    );
    await database.mixinDatabase
        .into(database.mixinDatabase.conversations)
        .insert(
          Conversation(
            conversationId: 'conversation',
            ownerId: 'sender',
            category: ConversationCategory.contact,
            lastMessageId: 'message',
            createdAt: DateTime.utc(2026),
            status: ConversationStatus.success,
          ),
        );
    await database.mixinDatabase
        .into(database.mixinDatabase.messages)
        .insert(
          Message(
            messageId: 'message',
            conversationId: 'conversation',
            userId: 'sender',
            category: MessageCategory.plainText,
            content: 'hello',
            status: MessageStatus.read,
            createdAt: DateTime.utc(2026),
          ),
        );
  });

  tearDown(() => database.dispose());

  test('requesting recall applies the local recall at once', () async {
    final jobs = <Job>[];
    final helper = SendMessageHelper(
      database,
      _UnusedAttachmentUtil(),
      jobs.add,
    );

    await helper.sendRecallMessage('conversation', ['message'], 'me');

    final message = await database.messageDao.findMessageByMessageId('message');
    expect(message?.category, MessageCategory.messageRecall);
    expect(message?.content, isNull);
    expect(message?.participantId, 'me');
    expect(jobs, hasLength(1));
    expect(jobs.single.action, kRecallMessage);
    expect(await database.jobDao.jobById(jobs.single.jobId), isNotNull);
  });

  test('a recall keeps an uncached actor as the actor', () async {
    await database.mixinDatabase
        .into(database.mixinDatabase.users)
        .insert(const User(userId: 'sender', identityNumber: '1'));
    await database.recallMessage(
      'conversation',
      'message',
      actorUserId: 'admin',
      currentUserId: 'me',
    );

    final item = await database.messageDao
        .messageItemByMessageId('message')
        .getSingle();
    final quote = await database.messageDao.findMessageItemById(
      'conversation',
      'message',
    );
    final conversation = await database.conversationDao
        .conversationItem('conversation')
        .getSingle();
    expect(item.participantUserId, 'admin');
    expect(quote?.participantUserId, 'admin');
    expect(conversation.participantUserId, 'admin');
  });

  for (final runCount in [0, 1]) {
    test('a legacy recall job with runCount $runCount recalls the message '
        'once the server accepts it', () async {
      final job = (await createSendRecallJob(
        'conversation',
        'message',
      )).copyWith(runCount: runCount);
      await database.jobDao.insert(job);

      final sender = _FakeSender(MessageResult(true, false));
      final queue = SendingJob(
        database: database,
        sender: sender,
        userId: 'sender',
        sessionId: 'session',
        privateKey: ed.generateKey().privateKey,
        signalProtocol: SignalProtocol('sender'),
        deleteAttachment: (_) {},
      )..stop(); // Keep its own loop from delivering the job too.
      await queue.run([job]);

      final message = await database.messageDao.findMessageByMessageId(
        'message',
      );
      expect(message?.category, MessageCategory.messageRecall);
      expect(message?.content, isNull);
      expect(sender.deliveries, runCount == 0 ? 1 : 0);
      expect(await database.jobDao.jobById(job.jobId), isNull);
    });
  }

  test('a recall updates the quotes of the message with its actor', () async {
    await database.mixinDatabase.batch(
      (batch) => batch.insertAll(database.mixinDatabase.users, const [
        User(userId: 'sender', identityNumber: '1', fullName: 'Sender'),
        User(userId: 'me', identityNumber: '2', fullName: 'Me'),
      ]),
    );
    await database.mixinDatabase
        .into(database.mixinDatabase.messages)
        .insert(
          Message(
            messageId: 'reply',
            conversationId: 'conversation',
            userId: 'me',
            category: MessageCategory.plainText,
            content: 'reply',
            status: MessageStatus.read,
            createdAt: DateTime.utc(2026),
            quoteMessageId: 'message',
            quoteContent: '{}',
          ),
        );

    await SendMessageHelper(
      database,
      _UnusedAttachmentUtil(),
      (_) {},
    ).sendRecallMessage('conversation', ['message'], 'me');

    final reply = await database.messageDao.findMessageByMessageId('reply');
    final quote = mapToQuoteMessage(
      jsonDecode(reply!.quoteContent!) as Map<String, dynamic>,
    );
    expect(quote.type, MessageCategory.messageRecall);
    expect(quote.participantUserId, 'me');
    expect(quote.participantFullName, 'Me');
  });

  for (final (name, result, kept) in [
    ('delivered', MessageResult(true, false), false),
    ('rejected', MessageResult(true, false, badData), false),
    ('failed', MessageResult(false, true), true),
  ]) {
    test(
      'a $name recall delivery ${kept ? 'keeps' : 'removes'} the job',
      () async {
        final job = await createSendRecallJob('conversation', 'message');
        await database.jobDao.insert(job);

        final queue = sendingJob(database, result);
        addTearDown(queue.stop);
        await queue.run([job]);

        expect(
          await database.jobDao.jobById(job.jobId),
          kept ? isNotNull : isNull,
        );
      },
    );
  }
}

class _UnusedAttachmentUtil implements AttachmentUtil {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSender implements Sender {
  _FakeSender(this.result);

  final MessageResult result;
  int deliveries = 0;

  @override
  Future<MessageResult> deliver(BlazeMessage blazeMessage) async {
    deliveries++;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SendingJob sendingJob(Database database, MessageResult result) => SendingJob(
  database: database,
  sender: _FakeSender(result),
  userId: 'sender',
  sessionId: 'session',
  privateKey: ed.generateKey().privateKey,
  signalProtocol: SignalProtocol('sender'),
  deleteAttachment: (_) {},
);
