import 'package:flutter_app/db/mixin_database.dart';

extension Conversation on ConversationItem {
  bool get isPlain => contentType.startsWith('PLAIN_');

  bool get isEncrypted => contentType.startsWith('ENCRYPTED_');

  bool get isSignal => contentType.startsWith('SIGNAL_');

  bool get isCall =>
      contentType.startsWith('WEBRTC_') || contentType.startsWith('KRAKEN_');

  bool get isKraken => contentType.startsWith('KRAKEN_');

  bool get isRecall => contentType == 'MESSAGE_RECALL';

  bool get isFtsMessage =>
      contentType.endsWith('_TEXT') ||
      contentType.endsWith('_DATA') ||
      contentType.endsWith('_POST');

  bool get isText =>
      contentType == 'SIGNAL_TEXT' ||
      contentType == 'PLAIN_TEXT' ||
      contentType == 'ENCRYPTED_TEXT';

  bool get isLive =>
      contentType == 'SIGNAL_LIVE' ||
      contentType == 'PLAIN_LIVE' ||
      contentType == 'ENCRYPTED_LIVE';

  bool get isImage =>
      contentType == 'SIGNAL_IMAGE' ||
      contentType == 'PLAIN_IMAGE' ||
      contentType == 'ENCRYPTED_IMAGE';

  bool get isVideo =>
      contentType == 'SIGNAL_VIDEO' ||
      contentType == 'PLAIN_VIDEO' ||
      contentType == 'ENCRYPTED_VIDEO';

  bool get isSticker =>
      contentType == 'SIGNAL_STICKER' ||
      contentType == 'PLAIN_STICKER' ||
      contentType == 'ENCRYPTED_STICKER';

  bool get isPost =>
      contentType == 'SIGNAL_POST' ||
      contentType == 'PLAIN_POST' ||
      contentType == 'ENCRYPTED_POST';

  bool get isAudio =>
      contentType == 'SIGNAL_AUDIO' ||
      contentType == 'PLAIN_AUDIO' ||
      contentType == 'ENCRYPTED_AUDIO';

  bool get isData =>
      contentType == 'SIGNAL_DATA' ||
      contentType == 'PLAIN_DATA' ||
      contentType == 'ENCRYPTED_DATA';

  bool get isLocation =>
      contentType == 'SIGNAL_LOCATION' ||
      contentType == 'PLAIN_LOCATION' ||
      contentType == 'ENCRYPTED_LOCATION';

  bool get isContact =>
      contentType == 'SIGNAL_CONTACT' ||
      contentType == 'PLAIN_CONTACT' ||
      contentType == 'ENCRYPTED_CONTACT';

  bool get isMedia => isData || isImage || isVideo;

  bool get isAttachment => isData || isImage || isVideo || isAudio;

  bool get isGroupCall =>
      contentType == 'KRAKEN_END' ||
      contentType == 'KRAKEN_DECLINE' ||
      contentType == 'KRAKEN_CANCEL' ||
      contentType == 'KRAKEN_INVITE';

  bool get isCallMessage =>
      contentType == 'WEBRTC_AUDIO_CANCEL' ||
      contentType == 'WEBRTC_AUDIO_DECLINE' ||
      contentType == 'WEBRTC_AUDIO_END' ||
      contentType == 'WEBRTC_AUDIO_BUSY' ||
      contentType == 'WEBRTC_AUDIO_FAILED';

  bool get canRecall =>
      contentType == 'SIGNAL_TEXT' ||
      contentType == 'SIGNAL_IMAGE' ||
      contentType == 'SIGNAL_VIDEO' ||
      contentType == 'SIGNAL_STICKER' ||
      contentType == 'SIGNAL_DATA' ||
      contentType == 'SIGNAL_CONTACT' ||
      contentType == 'SIGNAL_AUDIO' ||
      contentType == 'SIGNAL_LIVE' ||
      contentType == 'SIGNAL_POST' ||
      contentType == 'SIGNAL_LOCATION' ||
      contentType == 'PLAIN_TEXT' ||
      contentType == 'PLAIN_IMAGE' ||
      contentType == 'PLAIN_VIDEO' ||
      contentType == 'PLAIN_STICKER' ||
      contentType == 'PLAIN_DATA' ||
      contentType == 'PLAIN_CONTACT' ||
      contentType == 'PLAIN_AUDIO' ||
      contentType == 'PLAIN_LIVE' ||
      contentType == 'PLAIN_POST' ||
      contentType == 'PLAIN_LOCATION' ||
      contentType == 'APP_CARD';
}
