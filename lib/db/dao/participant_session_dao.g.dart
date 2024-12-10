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
      String conversationId, String userId) {
    return customSelect(
        'SELECT conversation_id, user_id, session_id, public_key FROM participant_session WHERE conversation_id = ?1 AND user_id != ?2 LIMIT 1',
        variables: [
          Variable<String>(conversationId),
          Variable<String>(userId)
        ],
        readsFrom: {
          participantSession,
        }).map((QueryRow row) => ParticipantSessionKey(
          conversationId: row.read<String>('conversation_id'),
          userId: row.read<String>('user_id'),
          sessionId: row.read<String>('session_id'),
          publicKey: row.readNullable<String>('public_key'),
        ));
  }

  Selectable<ParticipantSessionKey> otherParticipantSessionKey(
      String conversationId, String userId, String sessionId) {
    return customSelect(
        'SELECT conversation_id, user_id, session_id, public_key FROM participant_session WHERE conversation_id = ?1 AND user_id == ?2 AND session_id != ?3 ORDER BY created_at DESC LIMIT 1',
        variables: [
          Variable<String>(conversationId),
          Variable<String>(userId),
          Variable<String>(sessionId)
        ],
        readsFrom: {
          participantSession,
        }).map((QueryRow row) => ParticipantSessionKey(
          conversationId: row.read<String>('conversation_id'),
          userId: row.read<String>('user_id'),
          sessionId: row.read<String>('session_id'),
          publicKey: row.readNullable<String>('public_key'),
        ));
  }

  Selectable<ParticipantSessionData> notSendSessionParticipants(
      String conversationId, String sessionId) {
    return customSelect(
        'SELECT p.* FROM participant_session AS p LEFT JOIN users AS u ON p.user_id = u.user_id WHERE p.conversation_id = ?1 AND p.session_id != ?2 AND u.app_id IS NULL AND p.sent_to_server IS NULL',
        variables: [
          Variable<String>(conversationId),
          Variable<String>(sessionId)
        ],
        readsFrom: {
          participantSession,
          users,
        }).asyncMap(participantSession.mapFromRow);
  }
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
