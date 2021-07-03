import 'dao/app_dao.dart';
import 'dao/asset_dao.dart';
import 'dao/circle_conversation_dao.dart';
import 'dao/circle_dao.dart';
import 'dao/conversation_dao.dart';
import 'dao/flood_message_dao.dart';
import 'dao/job_dao.dart';
import 'dao/message_dao.dart';
import 'dao/message_history_dao.dart';
import 'dao/message_mention_dao.dart';
import 'dao/offset_dao.dart';
import 'dao/participant_dao.dart';
import 'dao/participant_session_dao.dart';
import 'dao/resend_session_message_dao.dart';
import 'dao/snapshot_dao.dart';
import 'dao/sticker_album_dao.dart';
import 'dao/sticker_dao.dart';
import 'dao/sticker_relationship_dao.dart';
import 'dao/user_dao.dart';
import 'mixin_database.dart';

class Database {
  Database(this.mixinDatabase) {
    appDao = AppDao(mixinDatabase);
    assetsDao = AssetDao(mixinDatabase);
    conversationDao = ConversationDao(mixinDatabase);
    circlesDao = CircleDao(mixinDatabase);
    circleConversationDao = CircleConversationDao(mixinDatabase);
    floodMessagesDao = FloodMessageDao(mixinDatabase);
    messagesDao = MessageDao(mixinDatabase);
    messagesHistoryDao = MessageHistoryDao(mixinDatabase);
    messageMentionsDao = MessageMentionDao(mixinDatabase);
    jobsDao = JobDao(mixinDatabase);
    offsetsDao = OffsetDao(mixinDatabase);
    participantsDao = ParticipantDao(mixinDatabase);
    resendSessionMessagesDao = ResendSessionMessageDao(mixinDatabase);
    snapshotsDao = SnapshotDao(mixinDatabase);
    stickerDao = StickerDao(mixinDatabase);
    stickerAlbumsDao = StickerAlbumDao(mixinDatabase);
    stickerRelationshipsDao = StickerRelationshipDao(mixinDatabase);
    participantSessionDao = ParticipantSessionDao(mixinDatabase);
    userDao = UserDao(mixinDatabase);
  }

  // static MixinDatabase _database;
  // static Future init() async {
  //   _database = await getMixinDatabaseConnection('3910');
  // }

  final MixinDatabase mixinDatabase;

  late final AppDao appDao;

  late final AssetDao assetsDao;

  late final MessageDao messagesDao;

  late final MessageHistoryDao messagesHistoryDao;

  late final MessageMentionDao messageMentionsDao;

  late final ConversationDao conversationDao;

  late final CircleDao circlesDao;

  late final CircleConversationDao circleConversationDao;

  late final FloodMessageDao floodMessagesDao;

  late final JobDao jobsDao;

  late final OffsetDao offsetsDao;

  late final ParticipantDao participantsDao;

  late final ParticipantSessionDao participantSessionDao;

  late final ResendSessionMessageDao resendSessionMessagesDao;

  late final SnapshotDao snapshotsDao;

  late final StickerDao stickerDao;

  late final StickerAlbumDao stickerAlbumsDao;

  late final StickerRelationshipDao stickerRelationshipsDao;

  late final UserDao userDao;

  Future<void> dispose() async {
    await mixinDatabase.eventBus.dispose();
    await mixinDatabase.close();
    // dispose stream, https://github.com/simolus3/moor/issues/290
  }

  Future<T> transaction<T>(Future<T> Function() action) =>
      mixinDatabase.transaction<T>(action);
}
