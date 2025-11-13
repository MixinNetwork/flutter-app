import 'dart:convert';

import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../enum/media_status.dart';
import '../../enum/message_category.dart';
import '../../utils/logger.dart';
import '../../widgets/message/item/action_card/action_card_data.dart';
import '../../widgets/message/send_message_dialog/attachment_extra.dart';
import '../converter/media_status_type_converter.dart';
import '../converter/message_status_type_converter.dart';
import '../converter/millis_date_converter.dart';
import '../dao/message_dao.dart';
import '../mixin_database.dart';
import 'message_category.dart';
import 'user.dart';

extension MessageItemExtension on MessageItem {
  bool get isLottie => assetType?.toLowerCase() == 'json';

  bool get isSignal => type.startsWith('SIGNAL_');

  bool get isEncrypted => type.startsWith('ENCRYPTED_');

  bool get isSecret => isSignal || isEncrypted;

  bool get isBot => UserExtension.isBotIdentityNumber(userIdentityNumber);

  bool _isFinishedAttachment() =>
      (type.isImage || type.isVideo || type.isAudio || type.isData) &&
      (mediaStatus == MediaStatus.done || mediaStatus == MediaStatus.read);

  bool get canForward {
    if (!const [
      MessageStatus.delivered,
      MessageStatus.read,
      MessageStatus.sent,
    ].contains(status)) {
      return false;
    }

    if (type == MessageCategory.appCard) {
      try {
        return AppCardData.fromJson(
          jsonDecode(content!) as Map<String, dynamic>,
        ).shareable;
      } catch (e) {
        w('AppCardData.fromJson error: $e');
      }
    }

    if (type.isAudio && mediaStatus == MediaStatus.done) {
      try {
        return AttachmentExtra.fromJson(
              jsonDecode(content!) as Map<String, dynamic>,
            ).shareable ??
            true;
      } catch (e) {
        d('AttachmentExtra.fromJson error: $e');
      }
    }

    return type.isText ||
        _isFinishedAttachment() ||
        type.isSticker ||
        type.isContact ||
        type.isLive ||
        type.isPost ||
        type.isLocation ||
        (type.isTranscript && mediaStatus == MediaStatus.done);
  }

  bool get canRecall =>
      [
        MessageStatus.sent,
        MessageStatus.delivered,
        MessageStatus.read,
      ].contains(status) &&
      relationship == UserRelationship.me &&
      type.canRecall &&
      DateTime.now().isBefore(createdAt.add(const Duration(minutes: 60)));
}

extension QuoteMessageItemExtension on QuoteMessageItem {
  String toJson() => jsonEncode(<String, dynamic>{
    'message_id': messageId,
    'conversation_id': conversationId,
    'user_id': userId,
    'user_full_name': userFullName,
    'user_identity_number': userIdentityNumber,
    'app_id': appId,
    'type': type,
    'content': content,
    'createdAt': const MillisDateConverter().toSql(createdAt),
    'status': const MessageStatusTypeConverter().toSql(status),
    'media_status': const MediaStatusTypeConverter().toSql(mediaStatus),
    'media_waveform': mediaWaveform,
    'media_name': mediaName,
    'media_mime_type': mediaMimeType,
    'media_size': mediaSize,
    'media_width': mediaWidth,
    'media_height': mediaHeight,
    'thumb_image': thumbImage,
    'thumb_url': thumbUrl,
    'media_url': mediaUrl,
    'media_duration': mediaDuration,
    'asset_url': assetUrl,
    'asset_width': assetWidth,
    'asset_height': assetHeight,
    'sticker_id': stickerId,
    'asset_name': assetName,
    'asset_type': assetType,
    'shared_user_id': sharedUserId,
    'shared_user_full_name': sharedUserFullName,
    'shared_user_identity_number': sharedUserIdentityNumber,
    'shared_user_avatar_url': sharedUserAvatarUrl,
    'shared_user_is_verified': sharedUserIsVerified,
    'shared_user_app_id': sharedUserAppId,
  });
}

