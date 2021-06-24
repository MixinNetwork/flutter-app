import 'dart:convert';

import '../../enum/message_category.dart';
import '../converter/media_status_type_converter.dart';
import '../converter/message_category_type_converter.dart';
import '../converter/message_status_type_converter.dart';
import '../converter/millis_date_converter.dart';
import '../mixin_database.dart';

extension Message on MessageItem {
  bool get isLottie => assetType?.toLowerCase() == 'json';

  bool get isSignal =>
      const MessageCategoryJsonConverter().toJson(type)!.startsWith('SIGNAL_');
}

extension QueteMessage on QuoteMessageItem {
  String toJson() => jsonEncode(<String, dynamic>{
        'message_id': messageId,
        'conversation_id': conversationId,
        'user_id': userId,
        'user_full_name': userFullName,
        'user_identity_number': userIdentityNumber,
        'app_id': appId,
        'type': const MessageCategoryTypeConverter().mapToSql(type),
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
      userId: map['user_id'],
      status: const MessageStatusTypeConverter().mapToDart(map['status'])!,
      messageId: map['message_id'],
      sharedUserIdentityNumber: map['shared_user_identity_number'],
      type: const MessageCategoryTypeConverter().mapToDart(map['type'])!,
      createdAt: const MillisDateConverter().mapToDart(map['createdAt'])!,
      conversationId: map['conversation_id'],
      userIdentityNumber: map['user_identity_number'],
      userFullName: map['user_full_name'],
      appId: map['app_id'],
      content: map['content'],
      mediaStatus:
          const MediaStatusTypeConverter().mapToDart(map['media_status']),
      mediaWaveform: map['media_waveform'],
      mediaName: map['media_name'],
      mediaMimeType: map['media_mime_type'],
      mediaSize: map['media_size'],
      mediaWidth: map['media_width'],
      mediaHeight: map['media_height'],
      thumbImage: map['thumb_image'],
      thumbUrl: map['thumb_url'],
      mediaUrl: map['media_url'],
      mediaDuration: map['media_duration'],
      quoteId: map['quote_id'],
      quoteContent: map['quote_content'],
      assetUrl: map['asset_url'],
      assetWidth: map['asset_width'],
      assetHeight: map['asset_height'],
      stickerId: map['sticker_id'],
      assetName: map['asset_name'],
      assetType: map['asset_type'],
      sharedUserId: map['shared_user_id'],
      sharedUserFullName: map['shared_user_full_name'],
      sharedUserAvatarUrl: map['shared_user_avatar_url'],
      sharedUserIsVerified: map['shared_user_is_verified'],
      sharedUserAppId: map['shared_user_app_id'],
    );
