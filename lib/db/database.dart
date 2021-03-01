import 'package:flutter/foundation.dart';
import 'package:flutter_app/db/dao/sticker_albums_dao.dart';
import 'package:flutter_app/db/dao/sticker_relationships_dao.dart';
import 'package:flutter_app/db/dao/stickers_dao.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/enum/message_status.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:moor/moor.dart';

import 'dao/apps_dao.dart';
import 'dao/conversations_dao.dart';
import 'dao/flood_messages_dao.dart';
import 'dao/jobs_dao.dart';
import 'dao/messages_dao.dart';
import 'dao/participants_dao.dart';
import 'dao/users_dao.dart';
import 'mixin_database.dart';

class Database {
  Database(this._database) {
    appsDao = AppsDao(_database);
    conversationDao = ConversationsDao(_database);
    floodMessagesDao = FloodMessagesDao(_database);
    messagesDao = MessagesDao(_database);
    jobsDao = JobsDao(_database);
    participantsDao = ParticipantsDao(_database);
    userDao = UserDao(_database);
    stickerDao = StickerDao(_database);
    stickerAlbumsDao = StickerAlbumsDao(_database);
    stickerRelationshipsDao = StickerRelationshipsDao(_database);
  }

  // static MixinDatabase _database;
  // static Future init() async {
  //   _database = await getMixinDatabaseConnection('3910');
  // }

  final MixinDatabase _database;

  late final AppsDao appsDao;

  late final MessagesDao messagesDao;

  late final ConversationsDao conversationDao;

  late final FloodMessagesDao floodMessagesDao;

  late final JobsDao jobsDao;

  late final ParticipantsDao participantsDao;

  late final UserDao userDao;

  late final StickerDao stickerDao;

  late final StickerAlbumsDao stickerAlbumsDao;

  late final StickerRelationshipsDao stickerRelationshipsDao;

  Future<void> dispose() async {
    await _database.eventBus.dispose();
    await _database.close();
    // dispose stream, https://github.com/simolus3/moor/issues/290
  }

  void mock() async {
    final user = await (_database.select(_database.users)
          ..where((tbl) => tbl.userId.equals('mockUserId0'))
          ..limit(1))
        .getSingle();
    if (user != null) return;

    debugPrint('mock start');
    await _database.transaction(() async {
      for (var i = 0; i < 30; i++) {
        debugPrint('mock start user $i');
        final conversationId = 'mockConversationId$i';
        final userId = 'mockUserId$i';
        final dateTime = DateTime.now();
        await _database.batch((batch) {
          batch
            ..insert(
              _database.users,
              UsersCompanion.insert(
                userId: userId,
                identityNumber: 'mockUserIdentityNumber$i',
                relationship: const Value(UserRelationship.stranger),
                fullName: Value('mockUserFullName$i'),
                avatarUrl: const Value('https://www.google.com/&safe=off'),
              ),
            )
            ..insert(
              _database.conversations,
              ConversationsCompanion.insert(
                conversationId: conversationId,
                ownerId: Value(userId),
                createdAt: dateTime,
                status: ConversationStatus.success,
                category: const Value(ConversationCategory.contact),
              ),
            )
            ..insertAll(
              _database.messages,
              List.generate(
                10000,
                (index) => MessagesCompanion.insert(
                  messageId: 'mockMessageId$i-$index',
                  conversationId: conversationId,
                  userId: userId,
                  category: MessageCategory.plainText,
                  status: MessageStatus.failed,
                  createdAt: dateTime.subtract(Duration(seconds: index)),
                  content: Value('message content $index'),
                ),
              ),
            );
        });

        debugPrint('mock end user $i');
      }
    });
    debugPrint('mock end');
  }
}
