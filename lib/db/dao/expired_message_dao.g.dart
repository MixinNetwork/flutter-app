// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expired_message_dao.dart';

// **************************************************************************
// DaoGenerator
// **************************************************************************

mixin _$ExpiredMessageDaoMixin on DatabaseAccessor<MixinDatabase> {
  Conversations get conversations => attachedDatabase.conversations;
  FloodMessages get floodMessages => attachedDatabase.floodMessages;
  Jobs get jobs => attachedDatabase.jobs;
  MessageMentions get messageMentions => attachedDatabase.messageMentions;
  Participants get participants => attachedDatabase.participants;
  StickerAlbums get stickerAlbums => attachedDatabase.stickerAlbums;
  PinMessages get pinMessages => attachedDatabase.pinMessages;
  Users get users => attachedDatabase.users;
  Messages get messages => attachedDatabase.messages;
  Addresses get addresses => attachedDatabase.addresses;
  Apps get apps => attachedDatabase.apps;
  Assets get assets => attachedDatabase.assets;
  CircleConversations get circleConversations =>
      attachedDatabase.circleConversations;
  Circles get circles => attachedDatabase.circles;
  Hyperlinks get hyperlinks => attachedDatabase.hyperlinks;
  MessagesHistory get messagesHistory => attachedDatabase.messagesHistory;
  Offsets get offsets => attachedDatabase.offsets;
  ParticipantSession get participantSession =>
      attachedDatabase.participantSession;
  ResendSessionMessages get resendSessionMessages =>
      attachedDatabase.resendSessionMessages;
  SentSessionSenderKeys get sentSessionSenderKeys =>
      attachedDatabase.sentSessionSenderKeys;
  Snapshots get snapshots => attachedDatabase.snapshots;
  StickerRelationships get stickerRelationships =>
      attachedDatabase.stickerRelationships;
  Stickers get stickers => attachedDatabase.stickers;
  TranscriptMessages get transcriptMessages =>
      attachedDatabase.transcriptMessages;
  Fiats get fiats => attachedDatabase.fiats;
  FavoriteApps get favoriteApps => attachedDatabase.favoriteApps;
  ExpiredMessages get expiredMessages => attachedDatabase.expiredMessages;
  Chains get chains => attachedDatabase.chains;
  Selectable<ExpiredMessage> getExpiredMessages(int? currentTime, int limit) {
    return customSelect(
        'SELECT * FROM expired_messages WHERE expire_at <= ?1 ORDER BY expire_at ASC LIMIT ?2',
        variables: [
          Variable<int>(currentTime),
          Variable<int>(limit)
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
}
typedef MarkExpiredMessageRead$where = Expression<bool> Function(
    ExpiredMessages expired_messages);
