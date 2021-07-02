import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

enum MessageCategory {
  signalKey,
  signalText,
  signalImage,
  signalVideo,
  signalSticker,
  signalData,
  signalContact,
  signalAudio,
  signalLive,
  signalPost,
  signalLocation,
  signalTranscript,
  plainText,
  plainImage,
  plainVideo,
  plainData,
  plainSticker,
  plainContact,
  plainAudio,
  plainLive,
  plainPost,
  plainJson,
  plainLocation,
  plainTranscript,
  messageRecall,
  stranger,
  secret,
  systemConversation,
  systemUser,
  systemCircle,
  systemSession,
  systemAccountSnapshot,
  appButtonGroup,
  appCard,
  webrtcAudioOffer,
  webrtcAudioAnswer,
  webrtcIceCandidate,
  webrtcAudioCancel,
  webrtcAudioDecline,
  webrtcAudioEnd,
  webrtcAudioBusy,
  webrtcAudioFailed,
  krakenInvite,
  krakenPublish,
  krakenSubscribe,
  krakenAnswer,
  krakenTrickle,
  krakenEnd,
  krakenCancel,
  krakenDecline,
  krakenList,
  krakenRestart,
  encryptedText,
  encryptedImage,
  encryptedVideo,
  encryptedSticker,
  encryptedData,
  encryptedContact,
  encryptedAudio,
  encryptedLive,
  encryptedPost,
  encryptedLocation,
  encryptedTranscript,
  unknown,
}

class MessageCategoryJsonConverter extends EnumJsonConverter<MessageCategory> {
  const MessageCategoryJsonConverter();
  @override
  List<MessageCategory> enumValues() => MessageCategory.values;

  @override
  String get unknownJson => MessageCategory.unknown.toString().toUpperCase();

  @override
  MessageCategory get unknownEnumValue => MessageCategory.unknown;
}
