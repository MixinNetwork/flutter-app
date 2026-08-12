@TestOn('linux || mac-os')
library;

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_app/account/send_message_helper.dart';
import 'package:flutter_app/db/dao/job_dao.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/encrypt_category.dart';
import 'package:flutter_app/utils/attachment/attachment_util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    hide Conversation, User;

void main() {
  late Database database;
  late SendMessageHelper helper;
  late List<Job> jobs;

  setUp(() async {
    database = Database(
      MixinDatabase(NativeDatabase.memory()),
      FtsDatabase(NativeDatabase.memory()),
    );
    await database.mixinDatabase
        .into(database.mixinDatabase.users)
        .insert(const User(userId: 'sender', identityNumber: '1000'));
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
        .into(database.mixinDatabase.users)
        .insert(const User(userId: 'bare-bot', identityNumber: '7000'));
    await database.mixinDatabase
        .into(database.mixinDatabase.users)
        .insert(
          const User(userId: 'full-bot', identityNumber: '7000105415'),
        );
    await database.mixinDatabase
        .into(database.mixinDatabase.users)
        .insert(
          const User(userId: 'unjoined-bot', identityNumber: '7000999999'),
        );
    await database.mixinDatabase
        .into(database.mixinDatabase.participants)
        .insert(
          Participant(
            conversationId: 'conversation',
            userId: 'bare-bot',
            createdAt: DateTime.utc(2026),
          ),
        );
    await database.mixinDatabase
        .into(database.mixinDatabase.participants)
        .insert(
          Participant(
            conversationId: 'conversation',
            userId: 'full-bot',
            createdAt: DateTime.utc(2026),
          ),
        );

    jobs = [];
    helper = SendMessageHelper(database, _UnusedAttachmentUtil(), jobs.add);
  });

  tearDown(() async {
    await pumpEventQueue();
    await database.dispose();
  });

  const cases = <String, String?>{
    '@7000 hello': 'bare-bot',
    '@7000 ': 'bare-bot',
    '@7000  hello': 'bare-bot',
    '@7000105415 hello': 'full-bot',
    '@7000105415 ': 'full-bot',
    '@7000 @7000105415 hello': 'bare-bot',
    '@7000105415 @7000 hello': 'full-bot',
    '@7000': null,
    '@7000U hello': null,
    '@7000hello': null,
    '@7000\thello': null,
    '@7000\nhello': null,
    '@7000\u00a0hello': null,
    '@7000, hello': null,
    '@7000。hello': null,
    '@7000105415U hello': null,
    '@7000105415hello': null,
    '@7000105415, hello': null,
    '@70001 hello': null,
    '@70001054151 hello': null,
    'hello @7000 hello': null,
    ' @7000 hello': null,
    '@7000U @7000 hello': null,
    '@70001 @7000 hello': null,
    '@7000999999 hello': null,
  };

  test('routes configured bot mentions', () async {
    for (final entry in cases.entries) {
      await helper.sendTextMessage(
        'conversation',
        'sender',
        EncryptCategory.encrypted,
        entry.key,
      );

      final job = jobs.removeLast();
      final payload = jsonDecode(job.blazeMessage!) as Map<String, dynamic>;
      expect(
        payload[JobDao.recipientIdKey],
        entry.value,
        reason: entry.key,
      );
    }
  });
}

class _UnusedAttachmentUtil implements AttachmentUtil {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
