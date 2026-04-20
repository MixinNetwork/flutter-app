// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_app_dao.dart';

// ignore_for_file: type=lint
mixin _$FavoriteAppDaoMixin on DatabaseAccessor<MixinDatabase> {
  FavoriteApps get favoriteApps => attachedDatabase.favoriteApps;
  Apps get apps => attachedDatabase.apps;
  Addresses get addresses => attachedDatabase.addresses;
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
  ExpiredMessages get expiredMessages => attachedDatabase.expiredMessages;
  Chains get chains => attachedDatabase.chains;
  Properties get properties => attachedDatabase.properties;
  AiChatMessages get aiChatMessages => attachedDatabase.aiChatMessages;
  SafeSnapshots get safeSnapshots => attachedDatabase.safeSnapshots;
  Tokens get tokens => attachedDatabase.tokens;
  InscriptionCollections get inscriptionCollections =>
      attachedDatabase.inscriptionCollections;
  InscriptionItems get inscriptionItems => attachedDatabase.inscriptionItems;
  Future<int> _deleteFavoriteAppByUserId(String userId) {
    return customUpdate(
      'DELETE FROM favorite_apps WHERE user_id = ?1',
      variables: [Variable<String>(userId)],
      updates: {favoriteApps},
      updateKind: UpdateKind.delete,
    );
  }

  Selectable<App> getFavoriteAppsByUserId(String userId) {
    return customSelect(
      'SELECT a.* FROM favorite_apps AS fa INNER JOIN apps AS a ON fa.app_id = a.app_id WHERE fa.user_id = ?1',
      variables: [Variable<String>(userId)],
      readsFrom: {favoriteApps, apps},
    ).asyncMap(apps.mapFromRow);
  }

  FavoriteAppDaoManager get managers => FavoriteAppDaoManager(this);
}

class FavoriteAppDaoManager {
  final _$FavoriteAppDaoMixin _db;
  FavoriteAppDaoManager(this._db);
  $FavoriteAppsTableManager get favoriteApps =>
      $FavoriteAppsTableManager(_db.attachedDatabase, _db.favoriteApps);
  $AppsTableManager get apps =>
      $AppsTableManager(_db.attachedDatabase, _db.apps);
  $AddressesTableManager get addresses =>
      $AddressesTableManager(_db.attachedDatabase, _db.addresses);
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
  $ExpiredMessagesTableManager get expiredMessages =>
      $ExpiredMessagesTableManager(_db.attachedDatabase, _db.expiredMessages);
  $ChainsTableManager get chains =>
      $ChainsTableManager(_db.attachedDatabase, _db.chains);
  $PropertiesTableManager get properties =>
      $PropertiesTableManager(_db.attachedDatabase, _db.properties);
  $AiChatMessagesTableManager get aiChatMessages =>
      $AiChatMessagesTableManager(_db.attachedDatabase, _db.aiChatMessages);
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
