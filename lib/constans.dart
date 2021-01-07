enum ConversationStatus {
  start,
  failure,
  success,
  quit,
}

const systemUser = '00000000-0000-0000-0000-000000000000';

class ConversationCategory {
  static const String contact = 'CONTACT';

  static const String group = 'GROUP';
}

class MessageStatus {
  static const String sending = 'SENDING';
  static const String sent = 'SENT';
  static const String delivered = 'DELIVERED';
  static const String read = 'READ';
  static const String failed = 'FAILED';
  static const String unknown = 'UNKNOWN';
}
