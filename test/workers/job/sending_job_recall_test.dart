@TestOn('linux || mac-os')
library;

import 'package:drift/native.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter_app/account/send_message_helper.dart';
import 'package:flutter_app/blaze/blaze_message.dart';
import 'package:flutter_app/blaze/vo/message_result.dart';
import 'package:flutter_app/constants/constants.dart';
import 'package:flutter_app/crypto/signal/signal_protocol.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/extension/job.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/utils/attachment/attachment_util.dart';
import 'package:flutter_app/workers/job/sending_job.dart';
import 'package:flutter_app/workers/sender.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide Conversation;

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
            content: 'keep until acknowledged',
            status: MessageStatus.read,
            createdAt: DateTime.utc(2026),
          ),
        );
  });

  tearDown(() => database.dispose());

  test('requesting recall keeps the local message until delivery', () async {
    final jobs = <Job>[];
    final helper = SendMessageHelper(
      database,
      _UnusedAttachmentUtil(),
      jobs.add,
    );

    await helper.sendRecallMessage('conversation', ['message']);

    final message = await database.messageDao.findMessageByMessageId('message');
    expect(message?.category, MessageCategory.plainText);
    expect(message?.content, 'keep until acknowledged');
    expect(jobs, hasLength(1));
    expect(jobs.single.action, kRecallMessage);
  });

  test('successful recall delivery applies the local recall', () async {
    final job = await createSendRecallJob('conversation', 'message');

    await sendingJob(database, MessageResult(true, false)).run([job]);

    final message = await database.messageDao.findMessageByMessageId('message');
    expect(message?.category, MessageCategory.messageRecall);
    expect(message?.content, isNull);
  });

  test('rejected recall delivery preserves the local message', () async {
    final job = await createSendRecallJob('conversation', 'message');

    await sendingJob(
      database,
      MessageResult(true, false, forbidden),
    ).run([job]);

    final message = await database.messageDao.findMessageByMessageId('message');
    expect(message?.category, MessageCategory.plainText);
    expect(message?.content, 'keep until acknowledged');
  });

  test('acknowledged recall resumes cleanup without redelivery', () async {
    final job = (await createSendRecallJob(
      'conversation',
      'message',
    )).copyWith(runCount: 1);

    await SendingJob(
      database: database,
      sender: _ThrowingSender(),
      userId: 'sender',
      sessionId: 'session',
      privateKey: ed.generateKey().privateKey,
      signalProtocol: SignalProtocol('sender'),
      deleteAttachment: (_) async {},
    ).run([job]);

    final message = await database.messageDao.findMessageByMessageId('message');
    expect(message?.category, MessageCategory.messageRecall);
    expect(await database.jobDao.jobById(job.jobId), isNull);
  });

  test('attachment cleanup failure keeps the acknowledged job', () async {
    await database.mixinDatabase.customStatement(
      'UPDATE messages SET category = ? WHERE message_id = ?',
      [MessageCategory.plainImage, 'message'],
    );
    final job = await createSendRecallJob('conversation', 'message');

    await sendingJob(
      database,
      MessageResult(true, false),
      deleteAttachment: (_) async => throw StateError('file is busy'),
    ).run([job]);

    final storedJob = await database.jobDao.jobById(job.jobId);
    final message = await database.messageDao.findMessageByMessageId('message');
    expect(storedJob?.runCount, 1);
    expect(message?.category, MessageCategory.plainImage);
  });
}

class _UnusedAttachmentUtil implements AttachmentUtil {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSender implements Sender {
  _FakeSender(this.result);

  final MessageResult result;

  @override
  Future<MessageResult> deliver(BlazeMessage blazeMessage) async => result;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingSender implements Sender {
  @override
  Future<MessageResult> deliver(BlazeMessage blazeMessage) =>
      throw StateError('acknowledged recall must not be redelivered');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SendingJob sendingJob(
  Database database,
  MessageResult result, {
  Future<void> Function(Message message)? deleteAttachment,
}) => SendingJob(
  database: database,
  sender: _FakeSender(result),
  userId: 'sender',
  sessionId: 'session',
  privateKey: ed.generateKey().privateKey,
  signalProtocol: SignalProtocol('sender'),
  deleteAttachment: deleteAttachment ?? (_) async {},
);
