import 'package:flutter_app/utils/enum_to_string.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:moor/moor.dart';
import 'package:recase/recase.dart';

class ConversationCategoryTypeConverter
    extends TypeConverter<ConversationCategory, String> {
  const ConversationCategoryTypeConverter();

  @override
  ConversationCategory mapToDart(String fromDb) =>
      EnumToString.fromString(ConversationCategory.values, fromDb?.camelCase);

  @override
  String mapToSql(ConversationCategory value) =>
      EnumToString.convertToString(value)?.constantCase;
}
