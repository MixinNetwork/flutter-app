// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcript_message_dao.dart';

// ignore_for_file: type=lint
mixin _$TranscriptMessageDaoMixin on DatabaseAccessor<MixinDatabase> {
  TranscriptMessages get transcriptMessages =>
      attachedDatabase.transcriptMessages;
  Conversations get conversations => attachedDatabase.conversations;
  Messages get messages => attachedDatabase.messages;
  Users get users => attachedDatabase.users;
  Stickers get stickers => attachedDatabase.stickers;
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
  PinMessages get pinMessages => attachedDatabase.pinMessages;
  Fiats get fiats => attachedDatabase.fiats;
  FavoriteApps get favoriteApps => attachedDatabase.favoriteApps;
  ExpiredMessages get expiredMessages => attachedDatabase.expiredMessages;
  Chains get chains => attachedDatabase.chains;
  Properties get properties => attachedDatabase.properties;
  SafeSnapshots get safeSnapshots => attachedDatabase.safeSnapshots;
  Tokens get tokens => attachedDatabase.tokens;
  Selectable<TranscriptMessageItem> baseTranscriptMessageItem(
      BaseTranscriptMessageItem$where where,
      BaseTranscriptMessageItem$limit limit) {
    var $arrayStartIndex = 1;
    final generatedwhere = $write(
        where(
            alias(this.transcriptMessages, 'transcript'),
            alias(this.messages, 'message'),
            alias(this.users, 'sender'),
            alias(this.users, 'sharedUser'),
            alias(this.stickers, 'sticker')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedwhere.amountOfVariables;
    final generatedlimit = $write(
        limit(
            alias(this.transcriptMessages, 'transcript'),
            alias(this.messages, 'message'),
            alias(this.users, 'sender'),
            alias(this.users, 'sharedUser'),
            alias(this.stickers, 'sticker')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedlimit.amountOfVariables;
    return customSelect(
        'SELECT transcript.transcript_id AS transcriptId, transcript.message_id AS messageId, message.conversation_id AS conversationId, transcript.category AS type, transcript.content AS content, transcript.created_at AS createdAt, message.status AS status, transcript.media_status AS mediaStatus, transcript.media_waveform AS mediaWaveform, transcript.media_name AS mediaName, transcript.media_mime_type AS mediaMimeType, transcript.media_size AS mediaSize, transcript.media_width AS mediaWidth, transcript.media_height AS mediaHeight, transcript.thumb_image AS thumbImage, transcript.thumb_url AS thumbUrl, transcript.media_url AS mediaUrl, transcript.media_duration AS mediaDuration, transcript.quote_id AS quoteId, transcript.quote_content AS quoteContent, transcript.shared_user_id AS sharedUserId, sender.user_id AS userId, IFNULL(sender.full_name, transcript.user_full_name) AS userFullName, sender.identity_number AS userIdentityNumber, sender.app_id AS appId, sender.relationship AS relationship, sender.avatar_url AS avatarUrl, sharedUser.full_name AS sharedUserFullName, sharedUser.identity_number AS sharedUserIdentityNumber, sharedUser.avatar_url AS sharedUserAvatarUrl, sharedUser.is_verified AS sharedUserIsVerified, sharedUser.app_id AS sharedUserAppId, sticker.asset_url AS assetUrl, sticker.asset_width AS assetWidth, sticker.asset_height AS assetHeight, sticker.sticker_id AS stickerId, sticker.name AS assetName, sticker.asset_type AS assetType FROM transcript_messages AS transcript INNER JOIN messages AS message ON message.message_id = transcript.transcript_id LEFT JOIN users AS sender ON transcript.user_id = sender.user_id LEFT JOIN users AS sharedUser ON transcript.shared_user_id = sharedUser.user_id LEFT JOIN stickers AS sticker ON sticker.sticker_id = transcript.sticker_id WHERE ${generatedwhere.sql} ORDER BY transcript.created_at, transcript."rowid" ${generatedlimit.sql}',
        variables: [
          ...generatedwhere.introducedVariables,
          ...generatedlimit.introducedVariables
        ],
        readsFrom: {
          transcriptMessages,
          messages,
          users,
          stickers,
          ...generatedwhere.watchedTables,
          ...generatedlimit.watchedTables,
        }).map((QueryRow row) => TranscriptMessageItem(
          transcriptId: row.read<String>('transcriptId'),
          messageId: row.read<String>('messageId'),
          conversationId: row.read<String>('conversationId'),
          type: row.read<String>('type'),
          content: row.readNullable<String>('content'),
          createdAt: TranscriptMessages.$convertercreatedAt
              .fromSql(row.read<int>('createdAt')),
          status: Messages.$converterstatus.fromSql(row.read<String>('status')),
          mediaStatus: TranscriptMessages.$convertermediaStatus
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
          quoteId: row.readNullable<String>('quoteId'),
          quoteContent: row.readNullable<String>('quoteContent'),
          sharedUserId: row.readNullable<String>('sharedUserId'),
          userId: row.readNullable<String>('userId'),
          userFullName: row.readNullable<String>('userFullName'),
          userIdentityNumber: row.readNullable<String>('userIdentityNumber'),
          appId: row.readNullable<String>('appId'),
          relationship: Users.$converterrelationship
              .fromSql(row.readNullable<String>('relationship')),
          avatarUrl: row.readNullable<String>('avatarUrl'),
          sharedUserFullName: row.readNullable<String>('sharedUserFullName'),
          sharedUserIdentityNumber:
              row.readNullable<String>('sharedUserIdentityNumber'),
          sharedUserAvatarUrl: row.readNullable<String>('sharedUserAvatarUrl'),
          sharedUserIsVerified: row.readNullable<bool>('sharedUserIsVerified'),
          sharedUserAppId: row.readNullable<String>('sharedUserAppId'),
          assetUrl: row.readNullable<String>('assetUrl'),
          assetWidth: row.readNullable<int>('assetWidth'),
          assetHeight: row.readNullable<int>('assetHeight'),
          stickerId: row.readNullable<String>('stickerId'),
          assetName: row.readNullable<String>('assetName'),
          assetType: row.readNullable<String>('assetType'),
        ));
  }

  Selectable<int> countTranscriptMessages() {
    return customSelect('SELECT COUNT(1) AS _c0 FROM transcript_messages',
        variables: [],
        readsFrom: {
          transcriptMessages,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }
}

class TranscriptMessageItem {
  final String transcriptId;
  final String messageId;
  final String conversationId;
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
  final String? quoteId;
  final String? quoteContent;
  final String? sharedUserId;
  final String? userId;
  final String? userFullName;
  final String? userIdentityNumber;
  final String? appId;
  final UserRelationship? relationship;
  final String? avatarUrl;
  final String? sharedUserFullName;
  final String? sharedUserIdentityNumber;
  final String? sharedUserAvatarUrl;
  final bool? sharedUserIsVerified;
  final String? sharedUserAppId;
  final String? assetUrl;
  final int? assetWidth;
  final int? assetHeight;
  final String? stickerId;
  final String? assetName;
  final String? assetType;
  TranscriptMessageItem({
    required this.transcriptId,
    required this.messageId,
    required this.conversationId,
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
    this.quoteId,
    this.quoteContent,
    this.sharedUserId,
    this.userId,
    this.userFullName,
    this.userIdentityNumber,
    this.appId,
    this.relationship,
    this.avatarUrl,
    this.sharedUserFullName,
    this.sharedUserIdentityNumber,
    this.sharedUserAvatarUrl,
    this.sharedUserIsVerified,
    this.sharedUserAppId,
    this.assetUrl,
    this.assetWidth,
    this.assetHeight,
    this.stickerId,
    this.assetName,
    this.assetType,
  });
  @override
  int get hashCode => Object.hashAll([
        transcriptId,
        messageId,
        conversationId,
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
        quoteId,
        quoteContent,
        sharedUserId,
        userId,
        userFullName,
        userIdentityNumber,
        appId,
        relationship,
        avatarUrl,
        sharedUserFullName,
        sharedUserIdentityNumber,
        sharedUserAvatarUrl,
        sharedUserIsVerified,
        sharedUserAppId,
        assetUrl,
        assetWidth,
        assetHeight,
        stickerId,
        assetName,
        assetType
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TranscriptMessageItem &&
          other.transcriptId == this.transcriptId &&
          other.messageId == this.messageId &&
          other.conversationId == this.conversationId &&
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
          other.quoteId == this.quoteId &&
          other.quoteContent == this.quoteContent &&
          other.sharedUserId == this.sharedUserId &&
          other.userId == this.userId &&
          other.userFullName == this.userFullName &&
          other.userIdentityNumber == this.userIdentityNumber &&
          other.appId == this.appId &&
          other.relationship == this.relationship &&
          other.avatarUrl == this.avatarUrl &&
          other.sharedUserFullName == this.sharedUserFullName &&
          other.sharedUserIdentityNumber == this.sharedUserIdentityNumber &&
          other.sharedUserAvatarUrl == this.sharedUserAvatarUrl &&
          other.sharedUserIsVerified == this.sharedUserIsVerified &&
          other.sharedUserAppId == this.sharedUserAppId &&
          other.assetUrl == this.assetUrl &&
          other.assetWidth == this.assetWidth &&
          other.assetHeight == this.assetHeight &&
          other.stickerId == this.stickerId &&
          other.assetName == this.assetName &&
          other.assetType == this.assetType);
  @override
  String toString() {
    return (StringBuffer('TranscriptMessageItem(')
          ..write('transcriptId: $transcriptId, ')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
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
          ..write('quoteId: $quoteId, ')
          ..write('quoteContent: $quoteContent, ')
          ..write('sharedUserId: $sharedUserId, ')
          ..write('userId: $userId, ')
          ..write('userFullName: $userFullName, ')
          ..write('userIdentityNumber: $userIdentityNumber, ')
          ..write('appId: $appId, ')
          ..write('relationship: $relationship, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('sharedUserFullName: $sharedUserFullName, ')
          ..write('sharedUserIdentityNumber: $sharedUserIdentityNumber, ')
          ..write('sharedUserAvatarUrl: $sharedUserAvatarUrl, ')
          ..write('sharedUserIsVerified: $sharedUserIsVerified, ')
          ..write('sharedUserAppId: $sharedUserAppId, ')
          ..write('assetUrl: $assetUrl, ')
          ..write('assetWidth: $assetWidth, ')
          ..write('assetHeight: $assetHeight, ')
          ..write('stickerId: $stickerId, ')
          ..write('assetName: $assetName, ')
          ..write('assetType: $assetType')
          ..write(')'))
        .toString();
  }
}

typedef BaseTranscriptMessageItem$where = Expression<bool> Function(
    TranscriptMessages transcript,
    Messages message,
    Users sender,
    Users sharedUser,
    Stickers sticker);
typedef BaseTranscriptMessageItem$limit = Limit Function(
    TranscriptMessages transcript,
    Messages message,
    Users sender,
    Users sharedUser,
    Stickers sticker);
