import 'package:flutter_app/enum/message_status.dart';
import 'package:flutter_app/utils/enum_to_string.dart';
import 'package:moor/moor.dart';

class MessageStatusTypeConverter extends TypeConverter<MessageStatus, String> {
  const MessageStatusTypeConverter();

  @override
  MessageStatus mapToDart(String fromDb) {
    return EnumToString.fromString(MessageStatus.values, fromDb);
  }

  @override
  String mapToSql(MessageStatus value) {
    return EnumToString.convertToString(value ?? MessageStatus.failed);
  }
}
