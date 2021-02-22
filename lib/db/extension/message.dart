import 'dart:convert';

import 'package:flutter_app/db/converter/media_status_type_converter.dart';
import 'package:flutter_app/db/converter/message_category_type_converter.dart';
import 'package:flutter_app/db/converter/message_status_type_converter.dart';
import 'package:flutter_app/db/converter/millis_date_converter.dart';
import 'package:flutter_app/db/mixin_database.dart';

extension Message on MessageItem {
  bool get isLottie => assetType?.toLowerCase() == 'json';
}

extension QueteMessage on QuoteMessageItem{

  String toJson() {
    return jsonEncode(<String, dynamic>{
    'message_id': messageId,
    'conversation_id': conversationId,
    'user_id': userId,
    'user_full_name': userFullName,
    'user_identity_number': userIdentityNumber,
    'app_id': appId,
    'type':const MessageCategoryTypeConverter().mapToSql(type),
    'content': content,
    'createdAt':const MillisDateConverter().mapToSql(createdAt),
    'status':const MessageStatusTypeConverter().mapToSql(status),
    'media_status' :const MediaStatusTypeConverter().mapToSql( mediaStatus),
    'media_waveform': mediaWaveform,
    'media_name': mediaName,
    'media_mime_type': mediaMimeType,
    'media_size' :mediaSize,
    'media_width' :mediaWidth,
    'media_height' :mediaHeight,
    'thumb_image': thumbImage,
    'thumb_url': thumbUrl,
    'media_url': mediaUrl,
    'media_duration': mediaDuration,
    'quote_id': quoteId,
    'quote_content': quoteContent,
    'asset_url': assetUrl,
    'asset_width': assetWidth,
    'asset_height':assetHeight,
    'sticker_id': stickerId,
    'asset_name': assetName,
    'asset_type': assetType,
    'shared_user_id': sharedUserId,
    'shared_user_full_name': sharedUserFullName,
    'shared_user_identity_number': sharedUserIdentityNumber,
    'shared_user_avatar_url': sharedUserAvatarUrl,
    'shared_user_is_verified':sharedUserIsVerified,
    'shared_user_app_id': sharedUserAppId,
    'mentions': mentions,
    });
  }
}