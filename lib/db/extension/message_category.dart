import '../../enum/encrypt_category.dart';
import '../../enum/message_category.dart';

extension MessageCategoryExtension on String? {
  EncryptCategory? get encryptCategory {
    if (isPlain) return EncryptCategory.plain;
    if (isSignal) return EncryptCategory.signal;
    if (isEncrypted) return EncryptCategory.encrypted;
    return null;
  }

  bool get isPlain => this?.startsWith('PLAIN_') ?? false;

  bool get isSystem => this?.startsWith('SYSTEM_') ?? false;

  bool get isPin => this == MessageCategory.messagePin;

  bool get isEncrypted => this?.startsWith('ENCRYPTED_') ?? false;

  bool get isSignal => this?.startsWith('SIGNAL_') ?? false;

  bool get isCall => RegExp('^(WEBRTC|KRAKEN)_').hasMatch(this ?? '');

  bool get isKraken => this?.startsWith('KRAKEN_') ?? false;

  bool get isRecall => this == MessageCategory.messageRecall;

  bool get isFtsMessage =>
      RegExp(r'_(TEXT|DATA|POST|TRANSCRIPT)$').hasMatch(this ?? '');

  bool get isText => this?.endsWith('_TEXT') ?? false;

  bool get isLive => this?.endsWith('_LIVE') ?? false;

  bool get isImage => this?.endsWith('_IMAGE') ?? false;

  bool get isVideo => this?.endsWith('_VIDEO') ?? false;

  bool get isSticker => this?.endsWith('_STICKER') ?? false;

  bool get isPost => this?.endsWith('_POST') ?? false;

  bool get isAudio => this?.endsWith('_AUDIO') ?? false;

  bool get isData => this?.endsWith('_DATA') ?? false;

  bool get isLocation => this?.endsWith('_LOCATION') ?? false;

  bool get isContact => this?.endsWith('_CONTACT') ?? false;

  bool get isTranscript => this?.endsWith('_TRANSCRIPT') ?? false;

  bool get isAppCard => this == MessageCategory.appCard;

  bool get isAppButtonGroup => this == MessageCategory.appButtonGroup;

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

  bool get isIllegalMessageCategory => {
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
    MessageCategory.messageRecall,
    MessageCategory.stranger,
    MessageCategory.secret,
    MessageCategory.systemConversation,
    MessageCategory.systemUser,
    MessageCategory.systemCircle,
    MessageCategory.systemSession,
    MessageCategory.systemAccountSnapshot,
    MessageCategory.systemSafeSnapshot,
    MessageCategory.systemSafeInscription,
    MessageCategory.appButtonGroup,
    MessageCategory.appCard,
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
    MessageCategory.messagePin,
  }.every((element) => element != this);

  bool get canReply =>
      isText ||
      isImage ||
      isVideo ||
      isLive ||
      isData ||
      isPost ||
      isLocation ||
      isAudio ||
      isSticker ||
      isContact ||
      isTranscript ||
      this == MessageCategory.appCard ||
      this == MessageCategory.appButtonGroup;
}
