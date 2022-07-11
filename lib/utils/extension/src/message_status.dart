import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

extension MessageStatusOrdinal on MessageStatus {
  int get ordinal {
    switch (this) {
      case MessageStatus.sending:
        return 0;
      case MessageStatus.sent:
        return 1;
      case MessageStatus.delivered:
        return 2;
      case MessageStatus.read:
        return 3;
      case MessageStatus.failed:
        return 4;
      case MessageStatus.unknown:
        return 6;
    }
  }
}
