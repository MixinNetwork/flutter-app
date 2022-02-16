import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:recase/recase.dart';

class MessageStatusTypeConverter extends TypeConverter<MessageStatus, String> {
  const MessageStatusTypeConverter();

  @override
  MessageStatus? mapToDart(String? fromDb) =>
      fromStringToEnum(MessageStatus.values, fromDb);

  @override
  String? mapToSql(MessageStatus? value) =>
      enumConvertToString(value ?? MessageStatus.failed)?.constantCase;
}
