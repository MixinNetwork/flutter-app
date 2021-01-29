// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blaze_param.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlazeMessageParam _$BlazeMessageParamFromJson(Map<String, dynamic> json) {
  return BlazeMessageParam(
    conversationId: json['conversation_id'] as String,
    recipientId: json['recipient_id'] as String,
    messageId: json['message_id'] as String,
    category: _$enumDecodeNullable(_$MessageCategoryEnumMap, json['category']),
    data: json['data'] as String,
    status: json['status'] as String,
    recipients: (json['recipients'] as List)
        ?.map((e) => e == null
            ? null
            : BlazeMessageParamSession.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    messages: json['messages'] as List,
    quoteMessageId: json['quoteMessage_id'] as String,
    sessionId: json['session_id'] as String,
    representativeId: json['representative_id'] as String,
    conversationChecksum: json['conversation_checksum'] as String,
    mentions: (json['mentions'] as List)?.map((e) => e as String)?.toList(),
    jsep: json['jsep'] as String,
    candidate: json['candidate'] as String,
    trackId: json['track_id'] as String,
    recipientIds:
        (json['recipient_ids'] as List)?.map((e) => e as String)?.toList(),
  );
}

Map<String, dynamic> _$BlazeMessageParamToJson(BlazeMessageParam instance) =>
    <String, dynamic>{
      'conversation_id': instance.conversationId,
      'recipient_id': instance.recipientId,
      'message_id': instance.messageId,
      'category': _$MessageCategoryEnumMap[instance.category],
      'data': instance.data,
      'status': instance.status,
      'recipients': instance.recipients,
      'messages': instance.messages,
      'quoteMessage_id': instance.quoteMessageId,
      'session_id': instance.sessionId,
      'representative_id': instance.representativeId,
      'conversation_checksum': instance.conversationChecksum,
      'mentions': instance.mentions,
      'jsep': instance.jsep,
      'candidate': instance.candidate,
      'track_id': instance.trackId,
      'recipient_ids': instance.recipientIds,
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

T _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
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
