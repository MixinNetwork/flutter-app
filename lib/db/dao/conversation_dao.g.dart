// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_dao.dart';

// ignore_for_file: type=lint
mixin _$ConversationDaoMixin on DatabaseAccessor<MixinDatabase> {
  Conversations get conversations => attachedDatabase.conversations;
  Users get users => attachedDatabase.users;
  CircleConversations get circleConversations =>
      attachedDatabase.circleConversations;
  Messages get messages => attachedDatabase.messages;
  Snapshots get snapshots => attachedDatabase.snapshots;
  ExpiredMessages get expiredMessages => attachedDatabase.expiredMessages;
  MessageMentions get messageMentions => attachedDatabase.messageMentions;
  Participants get participants => attachedDatabase.participants;
  Addresses get addresses => attachedDatabase.addresses;
  Apps get apps => attachedDatabase.apps;
  Assets get assets => attachedDatabase.assets;
  Circles get circles => attachedDatabase.circles;
  FloodMessages get floodMessages => attachedDatabase.floodMessages;
  Hyperlinks get hyperlinks => attachedDatabase.hyperlinks;
  Jobs get jobs => attachedDatabase.jobs;
  MessagesHistory get messagesHistory => attachedDatabase.messagesHistory;
  Offsets get offsets => attachedDatabase.offsets;
  ParticipantSession get participantSession =>
      attachedDatabase.participantSession;
  ResendSessionMessages get resendSessionMessages =>
      attachedDatabase.resendSessionMessages;
  SentSessionSenderKeys get sentSessionSenderKeys =>
      attachedDatabase.sentSessionSenderKeys;
  StickerAlbums get stickerAlbums => attachedDatabase.stickerAlbums;
  StickerRelationships get stickerRelationships =>
      attachedDatabase.stickerRelationships;
  Stickers get stickers => attachedDatabase.stickers;
  TranscriptMessages get transcriptMessages =>
      attachedDatabase.transcriptMessages;
  PinMessages get pinMessages => attachedDatabase.pinMessages;
  Fiats get fiats => attachedDatabase.fiats;
  FavoriteApps get favoriteApps => attachedDatabase.favoriteApps;
  Chains get chains => attachedDatabase.chains;
  Properties get properties => attachedDatabase.properties;
  SafeSnapshots get safeSnapshots => attachedDatabase.safeSnapshots;
  Tokens get tokens => attachedDatabase.tokens;
  Selectable<int> _baseConversationItemCount(
      BaseConversationItemCount$where where) {
    var $arrayStartIndex = 1;
    final generatedwhere = $write(
        where(
            alias(this.conversations, 'conversation'),
            alias(this.users, 'owner'),
            alias(this.circleConversations, 'circleConversation')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedwhere.amountOfVariables;
    return customSelect(
        'SELECT COUNT(DISTINCT conversation.conversation_id) AS _c0 FROM conversations AS conversation INNER JOIN users AS owner ON owner.user_id = conversation.owner_id LEFT JOIN circle_conversations AS circleConversation ON conversation.conversation_id = circleConversation.conversation_id WHERE ${generatedwhere.sql}',
        variables: [
          ...generatedwhere.introducedVariables
        ],
        readsFrom: {
          conversations,
          users,
          circleConversations,
          ...generatedwhere.watchedTables,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }

  Selectable<ConversationItem> _baseConversationItems(
      BaseConversationItems$where where,
      BaseConversationItems$order order,
      BaseConversationItems$limit limit) {
    var $arrayStartIndex = 1;
    final generatedwhere = $write(
        where(
            alias(this.conversations, 'conversation'),
            alias(this.users, 'owner'),
            alias(this.messages, 'lastMessage'),
            alias(this.users, 'lastMessageSender'),
            alias(this.snapshots, 'snapshot'),
            alias(this.users, 'participant'),
            alias(this.expiredMessages, 'em')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedwhere.amountOfVariables;
    final generatedorder = $write(
        order?.call(
                alias(this.conversations, 'conversation'),
                alias(this.users, 'owner'),
                alias(this.messages, 'lastMessage'),
                alias(this.users, 'lastMessageSender'),
                alias(this.snapshots, 'snapshot'),
                alias(this.users, 'participant'),
                alias(this.expiredMessages, 'em')) ??
            const OrderBy.nothing(),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedorder.amountOfVariables;
    final generatedlimit = $write(
        limit(
            alias(this.conversations, 'conversation'),
            alias(this.users, 'owner'),
            alias(this.messages, 'lastMessage'),
            alias(this.users, 'lastMessageSender'),
            alias(this.snapshots, 'snapshot'),
            alias(this.users, 'participant'),
            alias(this.expiredMessages, 'em')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedlimit.amountOfVariables;
    return customSelect(
        'SELECT conversation.conversation_id AS conversationId, conversation.icon_url AS groupIconUrl, conversation.category AS category, conversation.draft AS draft, conversation.name AS groupName, conversation.status AS status, conversation.last_read_message_id AS lastReadMessageId, conversation.unseen_message_count AS unseenMessageCount, conversation.owner_id AS ownerId, conversation.pin_time AS pinTime, conversation.mute_until AS muteUntil, conversation.expire_in AS expireIn, owner.avatar_url AS avatarUrl, owner.full_name AS name, owner.is_verified AS ownerVerified, owner.identity_number AS ownerIdentityNumber, owner.mute_until AS ownerMuteUntil, owner.app_id AS appId, lastMessage.content AS content, lastMessage.category AS contentType, conversation.created_at AS createdAt, lastMessage.created_at AS lastMessageCreatedAt, lastMessage.media_url AS mediaUrl, lastMessage.user_id AS senderId, lastMessage."action" AS actionName, lastMessage.status AS messageStatus, lastMessageSender.full_name AS senderFullName, snapshot.type AS SnapshotType, participant.full_name AS participantFullName, participant.user_id AS participantUserId, em.expire_in AS messageExpireIn, (SELECT COUNT(1) FROM message_mentions AS messageMention WHERE messageMention.conversation_id = conversation.conversation_id AND messageMention.has_read = 0) AS mentionCount, owner.relationship AS relationship FROM conversations AS conversation INNER JOIN users AS owner ON owner.user_id = conversation.owner_id LEFT JOIN messages AS lastMessage ON conversation.last_message_id = lastMessage.message_id LEFT JOIN users AS lastMessageSender ON lastMessageSender.user_id = lastMessage.user_id LEFT JOIN snapshots AS snapshot ON snapshot.snapshot_id = lastMessage.snapshot_id LEFT JOIN users AS participant ON participant.user_id = lastMessage.participant_id LEFT JOIN expired_messages AS em ON lastMessage.message_id = em.message_id WHERE ${generatedwhere.sql} ${generatedorder.sql} ${generatedlimit.sql}',
        variables: [
          ...generatedwhere.introducedVariables,
          ...generatedorder.introducedVariables,
          ...generatedlimit.introducedVariables
        ],
        readsFrom: {
          conversations,
          users,
          messages,
          snapshots,
          expiredMessages,
          messageMentions,
          ...generatedwhere.watchedTables,
          ...generatedorder.watchedTables,
          ...generatedlimit.watchedTables,
        }).map((QueryRow row) => ConversationItem(
          conversationId: row.read<String>('conversationId'),
          groupIconUrl: row.readNullable<String>('groupIconUrl'),
          category: Conversations.$convertercategory
              .fromSql(row.readNullable<String>('category')),
          draft: row.readNullable<String>('draft'),
          groupName: row.readNullable<String>('groupName'),
          status:
              Conversations.$converterstatus.fromSql(row.read<int>('status')),
          lastReadMessageId: row.readNullable<String>('lastReadMessageId'),
          unseenMessageCount: row.readNullable<int>('unseenMessageCount'),
          ownerId: row.readNullable<String>('ownerId'),
          pinTime: NullAwareTypeConverter.wrapFromSql(
              Conversations.$converterpinTime,
              row.readNullable<int>('pinTime')),
          muteUntil: NullAwareTypeConverter.wrapFromSql(
              Conversations.$convertermuteUntil,
              row.readNullable<int>('muteUntil')),
          expireIn: row.readNullable<int>('expireIn'),
          avatarUrl: row.readNullable<String>('avatarUrl'),
          name: row.readNullable<String>('name'),
          ownerVerified: row.readNullable<bool>('ownerVerified'),
          ownerIdentityNumber: row.read<String>('ownerIdentityNumber'),
          ownerMuteUntil: NullAwareTypeConverter.wrapFromSql(
              Users.$convertermuteUntil,
              row.readNullable<int>('ownerMuteUntil')),
          appId: row.readNullable<String>('appId'),
          content: row.readNullable<String>('content'),
          contentType: row.readNullable<String>('contentType'),
          createdAt: Conversations.$convertercreatedAt
              .fromSql(row.read<int>('createdAt')),
          lastMessageCreatedAt: NullAwareTypeConverter.wrapFromSql(
              Messages.$convertercreatedAt,
              row.readNullable<int>('lastMessageCreatedAt')),
          mediaUrl: row.readNullable<String>('mediaUrl'),
          senderId: row.readNullable<String>('senderId'),
          actionName: row.readNullable<String>('actionName'),
          messageStatus: NullAwareTypeConverter.wrapFromSql(
              Messages.$converterstatus,
              row.readNullable<String>('messageStatus')),
          senderFullName: row.readNullable<String>('senderFullName'),
          snapshotType: row.readNullable<String>('SnapshotType'),
          participantFullName: row.readNullable<String>('participantFullName'),
          participantUserId: row.readNullable<String>('participantUserId'),
          messageExpireIn: row.readNullable<int>('messageExpireIn'),
          mentionCount: row.read<int>('mentionCount'),
          relationship: Users.$converterrelationship
              .fromSql(row.readNullable<String>('relationship')),
        ));
  }

  Selectable<ConversationItem> _baseConversationItemsByCircleId(
      BaseConversationItemsByCircleId$where where,
      BaseConversationItemsByCircleId$order order,
      BaseConversationItemsByCircleId$limit limit) {
    var $arrayStartIndex = 1;
    final generatedwhere = $write(
        where(
            alias(this.conversations, 'conversation'),
            alias(this.users, 'owner'),
            alias(this.circleConversations, 'circleConversation'),
            alias(this.messages, 'lastMessage'),
            alias(this.users, 'lastMessageSender'),
            alias(this.snapshots, 'snapshot'),
            alias(this.users, 'participant'),
            alias(this.expiredMessages, 'em')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedwhere.amountOfVariables;
    final generatedorder = $write(
        order?.call(
                alias(this.conversations, 'conversation'),
                alias(this.users, 'owner'),
                alias(this.circleConversations, 'circleConversation'),
                alias(this.messages, 'lastMessage'),
                alias(this.users, 'lastMessageSender'),
                alias(this.snapshots, 'snapshot'),
                alias(this.users, 'participant'),
                alias(this.expiredMessages, 'em')) ??
            const OrderBy.nothing(),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedorder.amountOfVariables;
    final generatedlimit = $write(
        limit(
            alias(this.conversations, 'conversation'),
            alias(this.users, 'owner'),
            alias(this.circleConversations, 'circleConversation'),
            alias(this.messages, 'lastMessage'),
            alias(this.users, 'lastMessageSender'),
            alias(this.snapshots, 'snapshot'),
            alias(this.users, 'participant'),
            alias(this.expiredMessages, 'em')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedlimit.amountOfVariables;
    return customSelect(
        'SELECT conversation.conversation_id AS conversationId, conversation.icon_url AS groupIconUrl, conversation.category AS category, conversation.draft AS draft, conversation.name AS groupName, conversation.status AS status, conversation.last_read_message_id AS lastReadMessageId, conversation.unseen_message_count AS unseenMessageCount, conversation.owner_id AS ownerId, conversation.pin_time AS pinTime, conversation.mute_until AS muteUntil, conversation.expire_in AS expireIn, owner.avatar_url AS avatarUrl, owner.full_name AS name, owner.is_verified AS ownerVerified, owner.identity_number AS ownerIdentityNumber, owner.mute_until AS ownerMuteUntil, owner.app_id AS appId, lastMessage.content AS content, lastMessage.category AS contentType, conversation.created_at AS createdAt, lastMessage.created_at AS lastMessageCreatedAt, lastMessage.media_url AS mediaUrl, lastMessage.user_id AS senderId, lastMessage."action" AS actionName, lastMessage.status AS messageStatus, lastMessageSender.full_name AS senderFullName, snapshot.type AS SnapshotType, participant.full_name AS participantFullName, participant.user_id AS participantUserId, em.expire_in AS messageExpireIn, (SELECT COUNT(1) FROM message_mentions AS messageMention WHERE messageMention.conversation_id = conversation.conversation_id AND messageMention.has_read = 0) AS mentionCount, owner.relationship AS relationship FROM conversations AS conversation INNER JOIN users AS owner ON owner.user_id = conversation.owner_id LEFT JOIN circle_conversations AS circleConversation ON conversation.conversation_id = circleConversation.conversation_id LEFT JOIN messages AS lastMessage ON conversation.last_message_id = lastMessage.message_id LEFT JOIN users AS lastMessageSender ON lastMessageSender.user_id = lastMessage.user_id LEFT JOIN snapshots AS snapshot ON snapshot.snapshot_id = lastMessage.snapshot_id LEFT JOIN users AS participant ON participant.user_id = lastMessage.participant_id LEFT JOIN expired_messages AS em ON lastMessage.message_id = em.message_id WHERE ${generatedwhere.sql} ${generatedorder.sql} ${generatedlimit.sql}',
        variables: [
          ...generatedwhere.introducedVariables,
          ...generatedorder.introducedVariables,
          ...generatedlimit.introducedVariables
        ],
        readsFrom: {
          conversations,
          users,
          messages,
          snapshots,
          expiredMessages,
          messageMentions,
          circleConversations,
          ...generatedwhere.watchedTables,
          ...generatedorder.watchedTables,
          ...generatedlimit.watchedTables,
        }).map((QueryRow row) => ConversationItem(
          conversationId: row.read<String>('conversationId'),
          groupIconUrl: row.readNullable<String>('groupIconUrl'),
          category: Conversations.$convertercategory
              .fromSql(row.readNullable<String>('category')),
          draft: row.readNullable<String>('draft'),
          groupName: row.readNullable<String>('groupName'),
          status:
              Conversations.$converterstatus.fromSql(row.read<int>('status')),
          lastReadMessageId: row.readNullable<String>('lastReadMessageId'),
          unseenMessageCount: row.readNullable<int>('unseenMessageCount'),
          ownerId: row.readNullable<String>('ownerId'),
          pinTime: NullAwareTypeConverter.wrapFromSql(
              Conversations.$converterpinTime,
              row.readNullable<int>('pinTime')),
          muteUntil: NullAwareTypeConverter.wrapFromSql(
              Conversations.$convertermuteUntil,
              row.readNullable<int>('muteUntil')),
          expireIn: row.readNullable<int>('expireIn'),
          avatarUrl: row.readNullable<String>('avatarUrl'),
          name: row.readNullable<String>('name'),
          ownerVerified: row.readNullable<bool>('ownerVerified'),
          ownerIdentityNumber: row.read<String>('ownerIdentityNumber'),
          ownerMuteUntil: NullAwareTypeConverter.wrapFromSql(
              Users.$convertermuteUntil,
              row.readNullable<int>('ownerMuteUntil')),
          appId: row.readNullable<String>('appId'),
          content: row.readNullable<String>('content'),
          contentType: row.readNullable<String>('contentType'),
          createdAt: Conversations.$convertercreatedAt
              .fromSql(row.read<int>('createdAt')),
          lastMessageCreatedAt: NullAwareTypeConverter.wrapFromSql(
              Messages.$convertercreatedAt,
              row.readNullable<int>('lastMessageCreatedAt')),
          mediaUrl: row.readNullable<String>('mediaUrl'),
          senderId: row.readNullable<String>('senderId'),
          actionName: row.readNullable<String>('actionName'),
          messageStatus: NullAwareTypeConverter.wrapFromSql(
              Messages.$converterstatus,
              row.readNullable<String>('messageStatus')),
          senderFullName: row.readNullable<String>('senderFullName'),
          snapshotType: row.readNullable<String>('SnapshotType'),
          participantFullName: row.readNullable<String>('participantFullName'),
          participantUserId: row.readNullable<String>('participantUserId'),
          messageExpireIn: row.readNullable<int>('messageExpireIn'),
          mentionCount: row.read<int>('mentionCount'),
          relationship: Users.$converterrelationship
              .fromSql(row.readNullable<String>('relationship')),
        ));
  }

  Selectable<int> _baseUnseenMessageCount(BaseUnseenMessageCount$where where) {
    var $arrayStartIndex = 1;
    final generatedwhere = $write(
        where(
            alias(this.conversations, 'conversation'),
            alias(this.users, 'owner'),
            alias(this.circleConversations, 'circleConversation')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedwhere.amountOfVariables;
    return customSelect(
        'SELECT IFNULL(SUM(unseen_message_count), 0) AS _c0 FROM conversations AS conversation INNER JOIN users AS owner ON owner.user_id = conversation.owner_id LEFT JOIN circle_conversations AS circleConversation ON conversation.conversation_id = circleConversation.conversation_id WHERE ${generatedwhere.sql} LIMIT 1',
        variables: [
          ...generatedwhere.introducedVariables
        ],
        readsFrom: {
          conversations,
          users,
          circleConversations,
          ...generatedwhere.watchedTables,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }

  Selectable<BaseUnseenConversationCountResult> _baseUnseenConversationCount(
      BaseUnseenConversationCount$where where) {
    var $arrayStartIndex = 1;
    final generatedwhere = $write(
        where(alias(this.conversations, 'conversation'),
            alias(this.users, 'owner')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedwhere.amountOfVariables;
    return customSelect(
        'SELECT COUNT(1) AS unseen_conversation_count, IFNULL(SUM(CASE WHEN(CASE WHEN conversation.category = \'GROUP\' THEN conversation.mute_until ELSE owner.mute_until END)>=(strftime(\'%s\', \'now\') * 1000)AND IFNULL(conversation.unseen_message_count, 0) > 0 THEN 1 ELSE 0 END), 0) AS unseen_muted_conversation_count FROM conversations AS conversation INNER JOIN users AS owner ON owner.user_id = conversation.owner_id WHERE ${generatedwhere.sql} LIMIT 1',
        variables: [
          ...generatedwhere.introducedVariables
        ],
        readsFrom: {
          conversations,
          users,
          ...generatedwhere.watchedTables,
        }).map((QueryRow row) => BaseUnseenConversationCountResult(
          unseenConversationCount: row.read<int>('unseen_conversation_count'),
          unseenMutedConversationCount:
              row.read<int>('unseen_muted_conversation_count'),
        ));
  }

  Selectable<SearchConversationItem> _fuzzySearchConversation(
      String query,
      FuzzySearchConversation$where where,
      FuzzySearchConversation$limit limit) {
    var $arrayStartIndex = 2;
    final generatedwhere = $write(
        where(
            alias(this.conversations, 'conversation'),
            alias(this.users, 'owner'),
            alias(this.messages, 'message'),
            alias(this.users, 'lastMessageSender'),
            alias(this.users, 'participant')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedwhere.amountOfVariables;
    final generatedlimit = $write(
        limit(
            alias(this.conversations, 'conversation'),
            alias(this.users, 'owner'),
            alias(this.messages, 'message'),
            alias(this.users, 'lastMessageSender'),
            alias(this.users, 'participant')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedlimit.amountOfVariables;
    return customSelect(
        'SELECT conversation.conversation_id AS conversationId, conversation.icon_url AS groupIconUrl, conversation.category AS category, conversation.name AS groupName, conversation.pin_time AS pinTime, conversation.mute_until AS muteUntil, conversation.owner_id AS ownerId, owner.mute_until AS ownerMuteUntil, owner.identity_number AS ownerIdentityNumber, owner.full_name AS fullName, owner.avatar_url AS avatarUrl, owner.is_verified AS isVerified, owner.app_id AS appId, message.status AS messageStatus, message.content AS content, message.category AS contentType, message.user_id AS senderId, message."action" AS actionName, lastMessageSender.full_name AS senderFullName, participant.user_id AS participantUserId, participant.full_name AS participantFullName FROM conversations AS conversation INNER JOIN users AS owner ON owner.user_id = conversation.owner_id LEFT JOIN messages AS message ON conversation.last_message_id = message.message_id LEFT JOIN users AS lastMessageSender ON lastMessageSender.user_id = message.user_id LEFT JOIN users AS participant ON participant.user_id = message.participant_id WHERE((conversation.category = \'GROUP\' AND conversation.name LIKE \'%\' || ?1 || \'%\' ESCAPE \'\\\')OR(conversation.category = \'CONTACT\' AND(owner.full_name LIKE \'%\' || ?1 || \'%\' ESCAPE \'\\\' OR owner.identity_number LIKE \'%\' || ?1 || \'%\' ESCAPE \'\\\')))AND ${generatedwhere.sql} ORDER BY(conversation.category = \'GROUP\' AND conversation.name = ?1 COLLATE NOCASE)OR(conversation.category = \'CONTACT\' AND(owner.full_name = ?1 COLLATE NOCASE OR owner.identity_number = ?1 COLLATE NOCASE))DESC, conversation.pin_time DESC, message.created_at DESC ${generatedlimit.sql}',
        variables: [
          Variable<String>(query),
          ...generatedwhere.introducedVariables,
          ...generatedlimit.introducedVariables
        ],
        readsFrom: {
          conversations,
          users,
          messages,
          ...generatedwhere.watchedTables,
          ...generatedlimit.watchedTables,
        }).map((QueryRow row) => SearchConversationItem(
          conversationId: row.read<String>('conversationId'),
          groupIconUrl: row.readNullable<String>('groupIconUrl'),
          category: Conversations.$convertercategory
              .fromSql(row.readNullable<String>('category')),
          groupName: row.readNullable<String>('groupName'),
          pinTime: NullAwareTypeConverter.wrapFromSql(
              Conversations.$converterpinTime,
              row.readNullable<int>('pinTime')),
          muteUntil: NullAwareTypeConverter.wrapFromSql(
              Conversations.$convertermuteUntil,
              row.readNullable<int>('muteUntil')),
          ownerId: row.readNullable<String>('ownerId'),
          ownerMuteUntil: NullAwareTypeConverter.wrapFromSql(
              Users.$convertermuteUntil,
              row.readNullable<int>('ownerMuteUntil')),
          ownerIdentityNumber: row.read<String>('ownerIdentityNumber'),
          fullName: row.readNullable<String>('fullName'),
          avatarUrl: row.readNullable<String>('avatarUrl'),
          isVerified: row.readNullable<bool>('isVerified'),
          appId: row.readNullable<String>('appId'),
          messageStatus: NullAwareTypeConverter.wrapFromSql(
              Messages.$converterstatus,
              row.readNullable<String>('messageStatus')),
          content: row.readNullable<String>('content'),
          contentType: row.readNullable<String>('contentType'),
          senderId: row.readNullable<String>('senderId'),
          actionName: row.readNullable<String>('actionName'),
          senderFullName: row.readNullable<String>('senderFullName'),
          participantUserId: row.readNullable<String>('participantUserId'),
          participantFullName: row.readNullable<String>('participantFullName'),
        ));
  }

  Selectable<SearchConversationItem> _searchConversationItemByIn(
      List<String> ids, SearchConversationItemByIn$order order) {
    var $arrayStartIndex = 1;
    final expandedids = $expandVar($arrayStartIndex, ids.length);
    $arrayStartIndex += ids.length;
    final generatedorder = $write(
        order?.call(
                alias(this.conversations, 'conversation'),
                alias(this.users, 'owner'),
                alias(this.messages, 'message'),
                alias(this.users, 'lastMessageSender'),
                alias(this.users, 'participant')) ??
            const OrderBy.nothing(),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedorder.amountOfVariables;
    return customSelect(
        'SELECT conversation.conversation_id AS conversationId, conversation.icon_url AS groupIconUrl, conversation.category AS category, conversation.name AS groupName, conversation.pin_time AS pinTime, conversation.mute_until AS muteUntil, conversation.owner_id AS ownerId, owner.mute_until AS ownerMuteUntil, owner.identity_number AS ownerIdentityNumber, owner.full_name AS fullName, owner.avatar_url AS avatarUrl, owner.is_verified AS isVerified, owner.app_id AS appId, message.status AS messageStatus, message.content AS content, message.category AS contentType, message.user_id AS senderId, message."action" AS actionName, lastMessageSender.full_name AS senderFullName, participant.user_id AS participantUserId, participant.full_name AS participantFullName FROM conversations AS conversation INNER JOIN users AS owner ON owner.user_id = conversation.owner_id LEFT JOIN messages AS message ON conversation.last_message_id = message.message_id LEFT JOIN users AS lastMessageSender ON lastMessageSender.user_id = message.user_id LEFT JOIN users AS participant ON participant.user_id = message.participant_id WHERE conversation.conversation_id IN ($expandedids) ${generatedorder.sql}',
        variables: [
          for (var $ in ids) Variable<String>($),
          ...generatedorder.introducedVariables
        ],
        readsFrom: {
          conversations,
          users,
          messages,
          ...generatedorder.watchedTables,
        }).map((QueryRow row) => SearchConversationItem(
          conversationId: row.read<String>('conversationId'),
          groupIconUrl: row.readNullable<String>('groupIconUrl'),
          category: Conversations.$convertercategory
              .fromSql(row.readNullable<String>('category')),
          groupName: row.readNullable<String>('groupName'),
          pinTime: NullAwareTypeConverter.wrapFromSql(
              Conversations.$converterpinTime,
              row.readNullable<int>('pinTime')),
          muteUntil: NullAwareTypeConverter.wrapFromSql(
              Conversations.$convertermuteUntil,
              row.readNullable<int>('muteUntil')),
          ownerId: row.readNullable<String>('ownerId'),
          ownerMuteUntil: NullAwareTypeConverter.wrapFromSql(
              Users.$convertermuteUntil,
              row.readNullable<int>('ownerMuteUntil')),
          ownerIdentityNumber: row.read<String>('ownerIdentityNumber'),
          fullName: row.readNullable<String>('fullName'),
          avatarUrl: row.readNullable<String>('avatarUrl'),
          isVerified: row.readNullable<bool>('isVerified'),
          appId: row.readNullable<String>('appId'),
          messageStatus: NullAwareTypeConverter.wrapFromSql(
              Messages.$converterstatus,
              row.readNullable<String>('messageStatus')),
          content: row.readNullable<String>('content'),
          contentType: row.readNullable<String>('contentType'),
          senderId: row.readNullable<String>('senderId'),
          actionName: row.readNullable<String>('actionName'),
          senderFullName: row.readNullable<String>('senderFullName'),
          participantUserId: row.readNullable<String>('participantUserId'),
          participantFullName: row.readNullable<String>('participantFullName'),
        ));
  }

  Selectable<SearchConversationItem> _fuzzySearchConversationInCircle(
      String query,
      String? circleId,
      FuzzySearchConversationInCircle$where where,
      FuzzySearchConversationInCircle$limit limit) {
    var $arrayStartIndex = 3;
    final generatedwhere = $write(
        where(
            alias(this.conversations, 'conversation'),
            alias(this.users, 'owner'),
            alias(this.messages, 'message'),
            alias(this.users, 'lastMessageSender'),
            alias(this.circleConversations, 'circleConversation'),
            alias(this.users, 'participant')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedwhere.amountOfVariables;
    final generatedlimit = $write(
        limit(
            alias(this.conversations, 'conversation'),
            alias(this.users, 'owner'),
            alias(this.messages, 'message'),
            alias(this.users, 'lastMessageSender'),
            alias(this.circleConversations, 'circleConversation'),
            alias(this.users, 'participant')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedlimit.amountOfVariables;
    return customSelect(
        'SELECT conversation.conversation_id AS conversationId, conversation.icon_url AS groupIconUrl, conversation.category AS category, conversation.name AS groupName, conversation.pin_time AS pinTime, conversation.mute_until AS muteUntil, conversation.owner_id AS ownerId, owner.mute_until AS ownerMuteUntil, owner.identity_number AS ownerIdentityNumber, owner.full_name AS fullName, owner.avatar_url AS avatarUrl, owner.is_verified AS isVerified, owner.app_id AS appId, message.status AS messageStatus, message.content AS content, message.category AS contentType, message.user_id AS senderId, message."action" AS actionName, lastMessageSender.full_name AS senderFullName, participant.user_id AS participantUserId, participant.full_name AS participantFullName FROM conversations AS conversation INNER JOIN users AS owner ON owner.user_id = conversation.owner_id LEFT JOIN messages AS message ON conversation.last_message_id = message.message_id LEFT JOIN users AS lastMessageSender ON lastMessageSender.user_id = message.user_id LEFT JOIN circle_conversations AS circleConversation ON conversation.conversation_id = circleConversation.conversation_id LEFT JOIN users AS participant ON participant.user_id = message.participant_id WHERE((conversation.category = \'GROUP\' AND conversation.name LIKE \'%\' || ?1 || \'%\' ESCAPE \'\\\')OR(conversation.category = \'CONTACT\' AND(owner.full_name LIKE \'%\' || ?1 || \'%\' ESCAPE \'\\\' OR owner.identity_number LIKE \'%\' || ?1 || \'%\' ESCAPE \'\\\')))AND circleConversation.circle_id = ?2 AND ${generatedwhere.sql} ORDER BY(conversation.category = \'GROUP\' AND conversation.name = ?1 COLLATE NOCASE)OR(conversation.category = \'CONTACT\' AND(owner.full_name = ?1 COLLATE NOCASE OR owner.identity_number = ?1 COLLATE NOCASE))DESC, conversation.pin_time DESC, message.created_at DESC ${generatedlimit.sql}',
        variables: [
          Variable<String>(query),
          Variable<String>(circleId),
          ...generatedwhere.introducedVariables,
          ...generatedlimit.introducedVariables
        ],
        readsFrom: {
          conversations,
          users,
          messages,
          circleConversations,
          ...generatedwhere.watchedTables,
          ...generatedlimit.watchedTables,
        }).map((QueryRow row) => SearchConversationItem(
          conversationId: row.read<String>('conversationId'),
          groupIconUrl: row.readNullable<String>('groupIconUrl'),
          category: Conversations.$convertercategory
              .fromSql(row.readNullable<String>('category')),
          groupName: row.readNullable<String>('groupName'),
          pinTime: NullAwareTypeConverter.wrapFromSql(
              Conversations.$converterpinTime,
              row.readNullable<int>('pinTime')),
          muteUntil: NullAwareTypeConverter.wrapFromSql(
              Conversations.$convertermuteUntil,
              row.readNullable<int>('muteUntil')),
          ownerId: row.readNullable<String>('ownerId'),
          ownerMuteUntil: NullAwareTypeConverter.wrapFromSql(
              Users.$convertermuteUntil,
              row.readNullable<int>('ownerMuteUntil')),
          ownerIdentityNumber: row.read<String>('ownerIdentityNumber'),
          fullName: row.readNullable<String>('fullName'),
          avatarUrl: row.readNullable<String>('avatarUrl'),
          isVerified: row.readNullable<bool>('isVerified'),
          appId: row.readNullable<String>('appId'),
          messageStatus: NullAwareTypeConverter.wrapFromSql(
              Messages.$converterstatus,
              row.readNullable<String>('messageStatus')),
          content: row.readNullable<String>('content'),
          contentType: row.readNullable<String>('contentType'),
          senderId: row.readNullable<String>('senderId'),
          actionName: row.readNullable<String>('actionName'),
          senderFullName: row.readNullable<String>('senderFullName'),
          participantUserId: row.readNullable<String>('participantUserId'),
          participantFullName: row.readNullable<String>('participantFullName'),
        ));
  }

  Selectable<ConversationStorageUsage> conversationStorageUsage() {
    return customSelect(
        'SELECT c.conversation_id, c.owner_id, c.category, c.icon_url, c.name, u.identity_number, u.full_name, u.avatar_url, u.is_verified FROM conversations AS c INNER JOIN users AS u ON u.user_id = c.owner_id WHERE c.category IS NOT NULL',
        variables: [],
        readsFrom: {
          conversations,
          users,
        }).map((QueryRow row) => ConversationStorageUsage(
          conversationId: row.read<String>('conversation_id'),
          ownerId: row.readNullable<String>('owner_id'),
          category: Conversations.$convertercategory
              .fromSql(row.readNullable<String>('category')),
          iconUrl: row.readNullable<String>('icon_url'),
          name: row.readNullable<String>('name'),
          identityNumber: row.read<String>('identity_number'),
          fullName: row.readNullable<String>('full_name'),
          avatarUrl: row.readNullable<String>('avatar_url'),
          isVerified: row.readNullable<bool>('is_verified'),
        ));
  }

  Selectable<GroupMinimal> findSameConversations(String selfId, String userId) {
    return customSelect(
        'SELECT c.conversation_id AS conversationId, c.icon_url AS groupIconUrl, c.name AS groupName, (SELECT count(user_id) FROM participants WHERE conversation_id = c.conversation_id) AS memberCount FROM participants AS p INNER JOIN conversations AS c ON c.conversation_id = p.conversation_id WHERE p.user_id IN (?1, ?2) AND c.status = 2 AND c.category = \'GROUP\' GROUP BY c.conversation_id HAVING count(p.user_id) = 2 ORDER BY c.last_message_created_at DESC',
        variables: [
          Variable<String>(selfId),
          Variable<String>(userId)
        ],
        readsFrom: {
          conversations,
          participants,
        }).map((QueryRow row) => GroupMinimal(
          conversationId: row.read<String>('conversationId'),
          groupIconUrl: row.readNullable<String>('groupIconUrl'),
          groupName: row.readNullable<String>('groupName'),
          memberCount: row.read<int>('memberCount'),
        ));
  }

  Selectable<int> countConversations() {
    return customSelect('SELECT COUNT(1) AS _c0 FROM conversations',
        variables: [],
        readsFrom: {
          conversations,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }

  Future<int> _updateUnseenMessageCountAndLastMessageId(String conversationId,
      String userId, String? lastMessageId, DateTime? lastMessageCreatedAt) {
    return customUpdate(
      'UPDATE conversations SET unseen_message_count = (SELECT count(1) FROM messages WHERE conversation_id = ?1 AND status IN (\'SENT\', \'DELIVERED\') AND user_id != ?2), last_message_id = ?3, last_message_created_at = ?4 WHERE conversation_id = ?1',
      variables: [
        Variable<String>(conversationId),
        Variable<String>(userId),
        Variable<String>(lastMessageId),
        Variable<int>(NullAwareTypeConverter.wrapToSql(
            Conversations.$converterlastMessageCreatedAt, lastMessageCreatedAt))
      ],
      updates: {conversations},
      updateKind: UpdateKind.update,
    );
  }

  Selectable<bool> isBotGroup(String conversationId) {
    return customSelect(
        'SELECT (SELECT 1 FROM conversations INNER JOIN messages ON conversations.conversation_id = messages.conversation_id INNER JOIN users ON users.user_id = conversations.owner_id WHERE conversations.conversation_id = ?1 AND conversations.category = \'CONTACT\' AND users.app_id IS NOT NULL AND Length(users.app_id) > 0 AND messages.user_id != conversations.owner_id GROUP BY conversations.conversation_id HAVING Count(DISTINCT messages.user_id) >= 2) IS NOT NULL AS _c0',
        variables: [
          Variable<String>(conversationId)
        ],
        readsFrom: {
          conversations,
          messages,
          users,
        }).map((QueryRow row) => row.read<bool>('_c0'));
  }
}
typedef BaseConversationItemCount$where = Expression<bool> Function(
    Conversations conversation,
    Users owner,
    CircleConversations circleConversation);

class ConversationItem {
  final String conversationId;
  final String? groupIconUrl;
  final ConversationCategory? category;
  final String? draft;
  final String? groupName;
  final ConversationStatus status;
  final String? lastReadMessageId;
  final int? unseenMessageCount;
  final String? ownerId;
  final DateTime? pinTime;
  final DateTime? muteUntil;
  final int? expireIn;
  final String? avatarUrl;
  final String? name;
  final bool? ownerVerified;
  final String ownerIdentityNumber;
  final DateTime? ownerMuteUntil;
  final String? appId;
  final String? content;
  final String? contentType;
  final DateTime createdAt;
  final DateTime? lastMessageCreatedAt;
  final String? mediaUrl;
  final String? senderId;
  final String? actionName;
  final MessageStatus? messageStatus;
  final String? senderFullName;
  final String? snapshotType;
  final String? participantFullName;
  final String? participantUserId;
  final int? messageExpireIn;
  final int mentionCount;
  final UserRelationship? relationship;
  ConversationItem({
    required this.conversationId,
    this.groupIconUrl,
    this.category,
    this.draft,
    this.groupName,
    required this.status,
    this.lastReadMessageId,
    this.unseenMessageCount,
    this.ownerId,
    this.pinTime,
    this.muteUntil,
    this.expireIn,
    this.avatarUrl,
    this.name,
    this.ownerVerified,
    required this.ownerIdentityNumber,
    this.ownerMuteUntil,
    this.appId,
    this.content,
    this.contentType,
    required this.createdAt,
    this.lastMessageCreatedAt,
    this.mediaUrl,
    this.senderId,
    this.actionName,
    this.messageStatus,
    this.senderFullName,
    this.snapshotType,
    this.participantFullName,
    this.participantUserId,
    this.messageExpireIn,
    required this.mentionCount,
    this.relationship,
  });
  @override
  int get hashCode => Object.hashAll([
        conversationId,
        groupIconUrl,
        category,
        draft,
        groupName,
        status,
        lastReadMessageId,
        unseenMessageCount,
        ownerId,
        pinTime,
        muteUntil,
        expireIn,
        avatarUrl,
        name,
        ownerVerified,
        ownerIdentityNumber,
        ownerMuteUntil,
        appId,
        content,
        contentType,
        createdAt,
        lastMessageCreatedAt,
        mediaUrl,
        senderId,
        actionName,
        messageStatus,
        senderFullName,
        snapshotType,
        participantFullName,
        participantUserId,
        messageExpireIn,
        mentionCount,
        relationship
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationItem &&
          other.conversationId == this.conversationId &&
          other.groupIconUrl == this.groupIconUrl &&
          other.category == this.category &&
          other.draft == this.draft &&
          other.groupName == this.groupName &&
          other.status == this.status &&
          other.lastReadMessageId == this.lastReadMessageId &&
          other.unseenMessageCount == this.unseenMessageCount &&
          other.ownerId == this.ownerId &&
          other.pinTime == this.pinTime &&
          other.muteUntil == this.muteUntil &&
          other.expireIn == this.expireIn &&
          other.avatarUrl == this.avatarUrl &&
          other.name == this.name &&
          other.ownerVerified == this.ownerVerified &&
          other.ownerIdentityNumber == this.ownerIdentityNumber &&
          other.ownerMuteUntil == this.ownerMuteUntil &&
          other.appId == this.appId &&
          other.content == this.content &&
          other.contentType == this.contentType &&
          other.createdAt == this.createdAt &&
          other.lastMessageCreatedAt == this.lastMessageCreatedAt &&
          other.mediaUrl == this.mediaUrl &&
          other.senderId == this.senderId &&
          other.actionName == this.actionName &&
          other.messageStatus == this.messageStatus &&
          other.senderFullName == this.senderFullName &&
          other.snapshotType == this.snapshotType &&
          other.participantFullName == this.participantFullName &&
          other.participantUserId == this.participantUserId &&
          other.messageExpireIn == this.messageExpireIn &&
          other.mentionCount == this.mentionCount &&
          other.relationship == this.relationship);
  @override
  String toString() {
    return (StringBuffer('ConversationItem(')
          ..write('conversationId: $conversationId, ')
          ..write('groupIconUrl: $groupIconUrl, ')
          ..write('category: $category, ')
          ..write('draft: $draft, ')
          ..write('groupName: $groupName, ')
          ..write('status: $status, ')
          ..write('lastReadMessageId: $lastReadMessageId, ')
          ..write('unseenMessageCount: $unseenMessageCount, ')
          ..write('ownerId: $ownerId, ')
          ..write('pinTime: $pinTime, ')
          ..write('muteUntil: $muteUntil, ')
          ..write('expireIn: $expireIn, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('name: $name, ')
          ..write('ownerVerified: $ownerVerified, ')
          ..write('ownerIdentityNumber: $ownerIdentityNumber, ')
          ..write('ownerMuteUntil: $ownerMuteUntil, ')
          ..write('appId: $appId, ')
          ..write('content: $content, ')
          ..write('contentType: $contentType, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastMessageCreatedAt: $lastMessageCreatedAt, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('senderId: $senderId, ')
          ..write('actionName: $actionName, ')
          ..write('messageStatus: $messageStatus, ')
          ..write('senderFullName: $senderFullName, ')
          ..write('snapshotType: $snapshotType, ')
          ..write('participantFullName: $participantFullName, ')
          ..write('participantUserId: $participantUserId, ')
          ..write('messageExpireIn: $messageExpireIn, ')
          ..write('mentionCount: $mentionCount, ')
          ..write('relationship: $relationship')
          ..write(')'))
        .toString();
  }
}

typedef BaseConversationItems$where = Expression<bool> Function(
    Conversations conversation,
    Users owner,
    Messages lastMessage,
    Users lastMessageSender,
    Snapshots snapshot,
    Users participant,
    ExpiredMessages em);
typedef BaseConversationItems$order = OrderBy Function(
    Conversations conversation,
    Users owner,
    Messages lastMessage,
    Users lastMessageSender,
    Snapshots snapshot,
    Users participant,
    ExpiredMessages em);
typedef BaseConversationItems$limit = Limit Function(
    Conversations conversation,
    Users owner,
    Messages lastMessage,
    Users lastMessageSender,
    Snapshots snapshot,
    Users participant,
    ExpiredMessages em);
typedef BaseConversationItemsByCircleId$where = Expression<bool> Function(
    Conversations conversation,
    Users owner,
    CircleConversations circleConversation,
    Messages lastMessage,
    Users lastMessageSender,
    Snapshots snapshot,
    Users participant,
    ExpiredMessages em);
typedef BaseConversationItemsByCircleId$order = OrderBy Function(
    Conversations conversation,
    Users owner,
    CircleConversations circleConversation,
    Messages lastMessage,
    Users lastMessageSender,
    Snapshots snapshot,
    Users participant,
    ExpiredMessages em);
typedef BaseConversationItemsByCircleId$limit = Limit Function(
    Conversations conversation,
    Users owner,
    CircleConversations circleConversation,
    Messages lastMessage,
    Users lastMessageSender,
    Snapshots snapshot,
    Users participant,
    ExpiredMessages em);
typedef BaseUnseenMessageCount$where = Expression<bool> Function(
    Conversations conversation,
    Users owner,
    CircleConversations circleConversation);

class BaseUnseenConversationCountResult {
  final int unseenConversationCount;
  final int unseenMutedConversationCount;
  BaseUnseenConversationCountResult({
    required this.unseenConversationCount,
    required this.unseenMutedConversationCount,
  });
  @override
  int get hashCode =>
      Object.hash(unseenConversationCount, unseenMutedConversationCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BaseUnseenConversationCountResult &&
          other.unseenConversationCount == this.unseenConversationCount &&
          other.unseenMutedConversationCount ==
              this.unseenMutedConversationCount);
  @override
  String toString() {
    return (StringBuffer('BaseUnseenConversationCountResult(')
          ..write('unseenConversationCount: $unseenConversationCount, ')
          ..write('unseenMutedConversationCount: $unseenMutedConversationCount')
          ..write(')'))
        .toString();
  }
}

typedef BaseUnseenConversationCount$where = Expression<bool> Function(
    Conversations conversation, Users owner);

class SearchConversationItem {
  final String conversationId;
  final String? groupIconUrl;
  final ConversationCategory? category;
  final String? groupName;
  final DateTime? pinTime;
  final DateTime? muteUntil;
  final String? ownerId;
  final DateTime? ownerMuteUntil;
  final String ownerIdentityNumber;
  final String? fullName;
  final String? avatarUrl;
  final bool? isVerified;
  final String? appId;
  final MessageStatus? messageStatus;
  final String? content;
  final String? contentType;
  final String? senderId;
  final String? actionName;
  final String? senderFullName;
  final String? participantUserId;
  final String? participantFullName;
  SearchConversationItem({
    required this.conversationId,
    this.groupIconUrl,
    this.category,
    this.groupName,
    this.pinTime,
    this.muteUntil,
    this.ownerId,
    this.ownerMuteUntil,
    required this.ownerIdentityNumber,
    this.fullName,
    this.avatarUrl,
    this.isVerified,
    this.appId,
    this.messageStatus,
    this.content,
    this.contentType,
    this.senderId,
    this.actionName,
    this.senderFullName,
    this.participantUserId,
    this.participantFullName,
  });
  @override
  int get hashCode => Object.hashAll([
        conversationId,
        groupIconUrl,
        category,
        groupName,
        pinTime,
        muteUntil,
        ownerId,
        ownerMuteUntil,
        ownerIdentityNumber,
        fullName,
        avatarUrl,
        isVerified,
        appId,
        messageStatus,
        content,
        contentType,
        senderId,
        actionName,
        senderFullName,
        participantUserId,
        participantFullName
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchConversationItem &&
          other.conversationId == this.conversationId &&
          other.groupIconUrl == this.groupIconUrl &&
          other.category == this.category &&
          other.groupName == this.groupName &&
          other.pinTime == this.pinTime &&
          other.muteUntil == this.muteUntil &&
          other.ownerId == this.ownerId &&
          other.ownerMuteUntil == this.ownerMuteUntil &&
          other.ownerIdentityNumber == this.ownerIdentityNumber &&
          other.fullName == this.fullName &&
          other.avatarUrl == this.avatarUrl &&
          other.isVerified == this.isVerified &&
          other.appId == this.appId &&
          other.messageStatus == this.messageStatus &&
          other.content == this.content &&
          other.contentType == this.contentType &&
          other.senderId == this.senderId &&
          other.actionName == this.actionName &&
          other.senderFullName == this.senderFullName &&
          other.participantUserId == this.participantUserId &&
          other.participantFullName == this.participantFullName);
  @override
  String toString() {
    return (StringBuffer('SearchConversationItem(')
          ..write('conversationId: $conversationId, ')
          ..write('groupIconUrl: $groupIconUrl, ')
          ..write('category: $category, ')
          ..write('groupName: $groupName, ')
          ..write('pinTime: $pinTime, ')
          ..write('muteUntil: $muteUntil, ')
          ..write('ownerId: $ownerId, ')
          ..write('ownerMuteUntil: $ownerMuteUntil, ')
          ..write('ownerIdentityNumber: $ownerIdentityNumber, ')
          ..write('fullName: $fullName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('isVerified: $isVerified, ')
          ..write('appId: $appId, ')
          ..write('messageStatus: $messageStatus, ')
          ..write('content: $content, ')
          ..write('contentType: $contentType, ')
          ..write('senderId: $senderId, ')
          ..write('actionName: $actionName, ')
          ..write('senderFullName: $senderFullName, ')
          ..write('participantUserId: $participantUserId, ')
          ..write('participantFullName: $participantFullName')
          ..write(')'))
        .toString();
  }
}

typedef FuzzySearchConversation$where = Expression<bool> Function(
    Conversations conversation,
    Users owner,
    Messages message,
    Users lastMessageSender,
    Users participant);
typedef FuzzySearchConversation$limit = Limit Function(
    Conversations conversation,
    Users owner,
    Messages message,
    Users lastMessageSender,
    Users participant);
typedef SearchConversationItemByIn$order = OrderBy Function(
    Conversations conversation,
    Users owner,
    Messages message,
    Users lastMessageSender,
    Users participant);
typedef FuzzySearchConversationInCircle$where = Expression<bool> Function(
    Conversations conversation,
    Users owner,
    Messages message,
    Users lastMessageSender,
    CircleConversations circleConversation,
    Users participant);
typedef FuzzySearchConversationInCircle$limit = Limit Function(
    Conversations conversation,
    Users owner,
    Messages message,
    Users lastMessageSender,
    CircleConversations circleConversation,
    Users participant);

class ConversationStorageUsage {
  final String conversationId;
  final String? ownerId;
  final ConversationCategory? category;
  final String? iconUrl;
  final String? name;
  final String identityNumber;
  final String? fullName;
  final String? avatarUrl;
  final bool? isVerified;
  ConversationStorageUsage({
    required this.conversationId,
    this.ownerId,
    this.category,
    this.iconUrl,
    this.name,
    required this.identityNumber,
    this.fullName,
    this.avatarUrl,
    this.isVerified,
  });
  @override
  int get hashCode => Object.hash(conversationId, ownerId, category, iconUrl,
      name, identityNumber, fullName, avatarUrl, isVerified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationStorageUsage &&
          other.conversationId == this.conversationId &&
          other.ownerId == this.ownerId &&
          other.category == this.category &&
          other.iconUrl == this.iconUrl &&
          other.name == this.name &&
          other.identityNumber == this.identityNumber &&
          other.fullName == this.fullName &&
          other.avatarUrl == this.avatarUrl &&
          other.isVerified == this.isVerified);
  @override
  String toString() {
    return (StringBuffer('ConversationStorageUsage(')
          ..write('conversationId: $conversationId, ')
          ..write('ownerId: $ownerId, ')
          ..write('category: $category, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('name: $name, ')
          ..write('identityNumber: $identityNumber, ')
          ..write('fullName: $fullName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('isVerified: $isVerified')
          ..write(')'))
        .toString();
  }
}

class GroupMinimal {
  final String conversationId;
  final String? groupIconUrl;
  final String? groupName;
  final int memberCount;
  GroupMinimal({
    required this.conversationId,
    this.groupIconUrl,
    this.groupName,
    required this.memberCount,
  });
  @override
  int get hashCode =>
      Object.hash(conversationId, groupIconUrl, groupName, memberCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupMinimal &&
          other.conversationId == this.conversationId &&
          other.groupIconUrl == this.groupIconUrl &&
          other.groupName == this.groupName &&
          other.memberCount == this.memberCount);
  @override
  String toString() {
    return (StringBuffer('GroupMinimal(')
          ..write('conversationId: $conversationId, ')
          ..write('groupIconUrl: $groupIconUrl, ')
          ..write('groupName: $groupName, ')
          ..write('memberCount: $memberCount')
          ..write(')'))
        .toString();
  }
}
