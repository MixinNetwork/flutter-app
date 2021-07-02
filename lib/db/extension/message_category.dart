import '../../enum/message_category.dart';

extension MessageCategoryExtension on MessageCategory? {
  bool get isPlain => {
        MessageCategory.plainText,
        MessageCategory.plainImage,
        MessageCategory.plainVideo,
        MessageCategory.plainData,
        MessageCategory.plainSticker,
        MessageCategory.plainContact,
        MessageCategory.plainAudio,
        MessageCategory.plainLive,
        MessageCategory.plainPost,
        MessageCategory.plainJson,
        MessageCategory.plainLocation,
        MessageCategory.plainTranscript,
      }.any((element) => element == this);

  bool get isSystem => {
        MessageCategory.systemAccountSnapshot,
        MessageCategory.systemCircle,
        MessageCategory.systemConversation,
        MessageCategory.systemSession,
        MessageCategory.systemUser,
      }.any((element) => element == this);

  bool get isEncrypted => {
        MessageCategory.encryptedText,
        MessageCategory.encryptedImage,
        MessageCategory.encryptedVideo,
        MessageCategory.encryptedSticker,
        MessageCategory.encryptedData,
        MessageCategory.encryptedContact,
        MessageCategory.encryptedAudio,
        MessageCategory.encryptedLive,
        MessageCategory.encryptedPost,
        MessageCategory.encryptedLocation,
        MessageCategory.encryptedTranscript,
      }.any((element) => element == this);

  bool get isSignal => {
        MessageCategory.signalKey,
        MessageCategory.signalText,
        MessageCategory.signalImage,
        MessageCategory.signalVideo,
        MessageCategory.signalSticker,
        MessageCategory.signalData,
        MessageCategory.signalContact,
        MessageCategory.signalAudio,
        MessageCategory.signalLive,
        MessageCategory.signalPost,
        MessageCategory.signalLocation,
        MessageCategory.signalTranscript,
      }.any((element) => element == this);

  bool get isCall => {
        MessageCategory.webrtcAudioOffer,
        MessageCategory.webrtcAudioAnswer,
        MessageCategory.webrtcIceCandidate,
        MessageCategory.webrtcAudioCancel,
        MessageCategory.webrtcAudioDecline,
        MessageCategory.webrtcAudioEnd,
        MessageCategory.webrtcAudioBusy,
        MessageCategory.webrtcAudioFailed,
        MessageCategory.krakenInvite,
        MessageCategory.krakenPublish,
        MessageCategory.krakenSubscribe,
        MessageCategory.krakenAnswer,
        MessageCategory.krakenTrickle,
        MessageCategory.krakenEnd,
        MessageCategory.krakenCancel,
        MessageCategory.krakenDecline,
        MessageCategory.krakenList,
        MessageCategory.krakenRestart,
      }.any((element) => element == this);

  bool get isKraken => {
        MessageCategory.krakenInvite,
        MessageCategory.krakenPublish,
        MessageCategory.krakenSubscribe,
        MessageCategory.krakenAnswer,
        MessageCategory.krakenTrickle,
        MessageCategory.krakenEnd,
        MessageCategory.krakenCancel,
        MessageCategory.krakenDecline,
        MessageCategory.krakenList,
        MessageCategory.krakenRestart,
      }.any((element) => element == this);

  bool get isRecall => this == MessageCategory.messageRecall;

  bool get isFtsMessage => {
        MessageCategory.signalText,
        MessageCategory.plainText,
        MessageCategory.encryptedText,
        MessageCategory.signalData,
        MessageCategory.plainData,
        MessageCategory.encryptedData,
        MessageCategory.signalPost,
        MessageCategory.plainPost,
        MessageCategory.encryptedPost,
      }.any((element) => element == this);

  bool get isText => {
        MessageCategory.signalText,
        MessageCategory.plainText,
        MessageCategory.encryptedText,
      }.any((element) => element == this);

  bool get isLive => {
        MessageCategory.signalLive,
        MessageCategory.plainLive,
        MessageCategory.encryptedLive
      }.any((element) => element == this);

  bool get isImage => {
        MessageCategory.signalImage,
        MessageCategory.plainImage,
        MessageCategory.encryptedImage,
      }.any((element) => element == this);

  bool get isVideo => {
        MessageCategory.signalVideo,
        MessageCategory.plainVideo,
        MessageCategory.encryptedVideo,
      }.any((element) => element == this);

  bool get isSticker => {
        MessageCategory.signalSticker,
        MessageCategory.plainSticker,
        MessageCategory.encryptedSticker,
      }.any((element) => element == this);

  bool get isPost => {
        MessageCategory.signalPost,
        MessageCategory.plainPost,
        MessageCategory.encryptedPost,
      }.any((element) => element == this);

  bool get isAudio => {
        MessageCategory.signalAudio,
        MessageCategory.plainAudio,
        MessageCategory.encryptedAudio,
      }.any((element) => element == this);

  bool get isData => {
        MessageCategory.signalData,
        MessageCategory.plainData,
        MessageCategory.encryptedData,
      }.any((element) => element == this);

  bool get isLocation => {
        MessageCategory.signalLocation,
        MessageCategory.plainLocation,
        MessageCategory.encryptedLocation,
      }.any((element) => element == this);

  bool get isContact => {
        MessageCategory.signalContact,
        MessageCategory.plainContact,
        MessageCategory.encryptedContact,
      }.any((element) => element == this);

  bool get isTranscript => {
        MessageCategory.signalTranscript,
        MessageCategory.plainTranscript,
        MessageCategory.encryptedTranscript,
      }.any((element) => element == this);

  bool get isMedia => isData || isImage || isVideo;

  bool get isAttachment => isData || isImage || isVideo || isAudio;

  bool get isGroupCall => {
        MessageCategory.krakenEnd,
        MessageCategory.krakenDecline,
        MessageCategory.krakenCancel,
        MessageCategory.krakenInvite,
      }.any((element) => element == this);

  bool get isCallMessage => {
        MessageCategory.webrtcAudioCancel,
        MessageCategory.webrtcAudioDecline,
        MessageCategory.webrtcAudioEnd,
        MessageCategory.webrtcAudioBusy,
        MessageCategory.webrtcAudioFailed,
      }.any((element) => element == this);

  bool get canRecall => {
        MessageCategory.signalText,
        MessageCategory.signalImage,
        MessageCategory.signalVideo,
        MessageCategory.signalSticker,
        MessageCategory.signalData,
        MessageCategory.signalContact,
        MessageCategory.signalAudio,
        MessageCategory.signalLive,
        MessageCategory.signalPost,
        MessageCategory.signalLocation,
        MessageCategory.signalTranscript,
        MessageCategory.plainText,
        MessageCategory.plainImage,
        MessageCategory.plainVideo,
        MessageCategory.plainSticker,
        MessageCategory.plainData,
        MessageCategory.plainContact,
        MessageCategory.plainAudio,
        MessageCategory.plainLive,
        MessageCategory.plainPost,
        MessageCategory.plainLocation,
        MessageCategory.plainTranscript,
        MessageCategory.appCard,
      }.any((element) => element == this);

  bool get notSupportedYet => isAudio || isTranscript;
}
