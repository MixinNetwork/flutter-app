// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dao.dart';

// ignore_for_file: type=lint
mixin _$UserDaoMixin on DatabaseAccessor<MixinDatabase> {
  Users get users => attachedDatabase.users;
  Conversations get conversations => attachedDatabase.conversations;
  Messages get messages => attachedDatabase.messages;
  Participants get participants => attachedDatabase.participants;
  CircleConversations get circleConversations =>
      attachedDatabase.circleConversations;
  Addresses get addresses => attachedDatabase.addresses;
  Apps get apps => attachedDatabase.apps;
  Assets get assets => attachedDatabase.assets;
  Circles get circles => attachedDatabase.circles;
  FloodMessages get floodMessages => attachedDatabase.floodMessages;
  Hyperlinks get hyperlinks => attachedDatabase.hyperlinks;
  Jobs get jobs => attachedDatabase.jobs;
  MessageMentions get messageMentions => attachedDatabase.messageMentions;
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
  InscriptionCollections get inscriptionCollections =>
      attachedDatabase.inscriptionCollections;
  InscriptionItems get inscriptionItems => attachedDatabase.inscriptionItems;
  Selectable<User> _fuzzySearchBotGroupUser(
    String conversationId,
    DateTime createdAt,
    String id,
    String username,
    String identityNumber,
  ) {
    return customSelect(
      'SELECT u.* FROM users AS u WHERE(u.user_id IN (SELECT m.user_id FROM messages AS m WHERE conversation_id = ?1 AND m.created_at > ?2) OR u.user_id IN (SELECT f.user_id FROM users AS f WHERE relationship = \'FRIEND\'))AND u.user_id != ?3 AND u.identity_number != 0 AND(u.full_name LIKE \'%\' || ?4 || \'%\' ESCAPE \'\\\' OR u.identity_number LIKE \'%\' || ?5 || \'%\' ESCAPE \'\\\')ORDER BY CASE u.relationship WHEN \'FRIEND\' THEN 1 ELSE 2 END, u.relationship OR u.full_name = ?4 COLLATE NOCASE OR u.identity_number = ?5 COLLATE NOCASE DESC',
      variables: [
        Variable<String>(conversationId),
        Variable<int>(Messages.$convertercreatedAt.toSql(createdAt)),
        Variable<String>(id),
        Variable<String>(username),
        Variable<String>(identityNumber),
      ],
      readsFrom: {users, messages},
    ).asyncMap(users.mapFromRow);
  }

  Selectable<User> fuzzySearchGroupUser(
    String currentUserId,
    String conversationId,
    String keyword,
  ) {
    return customSelect(
      'SELECT u.* FROM participants AS p,users AS u WHERE u.user_id != ?1 AND p.conversation_id = ?2 AND p.user_id = u.user_id AND(u.full_name LIKE \'%\' || ?3 || \'%\' ESCAPE \'\\\' OR u.identity_number LIKE \'%\' || ?3 || \'%\' ESCAPE \'\\\')ORDER BY u.full_name = ?3 COLLATE NOCASE OR u.identity_number = ?3 COLLATE NOCASE DESC',
      variables: [
        Variable<String>(currentUserId),
        Variable<String>(conversationId),
        Variable<String>(keyword),
      ],
      readsFrom: {participants, users},
    ).asyncMap(users.mapFromRow);
  }

  Selectable<User> groupParticipants(String conversationId) {
    return customSelect(
      'SELECT u.* FROM participants AS p,users AS u WHERE p.conversation_id = ?1 AND p.user_id = u.user_id',
      variables: [Variable<String>(conversationId)],
      readsFrom: {participants, users},
    ).asyncMap(users.mapFromRow);
  }

  Selectable<User> notInFriends(List<String> filterIds) {
    var $arrayStartIndex = 1;
    final expandedfilterIds = $expandVar($arrayStartIndex, filterIds.length);
    $arrayStartIndex += filterIds.length;
    return customSelect(
      'SELECT * FROM users WHERE relationship = \'FRIEND\' AND user_id NOT IN ($expandedfilterIds) ORDER BY full_name, user_id ASC',
      variables: [for (var $ in filterIds) Variable<String>($)],
      readsFrom: {users},
    ).asyncMap(users.mapFromRow);
  }

  Selectable<User> usersByIn(List<String> userIds) {
    var $arrayStartIndex = 1;
    final expandeduserIds = $expandVar($arrayStartIndex, userIds.length);
    $arrayStartIndex += userIds.length;
    return customSelect(
      'SELECT * FROM users WHERE user_id IN ($expandeduserIds)',
      variables: [for (var $ in userIds) Variable<String>($)],
      readsFrom: {users},
    ).asyncMap(users.mapFromRow);
  }

  Selectable<String> userIdsByIn(List<String> userIds) {
    var $arrayStartIndex = 1;
    final expandeduserIds = $expandVar($arrayStartIndex, userIds.length);
    $arrayStartIndex += userIds.length;
    return customSelect(
      'SELECT user_id FROM users WHERE user_id IN ($expandeduserIds)',
      variables: [for (var $ in userIds) Variable<String>($)],
      readsFrom: {users},
    ).map((QueryRow row) => row.read<String>('user_id'));
  }

  Selectable<User> _fuzzySearchUser(
    FuzzySearchUser$firstFilter firstFilter,
    String id,
    String username,
    String identityNumber,
    FuzzySearchUser$lastFilter lastFilter,
  ) {
    var $arrayStartIndex = 4;
    final generatedfirstFilter = $write(
      firstFilter(this.users, this.conversations),
      hasMultipleTables: true,
      startIndex: $arrayStartIndex,
    );
    $arrayStartIndex += generatedfirstFilter.amountOfVariables;
    final generatedlastFilter = $write(
      lastFilter(this.users, this.conversations),
      hasMultipleTables: true,
      startIndex: $arrayStartIndex,
    );
    $arrayStartIndex += generatedlastFilter.amountOfVariables;
    return customSelect(
      'SELECT users.* FROM users LEFT JOIN conversations ON conversations.owner_id = user_id WHERE ${generatedfirstFilter.sql} AND user_id != ?1 AND relationship = \'FRIEND\' AND(full_name LIKE \'%\' || ?2 || \'%\' ESCAPE \'\\\' OR identity_number LIKE \'%\' || ?3 || \'%\' ESCAPE \'\\\')AND ${generatedlastFilter.sql} GROUP BY user_id ORDER BY full_name = ?2 COLLATE nocase OR identity_number = ?3 COLLATE nocase DESC',
      variables: [
        Variable<String>(id),
        Variable<String>(username),
        Variable<String>(identityNumber),
        ...generatedfirstFilter.introducedVariables,
        ...generatedlastFilter.introducedVariables,
      ],
      readsFrom: {
        users,
        conversations,
        ...generatedfirstFilter.watchedTables,
        ...generatedlastFilter.watchedTables,
      },
    ).asyncMap(users.mapFromRow);
  }

  Selectable<User> _fuzzySearchUserInCircle(
    FuzzySearchUserInCircle$filter filter,
    String id,
    String username,
    String identityNumber,
    String? circleId,
  ) {
    var $arrayStartIndex = 5;
    final generatedfilter = $write(
      filter(
        this.users,
        this.conversations,
        alias(this.circleConversations, 'circleConversation'),
      ),
      hasMultipleTables: true,
      startIndex: $arrayStartIndex,
    );
    $arrayStartIndex += generatedfilter.amountOfVariables;
    return customSelect(
      'SELECT users.* FROM users LEFT JOIN conversations ON conversations.owner_id = users.user_id LEFT JOIN circle_conversations AS circleConversation ON circleConversation.user_id = users.user_id WHERE ${generatedfilter.sql} AND users.user_id != ?1 AND relationship = \'FRIEND\' AND(full_name LIKE \'%\' || ?2 || \'%\' ESCAPE \'\\\' OR identity_number LIKE \'%\' || ?3 || \'%\' ESCAPE \'\\\')AND circleConversation.circle_id = ?4 GROUP BY users.user_id ORDER BY full_name = ?2 COLLATE nocase OR identity_number = ?3 COLLATE nocase DESC',
      variables: [
        Variable<String>(id),
        Variable<String>(username),
        Variable<String>(identityNumber),
        Variable<String>(circleId),
        ...generatedfilter.introducedVariables,
      ],
      readsFrom: {
        users,
        conversations,
        circleConversations,
        ...generatedfilter.watchedTables,
      },
    ).asyncMap(users.mapFromRow);
  }

  Selectable<String?> biographyByIdentityNumber(String userId) {
    return customSelect(
      'SELECT biography FROM users WHERE user_id = ?1',
      variables: [Variable<String>(userId)],
      readsFrom: {users},
    ).map((QueryRow row) => row.readNullable<String>('biography'));
  }

  Selectable<MentionUser> userByIdentityNumbers(List<String> numbers) {
    var $arrayStartIndex = 1;
    final expandednumbers = $expandVar($arrayStartIndex, numbers.length);
    $arrayStartIndex += numbers.length;
    return customSelect(
      'SELECT user_id, identity_number, full_name FROM users WHERE identity_number IN ($expandednumbers)',
      variables: [for (var $ in numbers) Variable<String>($)],
      readsFrom: {users},
    ).map(
      (QueryRow row) => MentionUser(
        userId: row.read<String>('user_id'),
        identityNumber: row.read<String>('identity_number'),
        fullName: row.readNullable<String>('full_name'),
      ),
    );
  }

  Selectable<int> countUsers() {
    return customSelect(
      'SELECT COUNT(*) AS _c0 FROM users',
      variables: [],
      readsFrom: {users},
    ).map((QueryRow row) => row.read<int>('_c0'));
  }
}
typedef FuzzySearchUser$firstFilter =
    Expression<bool> Function(Users users, Conversations conversations);
typedef FuzzySearchUser$lastFilter =
    Expression<bool> Function(Users users, Conversations conversations);
typedef FuzzySearchUserInCircle$filter =
    Expression<bool> Function(
      Users users,
      Conversations conversations,
      CircleConversations circleConversation,
    );

class MentionUser {
  final String userId;
  final String identityNumber;
  final String? fullName;
  MentionUser({
    required this.userId,
    required this.identityNumber,
    this.fullName,
  });
  @override
  int get hashCode => Object.hash(userId, identityNumber, fullName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MentionUser &&
          other.userId == this.userId &&
          other.identityNumber == this.identityNumber &&
          other.fullName == this.fullName);
  @override
  String toString() {
    return (StringBuffer('MentionUser(')
          ..write('userId: $userId, ')
          ..write('identityNumber: $identityNumber, ')
          ..write('fullName: $fullName')
          ..write(')'))
        .toString();
  }
}
