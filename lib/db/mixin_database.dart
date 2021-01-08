import 'dart:io';

import 'package:flutter_app/db/dao/hyperlinks_dao.dart';
import 'package:flutter_app/db/dao/jobs_dao.dart';
import 'package:flutter_app/db/dao/message_mentions_dao.dart';
import 'package:flutter_app/db/dao/messages_dao.dart';
import 'package:flutter_app/db/dao/messages_history_dao.dart';
import 'package:flutter_app/db/dao/participants_dao.dart';
import 'package:flutter_app/db/dao/resend_session_messages_dao.dart';
import 'package:flutter_app/db/dao/stickers_dao.dart';
import 'package:flutter_app/db/dao/users_dao.dart';
import 'package:moor/moor.dart';
// These imports are only needed to open the database
import 'package:moor/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'dao/addresses_dao.dart';
import 'dao/apps_dao.dart';
import 'dao/assets_dao.dart';
import 'dao/circle_conversations_dao.dart';
import 'dao/circles_dao.dart';
import 'dao/conversations_dao.dart';
import 'dao/flood_messages_dao.dart';
import 'dao/offsets_dao.dart';
import 'dao/participant_session_dao.dart';
import 'dao/sent_session_sender_keys_dao.dart';
import 'dao/snapshots_dao.dart';
import 'dao/sticker_albums_dao.dart';
import 'dao/sticker_relationships_dao.dart';

part 'mixin_database.g.dart';

@UseMoor(include: {
  'mixin.moor'
}, daos: [
  AddressesDao,
  AppsDao,
  AssetsDao,
  CircleConversationDao,
  CirclesDao,
  ConversationsDao,
  FloodMessagesDao,
  HyperlinksDao,
  JobsDao,
  MessageMentionsDao,
  MessagesDao,
  MessagesHistoryDao,
  OffsetsDao,
  ParticipantsDao,
  ParticipantSessionDao,
  ResendSessionMessagesDao,
  SentSessionSenderKeysDao,
  SnapshotsDao,
  StickerDao,
  StickerAlbumsDao,
  StickerRelationshipsDao,
  UserDao,
], queries: {
  'conversationItems':
      '''SELECT c.conversation_id AS conversationId, c.icon_url AS groupIconUrl, c.category AS category,
            c.name AS groupName, c.status AS status, c.last_read_message_id AS lastReadMessageId,
            c.unseen_message_count AS unseenMessageCount, c.owner_id AS ownerId, c.pin_time AS pinTime, c.mute_until AS muteUntil,
            ou.avatar_url AS avatarUrl, ou.full_name AS name, ou.is_verified AS ownerVerified,
            ou.identity_number AS ownerIdentityNumber, ou.mute_until AS ownerMuteUntil, ou.app_id AS appId,
            m.content AS content, m.category AS contentType, m.created_at AS createdAt, m.media_url AS mediaUrl,
            m.user_id AS senderId, m.action AS actionName, m.status AS messageStatus,
            mu.full_name AS senderFullName, s.type AS SnapshotType,
            pu.full_name AS participantFullName, pu.user_id AS participantUserId,
            (SELECT count(*) FROM message_mentions me WHERE me.conversation_id = c.conversation_id AND me.has_read = 0) as mentionCount,  
            mm.mentions AS mentions 
            FROM conversations c
            INNER JOIN users ou ON ou.user_id = c.owner_id
            LEFT JOIN messages m ON c.last_message_id = m.id
            LEFT JOIN message_mentions mm ON mm.message_id = m.id
            LEFT JOIN users mu ON mu.user_id = m.user_id
            LEFT JOIN snapshots s ON s.snapshot_id = m.snapshot_id
            LEFT JOIN users pu ON pu.user_id = m.participant_id
            WHERE c.category IS NOT NULL 
            ORDER BY c.pin_time DESC, 
              CASE 
                WHEN m.created_at is NULL THEN c.created_at
                ELSE m.created_at 
              END 
            DESC
            '''
})
class MixinDatabase extends _$MixinDatabase {
  MixinDatabase(this.identityNumber) : super(_openConnection(identityNumber));

  final String identityNumber;

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection(String identityNumber) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, identityNumber, 'mixin.db'));
    return VmDatabase(file);
  });
}
