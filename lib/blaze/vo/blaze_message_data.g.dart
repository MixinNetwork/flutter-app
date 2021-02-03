// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blaze_message_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlazeMessageData _$BlazeMessageDataFromJson(Map<String, dynamic> json) {
  return BlazeMessageData(
    json['conversation_id'] as String,
    json['user_id'] as String,
    json['message_id'] as String,
    _$enumDecode(_$MessageCategoryEnumMap, json['category']),
    json['data'] as String,
    _$enumDecode(_$MessageStatusEnumMap, json['status']),
    DateTime.parse(json['created_at'] as String),
    DateTime.parse(json['updated_at'] as String),
    json['source'] as String,
    json['representative_id'] as String,
    json['quote_message_id'] as String,
    json['session_id'] as String,
  );
}

Map<String, dynamic> _$BlazeMessageDataToJson(BlazeMessageData instance) =>
    <String, dynamic>{
      'conversation_id': instance.conversationId,
      'user_id': instance.userId,
      'message_id': instance.messageId,
      'category': _$MessageCategoryEnumMap[instance.category],
      'data': instance.data,
      'status': _$MessageStatusEnumMap[instance.status],
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'source': instance.source,
      'representative_id': instance.representativeId,
      'quote_message_id': instance.quoteMessageId,
      'session_id': instance.sessionId,
    };

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

const _$MessageCategoryEnumMap = {
  MessageCategory.signalKey: 'SIGNAL_KEY',
  MessageCategory.signalText: 'SIGNAL_TEXT',
  MessageCategory.signalImage: 'SIGNAL_IMAGE',
  MessageCategory.signalVideo: 'SIGNAL_VIDEO',
  MessageCategory.signalSticker: 'SIGNAL_STICKER',
  MessageCategory.signalData: 'SIGNAL_DATA',
  MessageCategory.signalContact: 'SIGNAL_CONTACT',
  MessageCategory.signalAudio: 'SIGNAL_AUDIO',
  MessageCategory.signalLive: 'SIGNAL_LIVE',
  MessageCategory.signalPost: 'SIGNAL_POST',
  MessageCategory.signalLocation: 'SIGNAL_LOCATION',
  MessageCategory.plainText: 'PLAIN_TEXT',
  MessageCategory.plainImage: 'PLAIN_IMAGE',
  MessageCategory.plainVideo: 'PLAIN_VIDEO',
  MessageCategory.plainData: 'PLAIN_DATA',
  MessageCategory.plainSticker: 'PLAIN_STICKER',
  MessageCategory.plainContact: 'PLAIN_CONTACT',
  MessageCategory.plainAudio: 'PLAIN_AUDIO',
  MessageCategory.plainLive: 'PLAIN_LIVE',
  MessageCategory.plainPost: 'PLAIN_POST',
  MessageCategory.plainJson: 'PLAIN_JSON',
  MessageCategory.plainLocation: 'PLAIN_LOCATION',
  MessageCategory.messageRecall: 'MESSAGE_RECALL',
  MessageCategory.stranger: 'STRANGER',
  MessageCategory.secret: 'SECRET',
  MessageCategory.systemConversation: 'SYSTEM_CONVERSATION',
  MessageCategory.systemUser: 'SYSTEM_USER',
  MessageCategory.systemCircle: 'SYSTEM_CIRCLE',
  MessageCategory.systemSession: 'SYSTEM_SESSION',
  MessageCategory.systemAccountSnapshot: 'SYSTEM_ACCOUNT_SNAPSHOT',
  MessageCategory.appButtonGroup: 'APP_BUTTON_GROUP',
  MessageCategory.appCard: 'APP_CARD',
  MessageCategory.webrtcAudioOffer: 'WEBRTC_AUDIO_OFFER',
  MessageCategory.webrtcAudioAnswer: 'WEBRTC_AUDIO_ANSWER',
  MessageCategory.webrtcIceCandidate: 'WEBRTC_ICE_CANDIDATE',
  MessageCategory.webrtcAudioCancel: 'WEBRTC_AUDIO_CANCEL',
  MessageCategory.webrtcAudioDecline: 'WEBRTC_AUDIO_DECLINE',
  MessageCategory.webrtcAudioEnd: 'WEBRTC_AUDIO_END',
  MessageCategory.webrtcAudioBusy: 'WEBRTC_AUDIO_BUSY',
  MessageCategory.webrtcAudioFailed: 'WEBRTC_AUDIO_FAILED',
  MessageCategory.krakenInvite: 'KRAKEN_INVITE',
  MessageCategory.krakenPublish: 'KRAKEN_PUBLISH',
  MessageCategory.krakenSubscribe: 'KRAKEN_SUBSCRIBE',
  MessageCategory.krakenAnswer: 'KRAKEN_ANSWER',
  MessageCategory.krakenTrickle: 'KRAKEN_TRICKLE',
  MessageCategory.krakenEnd: 'KRAKEN_END',
  MessageCategory.krakenCancel: 'KRAKEN_CANCEL',
  MessageCategory.krakenDecline: 'KRAKEN_DECLINE',
  MessageCategory.krakenList: 'KRAKEN_LIST',
  MessageCategory.krakenRestart: 'KRAKEN_RESTART',
  MessageCategory.encryptedText: 'ENCRYPTED_TEXT',
  MessageCategory.encryptedImage: 'ENCRYPTED_IMAGE',
  MessageCategory.encryptedVideo: 'ENCRYPTED_VIDEO',
  MessageCategory.encryptedSticker: 'ENCRYPTED_STICKER',
  MessageCategory.encryptedData: 'ENCRYPTED_DATA',
  MessageCategory.encryptedContact: 'ENCRYPTED_CONTACT',
  MessageCategory.encryptedAudio: 'ENCRYPTED_AUDIO',
  MessageCategory.encryptedLive: 'ENCRYPTED_LIVE',
  MessageCategory.encryptedPost: 'ENCRYPTED_POST',
  MessageCategory.encryptedLocation: 'ENCRYPTED_LOCATION',
};

const _$MessageStatusEnumMap = {
  MessageStatus.sending: 'SENDING',
  MessageStatus.sent: 'SENT',
  MessageStatus.delivered: 'DELIVERED',
  MessageStatus.read: 'READ',
  MessageStatus.failed: 'FAILED',
  MessageStatus.unknown: 'UNKNOWN',
};
