import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

class ConversationCategoryTypeConverter
    extends TypeConverter<ConversationCategory?, String?> {
  const ConversationCategoryTypeConverter();

  @override
  ConversationCategory? fromSql(String? fromDb) =>
      const ConversationCategoryJsonConverter().fromJson(fromDb);

  @override
  String? toSql(ConversationCategory? value) =>
      const ConversationCategoryJsonConverter().toJson(value);
}
