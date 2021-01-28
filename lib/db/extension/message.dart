import 'package:flutter_app/db/mixin_database.dart';

extension Message on MessageItem {
  bool get isPlain => type.startsWith('PLAIN_');

  bool get isEncrypted => type.startsWith('ENCRYPTED_');

  bool get isSignal => type.startsWith('SIGNAL_');

  bool get isCall => type.startsWith('WEBRTC_') || type.startsWith('KRAKEN_');

  bool get isKraken => type.startsWith('KRAKEN_');

  bool get isRecall => type == 'MESSAGE_RECALL';

  bool get isFtsMessage =>
      type.endsWith('_TEXT') ||
      type.endsWith('_DATA') ||
      type.endsWith('_POST');

  bool get isText =>
      type == 'SIGNAL_TEXT' || type == 'PLAIN_TEXT' || type == 'ENCRYPTED_TEXT';

  bool get isLive =>
      type == 'SIGNAL_LIVE' || type == 'PLAIN_LIVE' || type == 'ENCRYPTED_LIVE';

  bool get isImage =>
      type == 'SIGNAL_IMAGE' ||
      type == 'PLAIN_IMAGE' ||
      type == 'ENCRYPTED_IMAGE';

  bool get isVideo =>
      type == 'SIGNAL_VIDEO' ||
      type == 'PLAIN_VIDEO' ||
      type == 'ENCRYPTED_VIDEO';

  bool get isSticker =>
      type == 'SIGNAL_STICKER' ||
      type == 'PLAIN_STICKER' ||
      type == 'ENCRYPTED_STICKER';

  bool get isPost =>
      type == 'SIGNAL_POST' || type == 'PLAIN_POST' || type == 'ENCRYPTED_POST';

  bool get isAudio =>
      type == 'SIGNAL_AUDIO' ||
      type == 'PLAIN_AUDIO' ||
      type == 'ENCRYPTED_AUDIO';

  bool get isData =>
      type == 'SIGNAL_DATA' || type == 'PLAIN_DATA' || type == 'ENCRYPTED_DATA';

  bool get isLocation =>
      type == 'SIGNAL_LOCATION' ||
      type == 'PLAIN_LOCATION' ||
      type == 'ENCRYPTED_LOCATION';

  bool get isContact =>
      type == 'SIGNAL_CONTACT' ||
      type == 'PLAIN_CONTACT' ||
      type == 'ENCRYPTED_CONTACT';

  bool get isMedia => isData || isImage || isVideo;

  bool get isAttachment => isData || isImage || isVideo || isAudio;

  bool get isGroupCall =>
      type == 'KRAKEN_END' ||
      type == 'KRAKEN_DECLINE' ||
      type == 'KRAKEN_CANCEL' ||
      type == 'KRAKEN_INVITE';

  bool get isCallMessage =>
      type == 'WEBRTC_AUDIO_CANCEL' ||
      type == 'WEBRTC_AUDIO_DECLINE' ||
      type == 'WEBRTC_AUDIO_END' ||
      type == 'WEBRTC_AUDIO_BUSY' ||
      type == 'WEBRTC_AUDIO_FAILED';

  bool get canRecall =>
      type == 'SIGNAL_TEXT' ||
      type == 'SIGNAL_IMAGE' ||
      type == 'SIGNAL_VIDEO' ||
      type == 'SIGNAL_STICKER' ||
      type == 'SIGNAL_DATA' ||
      type == 'SIGNAL_CONTACT' ||
      type == 'SIGNAL_AUDIO' ||
      type == 'SIGNAL_LIVE' ||
      type == 'SIGNAL_POST' ||
      type == 'SIGNAL_LOCATION' ||
      type == 'PLAIN_TEXT' ||
      type == 'PLAIN_IMAGE' ||
      type == 'PLAIN_VIDEO' ||
      type == 'PLAIN_STICKER' ||
      type == 'PLAIN_DATA' ||
      type == 'PLAIN_CONTACT' ||
      type == 'PLAIN_AUDIO' ||
      type == 'PLAIN_LIVE' ||
      type == 'PLAIN_POST' ||
      type == 'PLAIN_LOCATION' ||
      type == 'APP_CARD';

  bool get isLottie => assetType?.toLowerCase() == 'json';
}
