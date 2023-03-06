import 'dao/app_dao.dart';
import 'dao/asset_dao.dart';
import 'dao/chain_dao.dart';
import 'dao/circle_conversation_dao.dart';
import 'dao/circle_dao.dart';
import 'dao/conversation_dao.dart';
import 'dao/expired_message_dao.dart';
import 'dao/favorite_app_dao.dart';
import 'dao/fiat_dao.dart';
import 'dao/flood_message_dao.dart';
import 'dao/job_dao.dart';
import 'dao/message_dao.dart';
import 'dao/message_history_dao.dart';
import 'dao/message_mention_dao.dart';
import 'dao/offset_dao.dart';
import 'dao/participant_dao.dart';
import 'dao/participant_session_dao.dart';
import 'dao/pin_message_dao.dart';
import 'dao/resend_session_message_dao.dart';
import 'dao/snapshot_dao.dart';
import 'dao/sticker_album_dao.dart';
import 'dao/sticker_dao.dart';
import 'dao/sticker_relationship_dao.dart';
import 'dao/transcript_message_dao.dart';
import 'dao/user_dao.dart';
import 'fts_database.dart';
import 'mixin_database.dart';

class Database {
  Database(this.mixinDatabase, this.ftsDatabase) {
    appDao = AppDao(mixinDatabase);
    assetDao = AssetDao(mixinDatabase);
    chainDao = ChainDao(mixinDatabase);
    conversationDao = ConversationDao(mixinDatabase);
    circleDao = CircleDao(mixinDatabase);
    circleConversationDao = CircleConversationDao(mixinDatabase);
    floodMessageDao = FloodMessageDao(mixinDatabase);
    messageDao = MessageDao(mixinDatabase);
    messagesHistoryDao = MessageHistoryDao(mixinDatabase);
    messageMentionDao = MessageMentionDao(mixinDatabase);
    jobDao = JobDao(mixinDatabase);
    offsetDao = OffsetDao(mixinDatabase);
    participantDao = ParticipantDao(mixinDatabase);
    resendSessionMessageDao = ResendSessionMessageDao(mixinDatabase);
    snapshotDao = SnapshotDao(mixinDatabase);
    stickerDao = StickerDao(mixinDatabase);
    stickerAlbumDao = StickerAlbumDao(mixinDatabase);
    stickerRelationshipDao = StickerRelationshipDao(mixinDatabase);
    participantSessionDao = ParticipantSessionDao(mixinDatabase);
    userDao = UserDao(mixinDatabase);
    transcriptMessageDao = TranscriptMessageDao(mixinDatabase);
    pinMessageDao = PinMessageDao(mixinDatabase);
    fiatDao = FiatDao(mixinDatabase);
    favoriteAppDao = FavoriteAppDao(mixinDatabase);
    expiredMessageDao = ExpiredMessageDao(mixinDatabase);
  }

  // static MixinDatabase _database;
  // static Future init() async {
  //   _database = await getMixinDatabaseConnection('3910');
  // }

  final MixinDatabase mixinDatabase;

  final FtsDatabase ftsDatabase;

  late final AppDao appDao;

  late final AssetDao assetDao;

  late final ChainDao chainDao;

  late final MessageDao messageDao;

  late final MessageHistoryDao messagesHistoryDao;

  late final MessageMentionDao messageMentionDao;

  late final ConversationDao conversationDao;

  late final CircleDao circleDao;

  late final CircleConversationDao circleConversationDao;

  late final FloodMessageDao floodMessageDao;

  late final JobDao jobDao;

  late final OffsetDao offsetDao;

  late final ParticipantDao participantDao;

  late final ParticipantSessionDao participantSessionDao;

  late final ResendSessionMessageDao resendSessionMessageDao;

  late final SnapshotDao snapshotDao;

  late final StickerDao stickerDao;

  late final StickerAlbumDao stickerAlbumDao;

  late final StickerRelationshipDao stickerRelationshipDao;

  late final UserDao userDao;

  late final TranscriptMessageDao transcriptMessageDao;

  late final PinMessageDao pinMessageDao;

  late final FiatDao fiatDao;

  late final FavoriteAppDao favoriteAppDao;

  late final ExpiredMessageDao expiredMessageDao;

  Future<void> dispose() async {
    await mixinDatabase.close();
    await ftsDatabase.close();
    // dispose stream, https://github.com/simolus3/moor/issues/290
  }

  Future<T> transaction<T>(Future<T> Function() action) =>
      mixinDatabase.transaction<T>(action);
}
