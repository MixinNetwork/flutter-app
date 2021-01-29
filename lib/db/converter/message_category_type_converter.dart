import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/utils/enum_to_string.dart';
import 'package:recase/recase.dart';
import 'package:moor/moor.dart';

class MessageCategoryTypeConverter
    extends TypeConverter<MessageCategory, String> {
  const MessageCategoryTypeConverter();

  @override
  MessageCategory mapToDart(String fromDb) =>
      EnumToString.fromString(MessageCategory.values, fromDb?.camelCase);

  @override
  String mapToSql(MessageCategory value) =>
      EnumToString.convertToString(value)?.constantCase;
}
