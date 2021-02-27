import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:moor/moor.dart';

class ConversationStatusTypeConverter
    extends TypeConverter<ConversationStatus, int> {
  const ConversationStatusTypeConverter();

  @override
  ConversationStatus? mapToDart(int? fromDb) =>
      const ConversationStatusJsonConverter().fromJson(fromDb);

  @override
  int? mapToSql(ConversationStatus? value) =>
      const ConversationStatusJsonConverter().toJson(value);
}
