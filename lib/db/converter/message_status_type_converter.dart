import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:recase/recase.dart';

class MessageStatusTypeConverter extends TypeConverter<MessageStatus, String> {
  const MessageStatusTypeConverter();

  @override
  MessageStatus fromSql(String fromDb) =>
      fromStringToEnum(MessageStatus.values, fromDb) ?? MessageStatus.failed;

  @override
  String toSql(MessageStatus value) => enumConvertToString(value)!.constantCase;
}
