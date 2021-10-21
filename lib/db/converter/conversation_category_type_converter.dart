import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

class ConversationCategoryTypeConverter
    extends TypeConverter<ConversationCategory, String> {
  const ConversationCategoryTypeConverter();

  @override
  ConversationCategory? mapToDart(String? fromDb) =>
      const ConversationCategoryJsonConverter().fromJson(fromDb);

  @override
  String? mapToSql(ConversationCategory? value) =>
      const ConversationCategoryJsonConverter().toJson(value);
}
