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
        variables: [
          Variable<int>(currentTime)
        ],
        readsFrom: {
          expiredMessages,
        }).asyncMap(expiredMessages.mapFromRow);
  }

  Selectable<ExpiredMessage> getFirstExpiredMessage() {
    return customSelect(
        'SELECT * FROM expired_messages WHERE expire_at IS NOT NULL ORDER BY expire_at ASC LIMIT 1',
        variables: [],
        readsFrom: {
          expiredMessages,
        }).asyncMap(expiredMessages.mapFromRow);
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
      double currentTime, MarkExpiredMessageRead$where where) {
    var $arrayStartIndex = 2;
    final generatedwhere =
        $write(where(this.expiredMessages), startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedwhere.amountOfVariables;
    return customUpdate(
      'UPDATE expired_messages SET expire_at = CAST((?1 + expire_in)AS INTEGER) WHERE(expire_at >(?1 + expire_in)OR expire_at IS NULL)AND ${generatedwhere.sql}',
      variables: [
        Variable<double>(currentTime),
        ...generatedwhere.introducedVariables
      ],
      updates: {expiredMessages},
      updateKind: UpdateKind.update,
    );
  }

  Selectable<ExpiredMessage> getExpiredMessageById(String messageId) {
    return customSelect('SELECT * FROM expired_messages WHERE message_id = ?1',
        variables: [
          Variable<String>(messageId)
        ],
        readsFrom: {
          expiredMessages,
        }).asyncMap(expiredMessages.mapFromRow);
  }

  Selectable<ExpiredMessage> getAllExpiredMessages(int limit, int offset) {
    return customSelect(
        'SELECT * FROM expired_messages ORDER BY "rowid" ASC LIMIT ?1 OFFSET ?2',
        variables: [
          Variable<int>(limit),
          Variable<int>(offset)
        ],
        readsFrom: {
          expiredMessages,
        }).asyncMap(expiredMessages.mapFromRow);
  }

  Selectable<int> countExpiredMessages() {
    return customSelect('SELECT COUNT(1) AS _c0 FROM expired_messages',
        variables: [],
        readsFrom: {
          expiredMessages,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }
}
typedef MarkExpiredMessageRead$where = Expression<bool> Function(
    ExpiredMessages expired_messages);
