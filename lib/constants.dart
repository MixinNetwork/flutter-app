enum ConversationStatus {
  start,
  failure,
  success,
  quit,
}

const systemUser = '00000000-0000-0000-0000-000000000000';

const scp =
    'PROFILE:READ PROFILE:WRITE PHONE:READ PHONE:WRITE CONTACTS:READ CONTACTS:WRITE MESSAGES:READ MESSAGES:WRITE ASSETS:READ SNAPSHOTS:READ CIRCLES:READ CIRCLES:WRITE';

class ConversationCategory {
  static const String contact = 'CONTACT';

  static const String group = 'GROUP';
}

const acknowledgeMessageReceipts = 'ACKNOWLEDGE_MESSAGE_RECEIPTS';

class MessageStatus {
  static const String sending = 'SENDING';
  static const String sent = 'SENT';
  static const String delivered = 'DELIVERED';
  static const String read = 'READ';
  static const String failed = 'FAILED';
  static const String unknown = 'UNKNOWN';
}

class MessageCategory{
  static const String signalKey = 'SIGNAL_KEY';
  static const String signalText = 'SIGNAL_TEXT';
  static const String signalImage = 'SIGNAL_IMAGE';
  static const String signalVideo = 'SIGNAL_VIDEO';
  static const String signalSticker = 'SIGNAL_STICKER';
  static const String signalData = 'SIGNAL_DATA';
  static const String signalContact = 'SIGNAL_CONTACT';
  static const String signalAudio = 'SIGNAL_AUDIO';
  static const String signalLive = 'SIGNAL_LIVE';
  static const String signalPost = 'SIGNAL_POST';
  static const String signalLocation = 'SIGNAL_LOCATION';
  static const String plainText = 'PLAIN_TEXT';
  static const String plainImage = 'PLAIN_IMAGE';
  static const String plainVideo = 'PLAIN_VIDEO';
  static const String plainData = 'PLAIN_DATA';
  static const String plainSticker = 'PLAIN_STICKER';
  static const String plainContact = 'PLAIN_CONTACT';
  static const String plainAudio = 'PLAIN_AUDIO';
  static const String plainLive = 'PLAIN_LIVE';
  static const String plainPost = 'PLAIN_POST';
  static const String plainJson = 'PLAIN_JSON';
  static const String plainLocation = 'PLAIN_LOCATION';
  static const String appButtonGroup = 'APP_BUTTON_GROUP';
  static const String appCard = 'APP_CARD';
}