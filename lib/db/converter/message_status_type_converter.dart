import 'package:flutter_app/enum/message_status.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:moor/moor.dart';

class MessageStatusTypeConverter extends TypeConverter<MessageStatus, String> {
  const MessageStatusTypeConverter();

  @override
  MessageStatus? mapToDart(String? fromDb) =>
      EnumToString.fromString(MessageStatus.values, fromDb);

  @override
  String? mapToSql(MessageStatus? value) =>
      EnumToString.convertToString(value ?? MessageStatus.failed);
}
