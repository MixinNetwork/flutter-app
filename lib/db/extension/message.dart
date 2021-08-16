import 'dart:convert';

import '../converter/media_status_type_converter.dart';
import '../converter/message_status_type_converter.dart';
import '../converter/millis_date_converter.dart';
import '../mixin_database.dart';

extension MessageItemExtension on MessageItem {
  bool get isLottie => assetType?.toLowerCase() == 'json';

  bool get isSignal => type.startsWith('SIGNAL_');
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
        'createdAt': const MillisDateConverter().mapToSql(createdAt),
        'status': const MessageStatusTypeConverter().mapToSql(status),
        'media_status': const MediaStatusTypeConverter().mapToSql(mediaStatus),
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
        'quote_id': quoteId,
        'quote_content': quoteContent,
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

QuoteMessageItem mapToQuoteMessage(Map<String, dynamic> map) =>
    QuoteMessageItem(
      userId: map['user_id'] as String,
      status: const MessageStatusTypeConverter()
          .mapToDart(map['status'] as String?)!,
      messageId: map['message_id'] as String,
      sharedUserIdentityNumber: map['shared_user_identity_number'] as String?,
      type: map['type'] as String,
      createdAt:
          const MillisDateConverter().mapToDart(map['createdAt'] as int?)!,
      conversationId: map['conversation_id'] as String,
      userIdentityNumber: map['user_identity_number'] as String,
      userFullName: map['user_full_name'] as String?,
      appId: map['app_id'] as String?,
      content: map['content'] as String?,
      mediaStatus: const MediaStatusTypeConverter()
          .mapToDart(map['media_status'] as String?),
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
      quoteId: map['quote_id'] as String?,
      quoteContent: map['quote_content'] as String?,
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
