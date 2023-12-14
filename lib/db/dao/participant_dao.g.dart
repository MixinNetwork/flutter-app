// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_dao.dart';

// ignore_for_file: type=lint
mixin _$ParticipantDaoMixin on DatabaseAccessor<MixinDatabase> {
  Conversations get conversations => attachedDatabase.conversations;
  Participants get participants => attachedDatabase.participants;
  Users get users => attachedDatabase.users;
  AddressesTable get addresses => attachedDatabase.addresses;
  Apps get apps => attachedDatabase.apps;
  Assets get assets => attachedDatabase.assets;
  CircleConversations get circleConversations =>
      attachedDatabase.circleConversations;
  Circles get circles => attachedDatabase.circles;
  FloodMessages get floodMessages => attachedDatabase.floodMessages;
  Hyperlinks get hyperlinks => attachedDatabase.hyperlinks;
  Jobs get jobs => attachedDatabase.jobs;
  MessageMentions get messageMentions => attachedDatabase.messageMentions;
  Messages get messages => attachedDatabase.messages;
  MessagesHistory get messagesHistory => attachedDatabase.messagesHistory;
  Offsets get offsets => attachedDatabase.offsets;
  ParticipantSession get participantSession =>
      attachedDatabase.participantSession;
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
  Selectable<User> participantsAvatar(String conversationId) {
    return customSelect(
        'SELECT user.* FROM participants AS participant INNER JOIN users AS user ON participant.user_id = user.user_id WHERE participant.conversation_id = ?1 ORDER BY participant.created_at ASC LIMIT 4',
        variables: [
          Variable<String>(conversationId)
        ],
        readsFrom: {
          participants,
          users,
        }).asyncMap(users.mapFromRow);
  }

  Selectable<ParticipantUser> groupParticipantsByConversationId(
      String conversationId) {
    return customSelect(
        'SELECT p.conversation_id AS conversationId, p.role AS role, p.created_at AS createdAt, u.user_id AS userId, u.identity_number AS identityNumber, u.relationship AS relationship, u.biography AS biography, u.full_name AS fullName, u.avatar_url AS avatarUrl, u.phone AS phone, u.is_verified AS isVerified, u.created_at AS userCreatedAt, u.mute_until AS muteUntil, u.has_pin AS hasPin, u.app_id AS appId, u.is_scam AS isScam FROM participants AS p,users AS u WHERE p.conversation_id = ?1 AND p.user_id = u.user_id ORDER BY p.created_at DESC',
        variables: [
          Variable<String>(conversationId)
        ],
        readsFrom: {
          participants,
          users,
        }).map((QueryRow row) => ParticipantUser(
          conversationId: row.read<String>('conversationId'),
          role: Participants.$converterrole
              .fromSql(row.readNullable<String>('role')),
          createdAt: Participants.$convertercreatedAt
              .fromSql(row.read<int>('createdAt')),
          userId: row.read<String>('userId'),
          identityNumber: row.read<String>('identityNumber'),
          relationship: Users.$converterrelationship
              .fromSql(row.readNullable<String>('relationship')),
          biography: row.readNullable<String>('biography'),
          fullName: row.readNullable<String>('fullName'),
          avatarUrl: row.readNullable<String>('avatarUrl'),
          phone: row.readNullable<String>('phone'),
          isVerified: row.readNullable<bool>('isVerified'),
          userCreatedAt: NullAwareTypeConverter.wrapFromSql(
              Users.$convertercreatedAt,
              row.readNullable<int>('userCreatedAt')),
          muteUntil: NullAwareTypeConverter.wrapFromSql(
              Users.$convertermuteUntil, row.readNullable<int>('muteUntil')),
          hasPin: row.readNullable<int>('hasPin'),
          appId: row.readNullable<String>('appId'),
          isScam: row.readNullable<int>('isScam'),
        ));
  }

  Selectable<String> userIdByIdentityNumber(
      String conversationId, String identityNumber) {
    return customSelect(
        'SELECT u.user_id FROM users AS u INNER JOIN participants AS p ON p.user_id = u.user_id WHERE p.conversation_id = ?1 AND u.identity_number = ?2',
        variables: [
          Variable<String>(conversationId),
          Variable<String>(identityNumber)
        ],
        readsFrom: {
          users,
          participants,
        }).map((QueryRow row) => row.read<String>('user_id'));
  }

  Selectable<int> countParticipants() {
    return customSelect('SELECT COUNT(1) AS _c0 FROM participants',
        variables: [],
        readsFrom: {
          participants,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }

  Selectable<int> conversationParticipantsCount(String conversationId) {
    return customSelect(
        'SELECT COUNT(1) AS _c0 FROM participants WHERE conversation_id = ?1',
        variables: [
          Variable<String>(conversationId)
        ],
        readsFrom: {
          participants,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }

  Selectable<String> _joinedConversationId(String userId) {
    return customSelect(
        'SELECT p.conversation_id FROM participants AS p,conversations AS c WHERE p.user_id = ?1 AND p.conversation_id = c.conversation_id AND c.status = 2 LIMIT 1',
        variables: [
          Variable<String>(userId)
        ],
        readsFrom: {
          participants,
          conversations,
        }).map((QueryRow row) => row.read<String>('conversation_id'));
  }
}

class ParticipantUser {
  final String conversationId;
  final ParticipantRole? role;
  final DateTime createdAt;
  final String userId;
  final String identityNumber;
  final UserRelationship? relationship;
  final String? biography;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final bool? isVerified;
  final DateTime? userCreatedAt;
  final DateTime? muteUntil;
  final int? hasPin;
  final String? appId;
  final int? isScam;
  ParticipantUser({
    required this.conversationId,
    this.role,
    required this.createdAt,
    required this.userId,
    required this.identityNumber,
    this.relationship,
    this.biography,
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.isVerified,
    this.userCreatedAt,
    this.muteUntil,
    this.hasPin,
    this.appId,
    this.isScam,
  });
  @override
  int get hashCode => Object.hash(
      conversationId,
      role,
      createdAt,
      userId,
      identityNumber,
      relationship,
      biography,
      fullName,
      avatarUrl,
      phone,
      isVerified,
      userCreatedAt,
      muteUntil,
      hasPin,
      appId,
      isScam);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParticipantUser &&
          other.conversationId == this.conversationId &&
          other.role == this.role &&
          other.createdAt == this.createdAt &&
          other.userId == this.userId &&
          other.identityNumber == this.identityNumber &&
          other.relationship == this.relationship &&
          other.biography == this.biography &&
          other.fullName == this.fullName &&
          other.avatarUrl == this.avatarUrl &&
          other.phone == this.phone &&
          other.isVerified == this.isVerified &&
          other.userCreatedAt == this.userCreatedAt &&
          other.muteUntil == this.muteUntil &&
          other.hasPin == this.hasPin &&
          other.appId == this.appId &&
          other.isScam == this.isScam);
  @override
  String toString() {
    return (StringBuffer('ParticipantUser(')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('createdAt: $createdAt, ')
          ..write('userId: $userId, ')
          ..write('identityNumber: $identityNumber, ')
          ..write('relationship: $relationship, ')
          ..write('biography: $biography, ')
          ..write('fullName: $fullName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('phone: $phone, ')
          ..write('isVerified: $isVerified, ')
          ..write('userCreatedAt: $userCreatedAt, ')
          ..write('muteUntil: $muteUntil, ')
          ..write('hasPin: $hasPin, ')
          ..write('appId: $appId, ')
          ..write('isScam: $isScam')
          ..write(')'))
        .toString();
  }
}
