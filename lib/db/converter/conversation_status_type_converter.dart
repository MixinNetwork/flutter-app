import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

class ConversationStatusTypeConverter
    extends TypeConverter<ConversationStatus, int> {
  const ConversationStatusTypeConverter();

  @override
  ConversationStatus fromSql(int fromDb) =>
      const ConversationStatusJsonConverter().fromJson(fromDb);

  @override
  int toSql(ConversationStatus value) =>
      const ConversationStatusJsonConverter().toJson(value)!;
}
