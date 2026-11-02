@TestOn('linux || mac-os')
library;

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter_app/blaze/blaze_message.dart';
import 'package:flutter_app/blaze/vo/message_result.dart';
import 'package:flutter_app/constants/constants.dart';
import 'package:flutter_app/crypto/signal/signal_protocol.dart';
import 'package:flutter_app/db/dao/message_dao.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/widgets/message/send_message_dialog/attachment_extra.dart';
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
  });

  tearDown(() => database.dispose());

  // Stores a sent message and a pending resend request for it, then runs the
  // job and returns the content that was given to the session encryption.
  Future<String?> resend(Message message) async {
    await database.mixinDatabase
        .into(database.mixinDatabase.messages)
        .insert(message);
    await database.mixinDatabase
        .into(database.mixinDatabase.resendSessionMessages)
        .insert(
          ResendSessionMessage(
            messageId: message.messageId,
            userId: 'receiver',
            sessionId: 'receiver-session',
            status: 1,
            createdAt: DateTime.utc(2026),
          ),
        );
    final signalProtocol = _CapturingSignalProtocol();
    await SendingJob(
      database: database,
      sender: _FakeSender(),
      userId: 'sender',
      sessionId: 'session',
      privateKey: ed.generateKey().privateKey,
      signalProtocol: signalProtocol,
      deleteAttachment: (_) async {},
    ).run([
      Job(
        jobId: 'job',
        action: kSendingMessage,
        priority: 5,
        blazeMessage: message.messageId,
        createdAt: DateTime.utc(2026),
        runCount: 0,
      ),
    ]);
    return signalProtocol.encryptedContent;
  }

  test('resent attachment payload can be decoded by the receiver', () async {
    final extra = jsonEncode(
      AttachmentExtra(
        attachmentId: 'attachment',
        messageId: 'message',
        createdAt: '2026-10-31T12:00:00Z',
        shareable: false,
      ),
    );

    final content = await resend(
      Message(
        messageId: 'message',
        conversationId: 'conversation',
        userId: 'sender',
        category: MessageCategory.signalImage,
        content: extra,
        mediaMimeType: 'image/png',
        mediaSize: 1024,
        mediaWidth: 20,
        mediaHeight: 10,
        mediaKey: 'a2V5',
        mediaDigest: 'ZGlnZXN0',
        thumbImage: 'thumb',
        caption: 'caption',
        status: MessageStatus.read,
        createdAt: DateTime.utc(2026),
      ),
    );

    final payload = AttachmentMessage.fromJson(
      jsonDecode(utf8.decode(base64Decode(content!))) as Map<String, dynamic>,
    );
    expect(payload.attachmentId, 'attachment');
    expect(payload.key, 'a2V5');
    expect(payload.digest, 'ZGlnZXN0');
    expect(payload.mimeType, 'image/png');
    expect(payload.size, 1024);
    expect(payload.width, 20);
    expect(payload.height, 10);
    expect(payload.thumbnail, 'thumb');
    expect(payload.caption, 'caption');
    expect(payload.createdAt, '2026-10-31T12:00:00Z');
    expect(payload.shareable, isFalse);
  });

  test('resent text keeps its content', () async {
    final content = await resend(
      Message(
        messageId: 'message',
        conversationId: 'conversation',
        userId: 'sender',
        category: MessageCategory.signalText,
        content: 'hello',
        status: MessageStatus.read,
        createdAt: DateTime.utc(2026),
      ),
    );

    expect(content, 'hello');
  });

  test('resent attachment keeps content that is already a payload', () async {
    final payload = base64Encode(utf8.encode('{"attachment_id":"attachment"}'));
    final message = SendingMessage(
      messageId: 'message',
      conversationId: 'conversation',
      userId: 'sender',
      category: MessageCategory.signalImage,
      content: payload,
      status: MessageStatus.read,
      createdAt: DateTime.utc(2026),
    );

    expect(await attachmentResendPayload(message), payload);
  });
}

class _CapturingSignalProtocol extends SignalProtocol {
  _CapturingSignalProtocol() : super('sender');

  String? encryptedContent;

  @override
  Future<BlazeMessage> encryptSessionMessage(
    SendingMessage message,
    String recipientId, {
    String? resendMessageId,
    String? sessionId,
    List<String>? mentionData,
    bool silent = false,
    int expireIn = 0,
  }) async {
    encryptedContent = message.content;
    return BlazeMessage(id: 'blaze', action: kCreateMessage);
  }
}

class _FakeSender implements Sender {
  @override
  Future<void> checkConversationExists(Conversation conversation) async {}

  @override
  Future<bool> checkSignalSession(String recipientId, String sessionId) async =>
      true;

  @override
  Future<MessageResult> deliver(BlazeMessage blazeMessage) async =>
      MessageResult(true, false);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
