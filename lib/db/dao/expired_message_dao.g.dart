// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expired_message_dao.dart';

// ignore_for_file: type=lint
mixin _$ExpiredMessageDaoMixin on DatabaseAccessor<MixinDatabase> {
  ExpiredMessages get expiredMessages => attachedDatabase.expiredMessages;
  Addresses get addresses => attachedDatabase.addresses;
  Apps get apps => attachedDatabase.apps;
  Assets get assets => attachedDatabase.assets;
  CircleConversations get circleConversations =>
      attachedDatabase.circleConversations;
  Circles get circles => attachedDatabase.circles;
  Conversations get conversations => attachedDatabase.conversations;
  FloodMessages get floodMessages => attachedDatabase.floodMessages;
  Hyperlinks get hyperlinks => attachedDatabase.hyperlinks;
  Jobs get jobs => attachedDatabase.jobs;
  MessageMentions get messageMentions => attachedDatabase.messageMentions;
  Messages get messages => attachedDatabase.messages;
  MessagesHistory get messagesHistory => attachedDatabase.messagesHistory;
  Offsets get offsets => attachedDatabase.offsets;
  ParticipantSession get participantSession =>
      attachedDatabase.participantSession;
  Participants get participants => attachedDatabase.participants;
  ResendSessionMessages get resendSessionMessages =>
      attachedDatabase.resendSessionMessages;
  SentSessionSenderKeys get sentSessionSenderKeys =>
      attachedDatabase.sentSessionSenderKeys;
  Snapshots get snapshots => attachedDatabase.snapshots;
  StickerAlbums get stickerAlbums => attachedDatabase.stickerAlbums;
  StickerRelationships get stickerRelationships =>
      attachedDatabase.stickerRelationships;
  Stickers get stickers => attachedDatabase.stickers;
  Users get users => attachedDatabase.users;
  TranscriptMessages get transcriptMessages =>
      attachedDatabase.transcriptMessages;
  PinMessages get pinMessages => attachedDatabase.pinMessages;
  Fiats get fiats => attachedDatabase.fiats;
  FavoriteApps get favoriteApps => attachedDatabase.favoriteApps;
  Chains get chains => attachedDatabase.chains;
  Properties get properties => attachedDatabase.properties;
  SafeSnapshots get safeSnapshots => attachedDatabase.safeSnapshots;
  Tokens get tokens => attachedDatabase.tokens;
  InscriptionCollections get inscriptionCollections =>
      attachedDatabase.inscriptionCollections;
  InscriptionItems get inscriptionItems => attachedDatabase.inscriptionItems;
  Selectable<ExpiredMessage> getExpiredMessages(int? currentTime) {
    return customSelect(
      'SELECT * FROM expired_messages WHERE expire_at <= ?1 ORDER BY expire_at ASC',
      variables: [Variable<int>(currentTime)],
      readsFrom: {expiredMessages},
    ).asyncMap(expiredMessages.mapFromRow);
  }

  Selectable<ExpiredMessage> getFirstExpiredMessage() {
    return customSelect(
      'SELECT * FROM expired_messages WHERE expire_at IS NOT NULL ORDER BY expire_at ASC LIMIT 1',
      variables: [],
      readsFrom: {expiredMessages},
    ).asyncMap(expiredMessages.mapFromRow);
  }

  Future<int> updateMessageExpireAt(int? expireAt, String messageId) {
    return customUpdate(
      'UPDATE expired_messages SET expire_at = ?1 WHERE message_id = ?2 AND(expire_at IS NULL || expire_at > ?1)',
      variables: [Variable<int>(expireAt), Variable<String>(messageId)],
      updates: {expiredMessages},
      updateKind: UpdateKind.update,
    );
  }

  Future<int> _markExpiredMessageRead(
    double currentTime,
    MarkExpiredMessageRead$where where,
  ) {
    var $arrayStartIndex = 2;
    final generatedwhere = $write(
      where(this.expiredMessages),
      startIndex: $arrayStartIndex,
    );
    $arrayStartIndex += generatedwhere.amountOfVariables;
    return customUpdate(
      'UPDATE expired_messages SET expire_at = CAST((?1 + expire_in)AS INTEGER) WHERE(expire_at >(?1 + expire_in)OR expire_at IS NULL)AND ${generatedwhere.sql}',
      variables: [
        Variable<double>(currentTime),
        ...generatedwhere.introducedVariables,
      ],
      updates: {expiredMessages},
      updateKind: UpdateKind.update,
    );
  }

  Selectable<ExpiredMessage> getExpiredMessageById(String messageId) {
    return customSelect(
      'SELECT * FROM expired_messages WHERE message_id = ?1',
      variables: [Variable<String>(messageId)],
      readsFrom: {expiredMessages},
    ).asyncMap(expiredMessages.mapFromRow);
  }

  Selectable<ExpiredMessage> getAllExpiredMessages(int limit, int offset) {
    return customSelect(
      'SELECT * FROM expired_messages ORDER BY "rowid" ASC LIMIT ?1 OFFSET ?2',
      variables: [Variable<int>(limit), Variable<int>(offset)],
      readsFrom: {expiredMessages},
    ).asyncMap(expiredMessages.mapFromRow);
  }

  Selectable<int> countExpiredMessages() {
    return customSelect(
      'SELECT COUNT(1) AS _c0 FROM expired_messages',
      variables: [],
      readsFrom: {expiredMessages},
    ).map((QueryRow row) => row.read<int>('_c0'));
  }

  ExpiredMessageDaoManager get managers => ExpiredMessageDaoManager(this);
}