QuoteMessageItem mapToQuoteMessage(Map<String, dynamic> map) {
  final createdAtJson = map['created_at'] ?? map['createdAt'];
  final createdAt = createdAtJson is String
      ? DateTime.parse(createdAtJson)
      : const MillisDateConverter().fromSql(createdAtJson as int);
  return QuoteMessageItem(
    userId: map['user_id'] as String,
    status: const MessageStatusTypeConverter().fromSql(map['status'] as String),
    messageId: map['message_id'] as String,
    sharedUserIdentityNumber: map['shared_user_identity_number'] as String?,
    type: map['type'] as String,
    createdAt: createdAt,
    conversationId: map['conversation_id'] as String,
    userIdentityNumber: map['user_identity_number'] as String,
    userFullName: map['user_full_name'] as String?,
    appId: map['app_id'] as String?,
    content: map['content'] as String?,
    mediaStatus: const MediaStatusTypeConverter().fromSql(
      map['media_status'] as String?,
    ),
    mediaWaveform: map['media_waveform'] as String?,
    mediaName: map['media_name'] as String?,
    mediaMimeType: map['media_mime_type'] as String?,
    mediaSize: map['media_size'] as int?,
    mediaWidth: map['media_width'] as int?,
    mediaHeight: map['media_height'] as int?,
    thumbImage: map['thumb_image'] as String?,
    thumbUrl: map['thumb_url'] as String?,
    mediaUrl: map['media_url'] as String?,
    mediaDuration: map['media_duration'] as String?,
    assetUrl: map['asset_url'] as String?,
    assetWidth: map['asset_width'] as int?,
    assetHeight: map['asset_height'] as int?,
    stickerId: map['sticker_id'] as String?,
    assetName: map['asset_name'] as String?,
    assetType: map['asset_type'] as String?,
    sharedUserId: map['shared_user_id'] as String?,
    sharedUserFullName: map['shared_user_full_name'] as String?,
    sharedUserAvatarUrl: map['shared_user_avatar_url'] as String?,
    sharedUserIsVerified: map['shared_user_is_verified'] as bool?,
    sharedUserAppId: map['shared_user_app_id'] as String?,
  );
}

extension SendingMessageCopy on SendingMessage {
  SendingMessage copyWith({
    String? messageId,
    String? conversationId,
    String? userId,
    String? category,
    String? content,
    String? mediaUrl,
    String? mediaMimeType,
    int? mediaSize,
    String? mediaDuration,
    int? mediaWidth,
    int? mediaHeight,
    String? mediaHash,
    String? thumbImage,
    String? mediaKey,
    String? mediaDigest,
    MediaStatus? mediaStatus,
    MessageStatus? status,
    DateTime? createdAt,
    String? action,
    String? participantId,
    String? snapshotId,
    String? hyperlink,
    String? name,
    String? albumId,
    String? stickerId,
    String? sharedUserId,
    String? mediaWaveform,
    String? quoteMessageId,
    String? quoteContent,
    int? resendStatus,
    String? resendUserId,
    String? resendSessionId,
    String? caption,
  }) => SendingMessage(
    messageId: messageId ?? this.messageId,
    conversationId: conversationId ?? this.conversationId,
    userId: userId ?? this.userId,
    category: category ?? this.category,
    content: content ?? this.content,
    mediaUrl: mediaUrl ?? this.mediaUrl,
    mediaMimeType: mediaMimeType ?? this.mediaMimeType,
    mediaSize: mediaSize ?? this.mediaSize,
    mediaDuration: mediaDuration ?? this.mediaDuration,
    mediaWidth: mediaWidth ?? this.mediaWidth,
    mediaHeight: mediaHeight ?? this.mediaHeight,
    mediaHash: mediaHash ?? this.mediaHash,
    thumbImage: thumbImage ?? this.thumbImage,
    mediaKey: mediaKey ?? this.mediaKey,
    mediaDigest: mediaDigest ?? this.mediaDigest,
    mediaStatus: mediaStatus ?? this.mediaStatus,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    action: action ?? this.action,
    participantId: participantId ?? this.participantId,
    snapshotId: snapshotId ?? this.snapshotId,
    hyperlink: hyperlink ?? this.hyperlink,
    name: name ?? this.name,
    albumId: albumId ?? this.albumId,
    stickerId: stickerId ?? this.stickerId,
    sharedUserId: sharedUserId ?? this.sharedUserId,
    mediaWaveform: mediaWaveform ?? this.mediaWaveform,
    quoteMessageId: quoteMessageId ?? this.quoteMessageId,
    quoteContent: quoteContent ?? this.quoteContent,
    resendStatus: resendStatus ?? this.resendStatus,
    resendUserId: resendUserId ?? this.resendUserId,
    resendSessionId: resendSessionId ?? this.resendSessionId,
    caption: caption ?? this.caption,
  );
}
