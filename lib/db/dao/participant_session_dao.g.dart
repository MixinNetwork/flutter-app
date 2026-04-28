// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_session_dao.dart';

// ignore_for_file: type=lint
mixin _$ParticipantSessionDaoMixin on DatabaseAccessor<MixinDatabase> {
  ParticipantSession get participantSession =>
      attachedDatabase.participantSession;
  Users get users => attachedDatabase.users;
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
  PinMessages get pinMessages => attachedDatabase.pinMessages;
  Fiats get fiats => attachedDatabase.fiats;
  FavoriteApps get favoriteApps => attachedDatabase.favoriteApps;
  ExpiredMessages get expiredMessages => attachedDatabase.expiredMessages;
  Chains get chains => attachedDatabase.chains;
  Properties get properties => attachedDatabase.properties;
  SafeSnapshots get safeSnapshots => attachedDatabase.safeSnapshots;
  Tokens get tokens => attachedDatabase.tokens;
  InscriptionCollections get inscriptionCollections =>
      attachedDatabase.inscriptionCollections;
  InscriptionItems get inscriptionItems => attachedDatabase.inscriptionItems;
  Selectable<ParticipantSessionKey> participantSessionKeyWithoutSelf(
    String conversationId,
    String userId,
  ) {
    return customSelect(
      'SELECT conversation_id, user_id, session_id, public_key FROM participant_session WHERE conversation_id = ?1 AND user_id != ?2 LIMIT 1',
      variables: [Variable<String>(conversationId), Variable<String>(userId)],
      readsFrom: {participantSession},
    ).map(
      (QueryRow row) => ParticipantSessionKey(
        conversationId: row.read<String>('conversation_id'),
        userId: row.read<String>('user_id'),
        sessionId: row.read<String>('session_id'),
        publicKey: row.readNullable<String>('public_key'),
      ),
    );
  }

  Selectable<ParticipantSessionKey> otherParticipantSessionKey(
    String conversationId,
    String userId,
    String sessionId,
  ) {
    return customSelect(
      'SELECT conversation_id, user_id, session_id, public_key FROM participant_session WHERE conversation_id = ?1 AND user_id == ?2 AND session_id != ?3 ORDER BY created_at DESC LIMIT 1',
      variables: [
        Variable<String>(conversationId),
        Variable<String>(userId),
        Variable<String>(sessionId),
      ],
      readsFrom: {participantSession},
    ).map(
      (QueryRow row) => ParticipantSessionKey(
        conversationId: row.read<String>('conversation_id'),
        userId: row.read<String>('user_id'),
        sessionId: row.read<String>('session_id'),
        publicKey: row.readNullable<String>('public_key'),
      ),
    );
  }

  Selectable<ParticipantSessionData> notSendSessionParticipants(
    String conversationId,
    String sessionId,
  ) {
    return customSelect(
      'SELECT p.* FROM participant_session AS p LEFT JOIN users AS u ON p.user_id = u.user_id WHERE p.conversation_id = ?1 AND p.session_id != ?2 AND u.app_id IS NULL AND p.sent_to_server IS NULL',
      variables: [
        Variable<String>(conversationId),
        Variable<String>(sessionId),
      ],
      readsFrom: {participantSession, users},
    ).asyncMap(participantSession.mapFromRow);
  }

  ParticipantSessionDaoManager get managers =>
      ParticipantSessionDaoManager(this);
}

class ParticipantSessionDaoManager {
  final _$ParticipantSessionDaoMixin _db;
  ParticipantSessionDaoManager(this._db);
  $ParticipantSessionTableManager get participantSession =>
      $ParticipantSessionTableManager(
        _db.attachedDatabase,
        _db.participantSession,
      );
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
  $PinMessagesTableManager get pinMessages =>
      $PinMessagesTableManager(_db.attachedDatabase, _db.pinMessages);
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

class ParticipantSessionKey {
  final String conversationId;
  final String userId;
  final String sessionId;
  final String? publicKey;
  ParticipantSessionKey({
    required this.conversationId,
    required this.userId,
    required this.sessionId,
    this.publicKey,
  });
  @override
  int get hashCode => Object.hash(conversationId, userId, sessionId, publicKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParticipantSessionKey &&
          other.conversationId == this.conversationId &&
          other.userId == this.userId &&
          other.sessionId == this.sessionId &&
          other.publicKey == this.publicKey);
  @override
  String toString() {
    return (StringBuffer('ParticipantSessionKey(')
          ..write('conversationId: $conversationId, ')
          ..write('userId: $userId, ')
          ..write('sessionId: $sessionId, ')
          ..write('publicKey: $publicKey')
          ..write(')'))
        .toString();
  }
}
