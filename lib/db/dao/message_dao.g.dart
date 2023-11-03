// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_dao.dart';

// ignore_for_file: type=lint
mixin _$MessageDaoMixin on DatabaseAccessor<MixinDatabase> {
  Conversations get conversations => attachedDatabase.conversations;
  Messages get messages => attachedDatabase.messages;
  Users get users => attachedDatabase.users;
  Stickers get stickers => attachedDatabase.stickers;
  MessageMentions get messageMentions => attachedDatabase.messageMentions;
  ResendSessionMessages get resendSessionMessages =>
      attachedDatabase.resendSessionMessages;
  Addresses get addresses => attachedDatabase.addresses;
  Apps get apps => attachedDatabase.apps;
  Assets get assets => attachedDatabase.assets;
  CircleConversations get circleConversations =>
      attachedDatabase.circleConversations;
  Circles get circles => attachedDatabase.circles;
  FloodMessages get floodMessages => attachedDatabase.floodMessages;
  Hyperlinks get hyperlinks => attachedDatabase.hyperlinks;
  Jobs get jobs => attachedDatabase.jobs;
  MessagesHistory get messagesHistory => attachedDatabase.messagesHistory;
  Offsets get offsets => attachedDatabase.offsets;
  ParticipantSession get participantSession =>
      attachedDatabase.participantSession;
  Participants get participants => attachedDatabase.participants;
  SentSessionSenderKeys get sentSessionSenderKeys =>
      attachedDatabase.sentSessionSenderKeys;
  Snapshots get snapshots => attachedDatabase.snapshots;
  StickerAlbums get stickerAlbums => attachedDatabase.stickerAlbums;
  StickerRelationships get stickerRelationships =>
      attachedDatabase.stickerRelationships;
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
  Selectable<QuoteMessageItem> _baseQuoteMessageItem(
      BaseQuoteMessageItem$where where,
      BaseQuoteMessageItem$order order,
      BaseQuoteMessageItem$limit limit) {
    var $arrayStartIndex = 1;
    final generatedwhere = $write(
        where(
            alias(this.messages, 'message'),
            alias(this.users, 'sender'),
            alias(this.stickers, 'sticker'),
            alias(this.users, 'shareUser'),
            alias(this.messageMentions, 'messageMention')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedwhere.amountOfVariables;
    final generatedorder = $write(
        order?.call(
                alias(this.messages, 'message'),
                alias(this.users, 'sender'),
                alias(this.stickers, 'sticker'),
                alias(this.users, 'shareUser'),
                alias(this.messageMentions, 'messageMention')) ??
            const OrderBy.nothing(),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedorder.amountOfVariables;
    final generatedlimit = $write(
        limit(
            alias(this.messages, 'message'),
            alias(this.users, 'sender'),
            alias(this.stickers, 'sticker'),
            alias(this.users, 'shareUser'),
            alias(this.messageMentions, 'messageMention')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedlimit.amountOfVariables;
    return customSelect(
        'SELECT message.message_id AS messageId, message.conversation_id AS conversationId, sender.user_id AS userId, sender.full_name AS userFullName, sender.identity_number AS userIdentityNumber, sender.app_id AS appId, message.category AS type, message.content AS content, message.created_at AS createdAt, message.status AS status, message.media_status AS mediaStatus, message.media_waveform AS mediaWaveform, message.name AS mediaName, message.media_mime_type AS mediaMimeType, message.media_size AS mediaSize, message.media_width AS mediaWidth, message.media_height AS mediaHeight, message.thumb_image AS thumbImage, message.thumb_url AS thumbUrl, message.media_url AS mediaUrl, message.media_duration AS mediaDuration, message.sticker_id AS stickerId, sticker.asset_url AS assetUrl, sticker.asset_width AS assetWidth, sticker.asset_height AS assetHeight, sticker.name AS assetName, sticker.asset_type AS assetType, message.shared_user_id AS sharedUserId, shareUser.full_name AS sharedUserFullName, shareUser.identity_number AS sharedUserIdentityNumber, shareUser.avatar_url AS sharedUserAvatarUrl, shareUser.is_verified AS sharedUserIsVerified, shareUser.app_id AS sharedUserAppId FROM messages AS message INNER JOIN users AS sender ON message.user_id = sender.user_id LEFT JOIN stickers AS sticker ON sticker.sticker_id = message.sticker_id LEFT JOIN users AS shareUser ON message.shared_user_id = shareUser.user_id LEFT JOIN message_mentions AS messageMention ON message.message_id = messageMention.message_id WHERE ${generatedwhere.sql} ${generatedorder.sql} ${generatedlimit.sql}',
        variables: [
          ...generatedwhere.introducedVariables,
          ...generatedorder.introducedVariables,
          ...generatedlimit.introducedVariables
        ],
        readsFrom: {
          messages,
          users,
          stickers,
          messageMentions,
          ...generatedwhere.watchedTables,
          ...generatedorder.watchedTables,
          ...generatedlimit.watchedTables,
        }).map((QueryRow row) => QuoteMessageItem(
          messageId: row.read<String>('messageId'),
          conversationId: row.read<String>('conversationId'),
          userId: row.read<String>('userId'),
          userFullName: row.readNullable<String>('userFullName'),
          userIdentityNumber: row.read<String>('userIdentityNumber'),
          appId: row.readNullable<String>('appId'),
          type: row.read<String>('type'),
          content: row.readNullable<String>('content'),
          createdAt:
              Messages.$convertercreatedAt.fromSql(row.read<int>('createdAt')),
          status: Messages.$converterstatus.fromSql(row.read<String>('status')),
          mediaStatus: Messages.$convertermediaStatus
              .fromSql(row.readNullable<String>('mediaStatus')),
          mediaWaveform: row.readNullable<String>('mediaWaveform'),
          mediaName: row.readNullable<String>('mediaName'),
          mediaMimeType: row.readNullable<String>('mediaMimeType'),
          mediaSize: row.readNullable<int>('mediaSize'),
          mediaWidth: row.readNullable<int>('mediaWidth'),
          mediaHeight: row.readNullable<int>('mediaHeight'),
          thumbImage: row.readNullable<String>('thumbImage'),
          thumbUrl: row.readNullable<String>('thumbUrl'),
          mediaUrl: row.readNullable<String>('mediaUrl'),
          mediaDuration: row.readNullable<String>('mediaDuration'),
          stickerId: row.readNullable<String>('stickerId'),
          assetUrl: row.readNullable<String>('assetUrl'),
          assetWidth: row.readNullable<int>('assetWidth'),
          assetHeight: row.readNullable<int>('assetHeight'),
          assetName: row.readNullable<String>('assetName'),
          assetType: row.readNullable<String>('assetType'),
          sharedUserId: row.readNullable<String>('sharedUserId'),
          sharedUserFullName: row.readNullable<String>('sharedUserFullName'),
          sharedUserIdentityNumber:
              row.readNullable<String>('sharedUserIdentityNumber'),
          sharedUserAvatarUrl: row.readNullable<String>('sharedUserAvatarUrl'),
          sharedUserIsVerified: row.readNullable<bool>('sharedUserIsVerified'),
          sharedUserAppId: row.readNullable<String>('sharedUserAppId'),
        ));
  }

  Selectable<MessageStatus> messageStatusById(String messageId) {
    return customSelect(
        'SELECT status FROM messages WHERE message_id = ?1 LIMIT 1',
        variables: [
          Variable<String>(messageId)
        ],
        readsFrom: {
          messages,
        }).map((QueryRow row) =>
        Messages.$converterstatus.fromSql(row.read<String>('status')));
  }

  Selectable<SendingMessage> sendingMessage(String messageId) {
    return customSelect(
        'SELECT m.message_id, m.conversation_id, m.user_id, m.category, m.content, m.media_url, m.media_mime_type, m.media_size, m.media_duration, m.media_width, m.media_height, m.media_hash, m.thumb_image, m.media_key, m.media_digest, m.media_status, m.status, m.created_at, m."action", m.participant_id, m.snapshot_id, m.hyperlink, m.name, m.album_id, m.sticker_id, m.shared_user_id, m.media_waveform, m.quote_message_id, m.quote_content, rm.status AS resend_status, rm.user_id AS resend_user_id, rm.session_id AS resend_session_id FROM messages AS m LEFT JOIN resend_session_messages AS rm ON m.message_id = rm.message_id WHERE m.message_id = ?1 AND(m.status = \'SENDING\' OR rm.status = 1)AND m.content IS NOT NULL LIMIT 1',
        variables: [
          Variable<String>(messageId)
        ],
        readsFrom: {
          messages,
          resendSessionMessages,
        }).map((QueryRow row) => SendingMessage(
          messageId: row.read<String>('message_id'),
          conversationId: row.read<String>('conversation_id'),
          userId: row.read<String>('user_id'),
          category: row.read<String>('category'),
          content: row.readNullable<String>('content'),
          mediaUrl: row.readNullable<String>('media_url'),
          mediaMimeType: row.readNullable<String>('media_mime_type'),
          mediaSize: row.readNullable<int>('media_size'),
          mediaDuration: row.readNullable<String>('media_duration'),
          mediaWidth: row.readNullable<int>('media_width'),
          mediaHeight: row.readNullable<int>('media_height'),
          mediaHash: row.readNullable<String>('media_hash'),
          thumbImage: row.readNullable<String>('thumb_image'),
          mediaKey: row.readNullable<String>('media_key'),
          mediaDigest: row.readNullable<String>('media_digest'),
          mediaStatus: Messages.$convertermediaStatus
              .fromSql(row.readNullable<String>('media_status')),
          status: Messages.$converterstatus.fromSql(row.read<String>('status')),
          createdAt:
              Messages.$convertercreatedAt.fromSql(row.read<int>('created_at')),
          action: row.readNullable<String>('action'),
          participantId: row.readNullable<String>('participant_id'),
          snapshotId: row.readNullable<String>('snapshot_id'),
          hyperlink: row.readNullable<String>('hyperlink'),
          name: row.readNullable<String>('name'),
          albumId: row.readNullable<String>('album_id'),
          stickerId: row.readNullable<String>('sticker_id'),
          sharedUserId: row.readNullable<String>('shared_user_id'),
          mediaWaveform: row.readNullable<String>('media_waveform'),
          quoteMessageId: row.readNullable<String>('quote_message_id'),
          quoteContent: row.readNullable<String>('quote_content'),
          resendStatus: row.readNullable<int>('resend_status'),
          resendUserId: row.readNullable<String>('resend_user_id'),
          resendSessionId: row.readNullable<String>('resend_session_id'),
        ));
  }

  Selectable<NotificationMessage> notificationMessage(List<String> messageId) {
    var $arrayStartIndex = 1;
    final expandedmessageId = $expandVar($arrayStartIndex, messageId.length);
    $arrayStartIndex += messageId.length;
    return customSelect(
        'SELECT m.message_id AS messageId, m.conversation_id AS conversationId, sender.user_id AS senderId, sender.full_name AS senderFullName, m.category AS type, m.content AS content, m.quote_content AS quoteContent, m.status AS status, c.name AS groupName, c.mute_until AS muteUntil, conversationOwner.mute_until AS ownerMuteUntil, conversationOwner.user_id AS ownerUserId, conversationOwner.full_name AS ownerFullName, m.created_at AS createdAt, c.category AS category, m."action" AS actionName, conversationOwner.relationship AS relationship, pu.full_name AS participantFullName, pu.user_id AS participantUserId FROM messages AS m INNER JOIN users AS sender ON m.user_id = sender.user_id LEFT JOIN conversations AS c ON m.conversation_id = c.conversation_id LEFT JOIN users AS conversationOwner ON c.owner_id = conversationOwner.user_id LEFT JOIN message_mentions AS mm ON m.message_id = mm.message_id LEFT JOIN users AS pu ON pu.user_id = m.participant_id WHERE m.message_id IN ($expandedmessageId) ORDER BY m.created_at DESC',
        variables: [
          for (var $ in messageId) Variable<String>($)
        ],
        readsFrom: {
          messages,
          users,
          conversations,
          messageMentions,
        }).map((QueryRow row) => NotificationMessage(
          messageId: row.read<String>('messageId'),
          conversationId: row.read<String>('conversationId'),
          senderId: row.read<String>('senderId'),
          senderFullName: row.readNullable<String>('senderFullName'),
          type: row.read<String>('type'),
          content: row.readNullable<String>('content'),
          quoteContent: row.readNullable<String>('quoteContent'),
          status: Messages.$converterstatus.fromSql(row.read<String>('status')),
          groupName: row.readNullable<String>('groupName'),
          muteUntil: NullAwareTypeConverter.wrapFromSql(
              Conversations.$convertermuteUntil,
              row.readNullable<int>('muteUntil')),
          ownerMuteUntil: NullAwareTypeConverter.wrapFromSql(
              Users.$convertermuteUntil,
              row.readNullable<int>('ownerMuteUntil')),
          ownerUserId: row.readNullable<String>('ownerUserId'),
          ownerFullName: row.readNullable<String>('ownerFullName'),
          createdAt:
              Messages.$convertercreatedAt.fromSql(row.read<int>('createdAt')),
          category: Conversations.$convertercategory
              .fromSql(row.readNullable<String>('category')),
          actionName: row.readNullable<String>('actionName'),
          relationship: Users.$converterrelationship
              .fromSql(row.readNullable<String>('relationship')),
          participantFullName: row.readNullable<String>('participantFullName'),
          participantUserId: row.readNullable<String>('participantUserId'),
        ));
  }

  Selectable<SearchMessageDetailItem> searchMessageByIds(
      List<String> messageIds) {
    var $arrayStartIndex = 1;
    final expandedmessageIds = $expandVar($arrayStartIndex, messageIds.length);
    $arrayStartIndex += messageIds.length;
    return customSelect(
        'SELECT m.message_id AS messageId, u.user_id AS senderId, u.avatar_url AS senderAvatarUrl, u.full_name AS senderFullName, m.status AS status, m.category AS type, m.content AS content, m.created_at AS createdAt, m.name AS mediaName, u.app_id AS appId, u.is_verified AS verified, c.owner_id AS ownerId, c.icon_url AS groupIconUrl, c.category AS category, c.name AS groupName, c.conversation_id AS conversationId, owner.full_name AS ownerFullName, owner.avatar_url AS ownerAvatarUrl FROM messages AS m INNER JOIN conversations AS c ON c.conversation_id = m.conversation_id INNER JOIN users AS u ON m.user_id = u.user_id INNER JOIN users AS owner ON c.owner_id = owner.user_id WHERE m.message_id IN ($expandedmessageIds) ORDER BY m.created_at DESC, m."rowid" DESC',
        variables: [
          for (var $ in messageIds) Variable<String>($)
        ],
        readsFrom: {
          messages,
          users,
          conversations,
        }).map((QueryRow row) => SearchMessageDetailItem(
          messageId: row.read<String>('messageId'),
          senderId: row.read<String>('senderId'),
          senderAvatarUrl: row.readNullable<String>('senderAvatarUrl'),
          senderFullName: row.readNullable<String>('senderFullName'),
          status: Messages.$converterstatus.fromSql(row.read<String>('status')),
          type: row.read<String>('type'),
          content: row.readNullable<String>('content'),
          createdAt:
              Messages.$convertercreatedAt.fromSql(row.read<int>('createdAt')),
          mediaName: row.readNullable<String>('mediaName'),
          appId: row.readNullable<String>('appId'),
          verified: row.readNullable<bool>('verified'),
          ownerId: row.readNullable<String>('ownerId'),
          groupIconUrl: row.readNullable<String>('groupIconUrl'),
          category: Conversations.$convertercategory
              .fromSql(row.readNullable<String>('category')),
          groupName: row.readNullable<String>('groupName'),
          conversationId: row.read<String>('conversationId'),
          ownerFullName: row.readNullable<String>('ownerFullName'),
          ownerAvatarUrl: row.readNullable<String>('ownerAvatarUrl'),
        ));
  }

  Selectable<MiniMessageItem> miniMessageByIds(List<String> messageIds) {
    var $arrayStartIndex = 1;
    final expandedmessageIds = $expandVar($arrayStartIndex, messageIds.length);
    $arrayStartIndex += messageIds.length;
    return customSelect(
        'SELECT conversation_id AS conversationId, message_id AS messageId FROM messages WHERE message_id IN ($expandedmessageIds)',
        variables: [
          for (var $ in messageIds) Variable<String>($)
        ],
        readsFrom: {
          messages,
        }).map((QueryRow row) => MiniMessageItem(
          conversationId: row.read<String>('conversationId'),
          messageId: row.read<String>('messageId'),
        ));
  }

  Selectable<SearchMessageDetailItem> _searchMessage(
      SearchMessage$where where, SearchMessage$limit limit) {
    var $arrayStartIndex = 1;
    final generatedwhere = $write(
        where(alias(this.messages, 'm'), alias(this.conversations, 'c'),
            alias(this.users, 'u'), alias(this.users, 'owner')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedwhere.amountOfVariables;
    final generatedlimit = $write(
        limit(alias(this.messages, 'm'), alias(this.conversations, 'c'),
            alias(this.users, 'u'), alias(this.users, 'owner')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedlimit.amountOfVariables;
    return customSelect(
        'SELECT m.message_id AS messageId, u.user_id AS senderId, u.avatar_url AS senderAvatarUrl, u.full_name AS senderFullName, m.status AS status, m.category AS type, m.content AS content, m.created_at AS createdAt, m.name AS mediaName, u.app_id AS appId, u.is_verified AS verified, c.owner_id AS ownerId, c.icon_url AS groupIconUrl, c.category AS category, c.name AS groupName, c.conversation_id AS conversationId, owner.full_name AS ownerFullName, owner.avatar_url AS ownerAvatarUrl FROM messages AS m INNER JOIN conversations AS c ON c.conversation_id = m.conversation_id INNER JOIN users AS u ON m.user_id = u.user_id INNER JOIN users AS owner ON c.owner_id = owner.user_id WHERE ${generatedwhere.sql} ORDER BY m.created_at DESC, m."rowid" DESC ${generatedlimit.sql}',
        variables: [
          ...generatedwhere.introducedVariables,
          ...generatedlimit.introducedVariables
        ],
        readsFrom: {
          messages,
          users,
          conversations,
          ...generatedwhere.watchedTables,
          ...generatedlimit.watchedTables,
        }).map((QueryRow row) => SearchMessageDetailItem(
          messageId: row.read<String>('messageId'),
          senderId: row.read<String>('senderId'),
          senderAvatarUrl: row.readNullable<String>('senderAvatarUrl'),
          senderFullName: row.readNullable<String>('senderFullName'),
          status: Messages.$converterstatus.fromSql(row.read<String>('status')),
          type: row.read<String>('type'),
          content: row.readNullable<String>('content'),
          createdAt:
              Messages.$convertercreatedAt.fromSql(row.read<int>('createdAt')),
          mediaName: row.readNullable<String>('mediaName'),
          appId: row.readNullable<String>('appId'),
          verified: row.readNullable<bool>('verified'),
          ownerId: row.readNullable<String>('ownerId'),
          groupIconUrl: row.readNullable<String>('groupIconUrl'),
          category: Conversations.$convertercategory
              .fromSql(row.readNullable<String>('category')),
          groupName: row.readNullable<String>('groupName'),
          conversationId: row.read<String>('conversationId'),
          ownerFullName: row.readNullable<String>('ownerFullName'),
          ownerAvatarUrl: row.readNullable<String>('ownerAvatarUrl'),
        ));
  }

  Selectable<int> countMessages() {
    return customSelect('SELECT count(1) AS _c0 FROM messages',
        variables: [],
        readsFrom: {
          messages,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }

  Selectable<int> countMediaMessages() {
    return customSelect(
        'SELECT count(1) AS _c0 FROM messages WHERE category IN (\'SIGNAL_IMAGE\', \'SIGNAL_VIDEO\', \'SIGNAL_DATA\', \'SIGNAL_AUDIO\', \'PLAIN_IMAGE\', \'PLAIN_VIDEO\', \'PLAIN_DATA\', \'PLAIN_AUDIO\', \'ENCRYPTED_IMAGE\', \'ENCRYPTED_VIDEO\', \'ENCRYPTED_DATA\', \'ENCRYPTED_AUDIO\')',
        variables: [],
        readsFrom: {
          messages,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }

  Selectable<QuoteMinimal> bigQuoteMessage(int rowId, int limit) {
    return customSelect(
        'SELECT "rowid", conversation_id, quote_message_id FROM messages WHERE "rowid" > ?1 AND quote_message_id IS NOT NULL AND quote_message_id != \'\' AND length(quote_content) > 10240 GROUP BY quote_message_id ORDER BY "rowid" ASC LIMIT ?2',
        variables: [
          Variable<int>(rowId),
          Variable<int>(limit)
        ],
        readsFrom: {
          messages,
        }).map((QueryRow row) => QuoteMinimal(
          rowid: row.read<int>('rowid'),
          conversationId: row.read<String>('conversation_id'),
          quoteMessageId: row.readNullable<String>('quote_message_id'),
        ));
  }
}

class QuoteMessageItem {
  final String messageId;
  final String conversationId;
  final String userId;
  final String? userFullName;
  final String userIdentityNumber;
  final String? appId;
  final String type;
  final String? content;
  final DateTime createdAt;
  final MessageStatus status;
  final MediaStatus? mediaStatus;
  final String? mediaWaveform;
  final String? mediaName;
  final String? mediaMimeType;
  final int? mediaSize;
  final int? mediaWidth;
  final int? mediaHeight;
  final String? thumbImage;
  final String? thumbUrl;
  final String? mediaUrl;
  final String? mediaDuration;
  final String? stickerId;
  final String? assetUrl;
  final int? assetWidth;
  final int? assetHeight;
  final String? assetName;
  final String? assetType;
  final String? sharedUserId;
  final String? sharedUserFullName;
  final String? sharedUserIdentityNumber;
  final String? sharedUserAvatarUrl;
  final bool? sharedUserIsVerified;
  final String? sharedUserAppId;
  QuoteMessageItem({
    required this.messageId,
    required this.conversationId,
    required this.userId,
    this.userFullName,
    required this.userIdentityNumber,
    this.appId,
    required this.type,
    this.content,
    required this.createdAt,
    required this.status,
    this.mediaStatus,
    this.mediaWaveform,
    this.mediaName,
    this.mediaMimeType,
    this.mediaSize,
    this.mediaWidth,
    this.mediaHeight,
    this.thumbImage,
    this.thumbUrl,
    this.mediaUrl,
    this.mediaDuration,
    this.stickerId,
    this.assetUrl,
    this.assetWidth,
    this.assetHeight,
    this.assetName,
    this.assetType,
    this.sharedUserId,
    this.sharedUserFullName,
    this.sharedUserIdentityNumber,
    this.sharedUserAvatarUrl,
    this.sharedUserIsVerified,
    this.sharedUserAppId,
  });
  @override
  int get hashCode => Object.hashAll([
        messageId,
        conversationId,
        userId,
        userFullName,
        userIdentityNumber,
        appId,
        type,
        content,
        createdAt,
        status,
        mediaStatus,
        mediaWaveform,
        mediaName,
        mediaMimeType,
        mediaSize,
        mediaWidth,
        mediaHeight,
        thumbImage,
        thumbUrl,
        mediaUrl,
        mediaDuration,
        stickerId,
        assetUrl,
        assetWidth,
        assetHeight,
        assetName,
        assetType,
        sharedUserId,
        sharedUserFullName,
        sharedUserIdentityNumber,
        sharedUserAvatarUrl,
        sharedUserIsVerified,
        sharedUserAppId
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuoteMessageItem &&
          other.messageId == this.messageId &&
          other.conversationId == this.conversationId &&
          other.userId == this.userId &&
          other.userFullName == this.userFullName &&
          other.userIdentityNumber == this.userIdentityNumber &&
          other.appId == this.appId &&
          other.type == this.type &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.mediaStatus == this.mediaStatus &&
          other.mediaWaveform == this.mediaWaveform &&
          other.mediaName == this.mediaName &&
          other.mediaMimeType == this.mediaMimeType &&
          other.mediaSize == this.mediaSize &&
          other.mediaWidth == this.mediaWidth &&
          other.mediaHeight == this.mediaHeight &&
          other.thumbImage == this.thumbImage &&
          other.thumbUrl == this.thumbUrl &&
          other.mediaUrl == this.mediaUrl &&
          other.mediaDuration == this.mediaDuration &&
          other.stickerId == this.stickerId &&
          other.assetUrl == this.assetUrl &&
          other.assetWidth == this.assetWidth &&
          other.assetHeight == this.assetHeight &&
          other.assetName == this.assetName &&
          other.assetType == this.assetType &&
          other.sharedUserId == this.sharedUserId &&
          other.sharedUserFullName == this.sharedUserFullName &&
          other.sharedUserIdentityNumber == this.sharedUserIdentityNumber &&
          other.sharedUserAvatarUrl == this.sharedUserAvatarUrl &&
          other.sharedUserIsVerified == this.sharedUserIsVerified &&
          other.sharedUserAppId == this.sharedUserAppId);
  @override
  String toString() {
    return (StringBuffer('QuoteMessageItem(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('userId: $userId, ')
          ..write('userFullName: $userFullName, ')
          ..write('userIdentityNumber: $userIdentityNumber, ')
          ..write('appId: $appId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('mediaStatus: $mediaStatus, ')
          ..write('mediaWaveform: $mediaWaveform, ')
          ..write('mediaName: $mediaName, ')
          ..write('mediaMimeType: $mediaMimeType, ')
          ..write('mediaSize: $mediaSize, ')
          ..write('mediaWidth: $mediaWidth, ')
          ..write('mediaHeight: $mediaHeight, ')
          ..write('thumbImage: $thumbImage, ')
          ..write('thumbUrl: $thumbUrl, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaDuration: $mediaDuration, ')
          ..write('stickerId: $stickerId, ')
          ..write('assetUrl: $assetUrl, ')
          ..write('assetWidth: $assetWidth, ')
          ..write('assetHeight: $assetHeight, ')
          ..write('assetName: $assetName, ')
          ..write('assetType: $assetType, ')
          ..write('sharedUserId: $sharedUserId, ')
          ..write('sharedUserFullName: $sharedUserFullName, ')
          ..write('sharedUserIdentityNumber: $sharedUserIdentityNumber, ')
          ..write('sharedUserAvatarUrl: $sharedUserAvatarUrl, ')
          ..write('sharedUserIsVerified: $sharedUserIsVerified, ')
          ..write('sharedUserAppId: $sharedUserAppId')
          ..write(')'))
        .toString();
  }
}

typedef BaseQuoteMessageItem$where = Expression<bool> Function(
    Messages message,
    Users sender,
    Stickers sticker,
    Users shareUser,
    MessageMentions messageMention);
typedef BaseQuoteMessageItem$order = OrderBy Function(
    Messages message,
    Users sender,
    Stickers sticker,
    Users shareUser,
    MessageMentions messageMention);
typedef BaseQuoteMessageItem$limit = Limit Function(
    Messages message,
    Users sender,
    Stickers sticker,
    Users shareUser,
    MessageMentions messageMention);

class SendingMessage {
  final String messageId;
  final String conversationId;
  final String userId;
  final String category;
  final String? content;
  final String? mediaUrl;
  final String? mediaMimeType;
  final int? mediaSize;
  final String? mediaDuration;
  final int? mediaWidth;
  final int? mediaHeight;
  final String? mediaHash;
  final String? thumbImage;
  final String? mediaKey;
  final String? mediaDigest;
  final MediaStatus? mediaStatus;
  final MessageStatus status;
  final DateTime createdAt;
  final String? action;
  final String? participantId;
  final String? snapshotId;
  final String? hyperlink;
  final String? name;
  final String? albumId;
  final String? stickerId;
  final String? sharedUserId;
  final String? mediaWaveform;
  final String? quoteMessageId;
  final String? quoteContent;
  final int? resendStatus;
  final String? resendUserId;
  final String? resendSessionId;
  SendingMessage({
    required this.messageId,
    required this.conversationId,
    required this.userId,
    required this.category,
    this.content,
    this.mediaUrl,
    this.mediaMimeType,
    this.mediaSize,
    this.mediaDuration,
    this.mediaWidth,
    this.mediaHeight,
    this.mediaHash,
    this.thumbImage,
    this.mediaKey,
    this.mediaDigest,
    this.mediaStatus,
    required this.status,
    required this.createdAt,
    this.action,
    this.participantId,
    this.snapshotId,
    this.hyperlink,
    this.name,
    this.albumId,
    this.stickerId,
    this.sharedUserId,
    this.mediaWaveform,
    this.quoteMessageId,
    this.quoteContent,
    this.resendStatus,
    this.resendUserId,
    this.resendSessionId,
  });
  @override
  int get hashCode => Object.hashAll([
        messageId,
        conversationId,
        userId,
        category,
        content,
        mediaUrl,
        mediaMimeType,
        mediaSize,
        mediaDuration,
        mediaWidth,
        mediaHeight,
        mediaHash,
        thumbImage,
        mediaKey,
        mediaDigest,
        mediaStatus,
        status,
        createdAt,
        action,
        participantId,
        snapshotId,
        hyperlink,
        name,
        albumId,
        stickerId,
        sharedUserId,
        mediaWaveform,
        quoteMessageId,
        quoteContent,
        resendStatus,
        resendUserId,
        resendSessionId
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SendingMessage &&
          other.messageId == this.messageId &&
          other.conversationId == this.conversationId &&
          other.userId == this.userId &&
          other.category == this.category &&
          other.content == this.content &&
          other.mediaUrl == this.mediaUrl &&
          other.mediaMimeType == this.mediaMimeType &&
          other.mediaSize == this.mediaSize &&
          other.mediaDuration == this.mediaDuration &&
          other.mediaWidth == this.mediaWidth &&
          other.mediaHeight == this.mediaHeight &&
          other.mediaHash == this.mediaHash &&
          other.thumbImage == this.thumbImage &&
          other.mediaKey == this.mediaKey &&
          other.mediaDigest == this.mediaDigest &&
          other.mediaStatus == this.mediaStatus &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.action == this.action &&
          other.participantId == this.participantId &&
          other.snapshotId == this.snapshotId &&
          other.hyperlink == this.hyperlink &&
          other.name == this.name &&
          other.albumId == this.albumId &&
          other.stickerId == this.stickerId &&
          other.sharedUserId == this.sharedUserId &&
          other.mediaWaveform == this.mediaWaveform &&
          other.quoteMessageId == this.quoteMessageId &&
          other.quoteContent == this.quoteContent &&
          other.resendStatus == this.resendStatus &&
          other.resendUserId == this.resendUserId &&
          other.resendSessionId == this.resendSessionId);
  @override
  String toString() {
    return (StringBuffer('SendingMessage(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('userId: $userId, ')
          ..write('category: $category, ')
          ..write('content: $content, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaMimeType: $mediaMimeType, ')
          ..write('mediaSize: $mediaSize, ')
          ..write('mediaDuration: $mediaDuration, ')
          ..write('mediaWidth: $mediaWidth, ')
          ..write('mediaHeight: $mediaHeight, ')
          ..write('mediaHash: $mediaHash, ')
          ..write('thumbImage: $thumbImage, ')
          ..write('mediaKey: $mediaKey, ')
          ..write('mediaDigest: $mediaDigest, ')
          ..write('mediaStatus: $mediaStatus, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('action: $action, ')
          ..write('participantId: $participantId, ')
          ..write('snapshotId: $snapshotId, ')
          ..write('hyperlink: $hyperlink, ')
          ..write('name: $name, ')
          ..write('albumId: $albumId, ')
          ..write('stickerId: $stickerId, ')
          ..write('sharedUserId: $sharedUserId, ')
          ..write('mediaWaveform: $mediaWaveform, ')
          ..write('quoteMessageId: $quoteMessageId, ')
          ..write('quoteContent: $quoteContent, ')
          ..write('resendStatus: $resendStatus, ')
          ..write('resendUserId: $resendUserId, ')
          ..write('resendSessionId: $resendSessionId')
          ..write(')'))
        .toString();
  }
}

class NotificationMessage {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String? senderFullName;
  final String type;
  final String? content;
  final String? quoteContent;
  final MessageStatus status;
  final String? groupName;
  final DateTime? muteUntil;
  final DateTime? ownerMuteUntil;
  final String? ownerUserId;
  final String? ownerFullName;
  final DateTime createdAt;
  final ConversationCategory? category;
  final String? actionName;
  final UserRelationship? relationship;
  final String? participantFullName;
  final String? participantUserId;
  NotificationMessage({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    this.senderFullName,
    required this.type,
    this.content,
    this.quoteContent,
    required this.status,
    this.groupName,
    this.muteUntil,
    this.ownerMuteUntil,
    this.ownerUserId,
    this.ownerFullName,
    required this.createdAt,
    this.category,
    this.actionName,
    this.relationship,
    this.participantFullName,
    this.participantUserId,
  });
  @override
  int get hashCode => Object.hash(
      messageId,
      conversationId,
      senderId,
      senderFullName,
      type,
      content,
      quoteContent,
      status,
      groupName,
      muteUntil,
      ownerMuteUntil,
      ownerUserId,
      ownerFullName,
      createdAt,
      category,
      actionName,
      relationship,
      participantFullName,
      participantUserId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationMessage &&
          other.messageId == this.messageId &&
          other.conversationId == this.conversationId &&
          other.senderId == this.senderId &&
          other.senderFullName == this.senderFullName &&
          other.type == this.type &&
          other.content == this.content &&
          other.quoteContent == this.quoteContent &&
          other.status == this.status &&
          other.groupName == this.groupName &&
          other.muteUntil == this.muteUntil &&
          other.ownerMuteUntil == this.ownerMuteUntil &&
          other.ownerUserId == this.ownerUserId &&
          other.ownerFullName == this.ownerFullName &&
          other.createdAt == this.createdAt &&
          other.category == this.category &&
          other.actionName == this.actionName &&
          other.relationship == this.relationship &&
          other.participantFullName == this.participantFullName &&
          other.participantUserId == this.participantUserId);
  @override
  String toString() {
    return (StringBuffer('NotificationMessage(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('senderFullName: $senderFullName, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('quoteContent: $quoteContent, ')
          ..write('status: $status, ')
          ..write('groupName: $groupName, ')
          ..write('muteUntil: $muteUntil, ')
          ..write('ownerMuteUntil: $ownerMuteUntil, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('ownerFullName: $ownerFullName, ')
          ..write('createdAt: $createdAt, ')
          ..write('category: $category, ')
          ..write('actionName: $actionName, ')
          ..write('relationship: $relationship, ')
          ..write('participantFullName: $participantFullName, ')
          ..write('participantUserId: $participantUserId')
          ..write(')'))
        .toString();
  }
}

class SearchMessageDetailItem {
  final String messageId;
  final String senderId;
  final String? senderAvatarUrl;
  final String? senderFullName;
  final MessageStatus status;
  final String type;
  final String? content;
  final DateTime createdAt;
  final String? mediaName;
  final String? appId;
  final bool? verified;
  final String? ownerId;
  final String? groupIconUrl;
  final ConversationCategory? category;
  final String? groupName;
  final String conversationId;
  final String? ownerFullName;
  final String? ownerAvatarUrl;
  SearchMessageDetailItem({
    required this.messageId,
    required this.senderId,
    this.senderAvatarUrl,
    this.senderFullName,
    required this.status,
    required this.type,
    this.content,
    required this.createdAt,
    this.mediaName,
    this.appId,
    this.verified,
    this.ownerId,
    this.groupIconUrl,
    this.category,
    this.groupName,
    required this.conversationId,
    this.ownerFullName,
    this.ownerAvatarUrl,
  });
  @override
  int get hashCode => Object.hash(
      messageId,
      senderId,
      senderAvatarUrl,
      senderFullName,
      status,
      type,
      content,
      createdAt,
      mediaName,
      appId,
      verified,
      ownerId,
      groupIconUrl,
      category,
      groupName,
      conversationId,
      ownerFullName,
      ownerAvatarUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchMessageDetailItem &&
          other.messageId == this.messageId &&
          other.senderId == this.senderId &&
          other.senderAvatarUrl == this.senderAvatarUrl &&
          other.senderFullName == this.senderFullName &&
          other.status == this.status &&
          other.type == this.type &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.mediaName == this.mediaName &&
          other.appId == this.appId &&
          other.verified == this.verified &&
          other.ownerId == this.ownerId &&
          other.groupIconUrl == this.groupIconUrl &&
          other.category == this.category &&
          other.groupName == this.groupName &&
          other.conversationId == this.conversationId &&
          other.ownerFullName == this.ownerFullName &&
          other.ownerAvatarUrl == this.ownerAvatarUrl);
  @override
  String toString() {
    return (StringBuffer('SearchMessageDetailItem(')
          ..write('messageId: $messageId, ')
          ..write('senderId: $senderId, ')
          ..write('senderAvatarUrl: $senderAvatarUrl, ')
          ..write('senderFullName: $senderFullName, ')
          ..write('status: $status, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('mediaName: $mediaName, ')
          ..write('appId: $appId, ')
          ..write('verified: $verified, ')
          ..write('ownerId: $ownerId, ')
          ..write('groupIconUrl: $groupIconUrl, ')
          ..write('category: $category, ')
          ..write('groupName: $groupName, ')
          ..write('conversationId: $conversationId, ')
          ..write('ownerFullName: $ownerFullName, ')
          ..write('ownerAvatarUrl: $ownerAvatarUrl')
          ..write(')'))
        .toString();
  }
}

class MiniMessageItem {
  final String conversationId;
  final String messageId;
  MiniMessageItem({
    required this.conversationId,
    required this.messageId,
  });
  @override
  int get hashCode => Object.hash(conversationId, messageId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MiniMessageItem &&
          other.conversationId == this.conversationId &&
          other.messageId == this.messageId);
  @override
  String toString() {
    return (StringBuffer('MiniMessageItem(')
          ..write('conversationId: $conversationId, ')
          ..write('messageId: $messageId')
          ..write(')'))
        .toString();
  }
}

typedef SearchMessage$where = Expression<bool> Function(
    Messages m, Conversations c, Users u, Users owner);
typedef SearchMessage$limit = Limit Function(
    Messages m, Conversations c, Users u, Users owner);

class QuoteMinimal {
  final int rowid;
  final String conversationId;
  final String? quoteMessageId;
  QuoteMinimal({
    required this.rowid,
    required this.conversationId,
    this.quoteMessageId,
  });
  @override
  int get hashCode => Object.hash(rowid, conversationId, quoteMessageId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuoteMinimal &&
          other.rowid == this.rowid &&
          other.conversationId == this.conversationId &&
          other.quoteMessageId == this.quoteMessageId);
  @override
  String toString() {
    return (StringBuffer('QuoteMinimal(')
          ..write('rowid: $rowid, ')
          ..write('conversationId: $conversationId, ')
          ..write('quoteMessageId: $quoteMessageId')
          ..write(')'))
        .toString();
  }
}
