import 'dart:ui';

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
const createMessage = 'CREATE_MESSAGE';

class MessageStatus {
  static const String sending = 'SENDING';
  static const String sent = 'SENT';
  static const String delivered = 'DELIVERED';
  static const String read = 'READ';
  static const String failed = 'FAILED';
  static const String unknown = 'UNKNOWN';
}

class MediaStatus {
  static const String pending = 'PENDING';
  static const String done = 'DONE';
  static const String canceled = 'CANCELED';
  static const String expired = 'EXPIRED';
  static const String read = 'READ';
}

class MessageCategory {
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

final circleColors = [
  const Color(0x8E7BFF),
  const Color(0x657CFB),
  const Color(0xA739C2),
  const Color(0xBD6DDA),
  const Color(0xFD89F1),
  const Color(0xFA7B95),
  const Color(0xE94156),
  const Color(0xFA9652),
  const Color(0xF1D22B),
  const Color(0xBAE361),
  const Color(0x5EDD5E),
  const Color(0x4BE6FF),
  const Color(0x45B7FE),
  const Color(0x00ECD0),
  const Color(0xFFCCC0),
  const Color(0xCEA06B)
];

final avatarColors = [
  const Color(0xFFD659),
  const Color(0xFFC168),
  const Color(0xF58268),
  const Color(0xF4979C),
  const Color(0xEC7F87),
  const Color(0xFF78CB),
  const Color(0xC377E0),
  const Color(0x8BAAFF),
  const Color(0x78DCFA),
  const Color(0x88E5B9),
  const Color(0xBFF199),
  const Color(0xC5E1A5),
  const Color(0xCD907D),
  const Color(0xBE938E),
  const Color(0xB68F91),
  const Color(0xBC987B),
  const Color(0xA69E8E),
  const Color(0xD4C99E),
  const Color(0x93C2E6),
  const Color(0x92C3D9),
  const Color(0x8FBFC5),
  const Color(0x80CBC4),
  const Color(0xA4DBDB),
  const Color(0xB2C8BD),
  const Color(0xF7C8C9),
  const Color(0xDCC6E4),
  const Color(0xBABAE8),
  const Color(0xBABCD5),
  const Color(0xAD98DA),
  const Color(0xC097D9)
];

final nameColors = [
  const Color(0x8C8DFF),
  const Color(0x7983C2),
  const Color(0x6D8DDE),
  const Color(0x5979F0),
  const Color(0x6695DF),
  const Color(0x8F7AC5),
  const Color(0x9D77A5),
  const Color(0x8A64D0),
  const Color(0xAA66C3),
  const Color(0xA75C96),
  const Color(0xC8697D),
  const Color(0xB74D62),
  const Color(0xBD637C),
  const Color(0xB3798E),
  const Color(0x9B6D77),
  const Color(0xB87F7F),
  const Color(0xC5595A),
  const Color(0xAA4848),
  const Color(0xB0665E),
  const Color(0xB76753),
  const Color(0xBB5334),
  const Color(0xC97B46),
  const Color(0xBE6C2C),
  const Color(0xCB7F40),
  const Color(0xA47758),
  const Color(0xB69370),
  const Color(0xA49373),
  const Color(0xAA8A46),
  const Color(0xAA8220),
  const Color(0x76A048),
  const Color(0x9CAD23),
  const Color(0xA19431),
  const Color(0xAA9100),
  const Color(0xA09555),
  const Color(0xC49B4B),
  const Color(0x5FB05F),
  const Color(0x6AB48F),
  const Color(0x71B15C),
  const Color(0xB3B357),
  const Color(0xA3B561),
  const Color(0x909F45),
  const Color(0x93B289),
  const Color(0x3D98D0),
  const Color(0x429AB6),
  const Color(0x4EABAA),
  const Color(0x6BC0CE),
  const Color(0x64B5D9),
  const Color(0x3E9CCB),
  const Color(0x2887C4),
  const Color(0x52A98B)
];