class ExpiredMessageDaoManager {
  final _$ExpiredMessageDaoMixin _db;
  ExpiredMessageDaoManager(this._db);
  $ExpiredMessagesTableManager get expiredMessages =>
      $ExpiredMessagesTableManager(_db.attachedDatabase, _db.expiredMessages);
  $AddressesTableManager get addresses =>
      $AddressesTableManager(_db.attachedDatabase, _db.addresses);
  $AppsTableManager get apps =>
      $AppsTableManager(_db.attachedDatabase, _db.apps);
  $AssetsTableManager get assets =>
      $AssetsTableManager(_db.attachedDatabase, _db.assets);
  $CircleConversationsTableManager get circleConversations =>
      $CircleConversationsTableManager(
        _db.attachedDatabase,
        _db.circleConversations,
      );
  $CirclesTableManager get circles =>
      $CirclesTableManager(_db.attachedDatabase, _db.circles);
  $ConversationsTableManager get conversations =>
      $ConversationsTableManager(_db.attachedDatabase, _db.conversations);
  $FloodMessagesTableManager get floodMessages =>
      $FloodMessagesTableManager(_db.attachedDatabase, _db.floodMessages);
  $HyperlinksTableManager get hyperlinks =>
      $HyperlinksTableManager(_db.attachedDatabase, _db.hyperlinks);
  $JobsTableManager get jobs =>
      $JobsTableManager(_db.attachedDatabase, _db.jobs);
  $MessageMentionsTableManager get messageMentions =>
      $MessageMentionsTableManager(_db.attachedDatabase, _db.messageMentions);
  $MessagesTableManager get messages =>
      $MessagesTableManager(_db.attachedDatabase, _db.messages);
  $MessagesHistoryTableManager get messagesHistory =>
      $MessagesHistoryTableManager(_db.attachedDatabase, _db.messagesHistory);
  $OffsetsTableManager get offsets =>
      $OffsetsTableManager(_db.attachedDatabase, _db.offsets);
  $ParticipantSessionTableManager get participantSession =>
      $ParticipantSessionTableManager(
        _db.attachedDatabase,
        _db.participantSession,
      );
  $ParticipantsTableManager get participants =>
      $ParticipantsTableManager(_db.attachedDatabase, _db.participants);
  $ResendSessionMessagesTableManager get resendSessionMessages =>
      $ResendSessionMessagesTableManager(
        _db.attachedDatabase,
        _db.resendSessionMessages,
      );
  $SentSessionSenderKeysTableManager get sentSessionSenderKeys =>
      $SentSessionSenderKeysTableManager(
        _db.attachedDatabase,
        _db.sentSessionSenderKeys,
      );
  $SnapshotsTableManager get snapshots =>
      $SnapshotsTableManager(_db.attachedDatabase, _db.snapshots);
  $StickerAlbumsTableManager get stickerAlbums =>
      $StickerAlbumsTableManager(_db.attachedDatabase, _db.stickerAlbums);
  $StickerRelationshipsTableManager get stickerRelationships =>
      $StickerRelationshipsTableManager(
        _db.attachedDatabase,
        _db.stickerRelationships,
      );
  $StickersTableManager get stickers =>
      $StickersTableManager(_db.attachedDatabase, _db.stickers);
  $UsersTableManager get users =>
      $UsersTableManager(_db.attachedDatabase, _db.users);
  $TranscriptMessagesTableManager get transcriptMessages =>
      $TranscriptMessagesTableManager(
        _db.attachedDatabase,
        _db.transcriptMessages,
      );
  $PinMessagesTableManager get pinMessages =>
      $PinMessagesTableManager(_db.attachedDatabase, _db.pinMessages);
  $FiatsTableManager get fiats =>
      $FiatsTableManager(_db.attachedDatabase, _db.fiats);
  $FavoriteAppsTableManager get favoriteApps =>
      $FavoriteAppsTableManager(_db.attachedDatabase, _db.favoriteApps);
  $ChainsTableManager get chains =>
      $ChainsTableManager(_db.attachedDatabase, _db.chains);
  $PropertiesTableManager get properties =>
      $PropertiesTableManager(_db.attachedDatabase, _db.properties);
  $SafeSnapshotsTableManager get safeSnapshots =>
      $SafeSnapshotsTableManager(_db.attachedDatabase, _db.safeSnapshots);
  $TokensTableManager get tokens =>
      $TokensTableManager(_db.attachedDatabase, _db.tokens);
  $InscriptionCollectionsTableManager get inscriptionCollections =>
      $InscriptionCollectionsTableManager(
        _db.attachedDatabase,
        _db.inscriptionCollections,
      );
  $InscriptionItemsTableManager get inscriptionItems =>
      $InscriptionItemsTableManager(_db.attachedDatabase, _db.inscriptionItems);
}

typedef MarkExpiredMessageRead$where =
    Expression<bool> Function(ExpiredMessages expired_messages);
