// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pin_message_dao.dart';

// ignore_for_file: type=lint
mixin _$PinMessageDaoMixin on DatabaseAccessor<MixinDatabase> {
  Conversations get conversations => attachedDatabase.conversations;
  Messages get messages => attachedDatabase.messages;
  PinMessages get pinMessages => attachedDatabase.pinMessages;
  Users get users => attachedDatabase.users;
  Addresses get addresses => attachedDatabase.addresses;
  Apps get apps => attachedDatabase.apps;
  Assets get assets => attachedDatabase.assets;
  CircleConversations get circleConversations =>
      attachedDatabase.circleConversations;
  Circles get circles => attachedDatabase.circles;
  FloodMessages get floodMessages => attachedDatabase.floodMessages;
  Hyperlinks get hyperlinks => attachedDatabase.hyperlinks;
  Jobs get jobs => attachedDatabase.jobs;
  MessageMentions get messageMentions => attachedDatabase.messageMentions;
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
  TranscriptMessages get transcriptMessages =>
      attachedDatabase.transcriptMessages;
  Fiats get fiats => attachedDatabase.fiats;
  FavoriteApps get favoriteApps => attachedDatabase.favoriteApps;
  ExpiredMessages get expiredMessages => attachedDatabase.expiredMessages;
  Chains get chains => attachedDatabase.chains;
  Properties get properties => attachedDatabase.properties;
  AiChatMessages get aiChatMessages => attachedDatabase.aiChatMessages;
  SafeSnapshots get safeSnapshots => attachedDatabase.safeSnapshots;
  Tokens get tokens => attachedDatabase.tokens;
  InscriptionCollections get inscriptionCollections =>
      attachedDatabase.inscriptionCollections;
  InscriptionItems get inscriptionItems => attachedDatabase.inscriptionItems;
  Selectable<PinMessageItemResult> pinMessageItem(
    String messageId,
    String conversationId,
  ) {
    return customSelect(
      'SELECT message.content AS content, sender.full_name AS userFullName FROM messages AS message INNER JOIN pin_messages AS pinMessage ON ?1 = pinMessage.message_id INNER JOIN users AS sender ON message.user_id = sender.user_id WHERE message.conversation_id = ?2 AND message.category = \'MESSAGE_PIN\' AND message.quote_message_id = ?1 ORDER BY message.created_at DESC LIMIT 1',
      variables: [
        Variable<String>(messageId),
        Variable<String>(conversationId),
      ],
      readsFrom: {messages, users, pinMessages},
    ).map(
      (QueryRow row) => PinMessageItemResult(
        content: row.readNullable<String>('content'),
        userFullName: row.readNullable<String>('userFullName'),
      ),
    );
  }

  Selectable<String> pinMessageIds(String conversationId) {
    return customSelect(
      'SELECT pinMessage.message_id FROM pin_messages AS pinMessage INNER JOIN messages AS message ON message.message_id = pinMessage.message_id WHERE pinMessage.conversation_id = ?1 ORDER BY message.created_at DESC',
      variables: [Variable<String>(conversationId)],
      readsFrom: {pinMessages, messages},
    ).map((QueryRow row) => row.read<String>('message_id'));
  }

  Selectable<int> countPinMessages() {
    return customSelect(
      'SELECT COUNT(1) AS _c0 FROM pin_messages',
      variables: [],
      readsFrom: {pinMessages},
    ).map((QueryRow row) => row.read<int>('_c0'));
  }

  PinMessageDaoManager get managers => PinMessageDaoManager(this);
}

class PinMessageDaoManager {
  final _$PinMessageDaoMixin _db;
  PinMessageDaoManager(this._db);
  $ConversationsTableManager get conversations =>
      $ConversationsTableManager(_db.attachedDatabase, _db.conversations);
  $MessagesTableManager get messages =>
      $MessagesTableManager(_db.attachedDatabase, _db.messages);
  $PinMessagesTableManager get pinMessages =>
      $PinMessagesTableManager(_db.attachedDatabase, _db.pinMessages);
  $UsersTableManager get users =>
      $UsersTableManager(_db.attachedDatabase, _db.users);
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
  $FloodMessagesTableManager get floodMessages =>
      $FloodMessagesTableManager(_db.attachedDatabase, _db.floodMessages);
  $HyperlinksTableManager get hyperlinks =>
      $HyperlinksTableManager(_db.attachedDatabase, _db.hyperlinks);
  $JobsTableManager get jobs =>
      $JobsTableManager(_db.attachedDatabase, _db.jobs);
  $MessageMentionsTableManager get messageMentions =>
      $MessageMentionsTableManager(_db.attachedDatabase, _db.messageMentions);
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
  $TranscriptMessagesTableManager get transcriptMessages =>
      $TranscriptMessagesTableManager(
        _db.attachedDatabase,
        _db.transcriptMessages,
      );
  $FiatsTableManager get fiats =>
      $FiatsTableManager(_db.attachedDatabase, _db.fiats);
  $FavoriteAppsTableManager get favoriteApps =>
      $FavoriteAppsTableManager(_db.attachedDatabase, _db.favoriteApps);
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

class PinMessageItemResult {
  final String? content;
  final String? userFullName;
  PinMessageItemResult({this.content, this.userFullName});
  @override
  int get hashCode => Object.hash(content, userFullName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PinMessageItemResult &&
          other.content == this.content &&
          other.userFullName == this.userFullName);
  @override
  String toString() {
    return (StringBuffer('PinMessageItemResult(')
          ..write('content: $content, ')
          ..write('userFullName: $userFullName')
          ..write(')'))
        .toString();
  }
}
