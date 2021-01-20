import 'package:flutter_app/vo/conversation_status.dart';
import 'package:moor/moor.dart';

class ConversationStatusTypeConverter
    extends TypeConverter<ConversationStatus, int> {
  @override
  ConversationStatus mapToDart(int fromDb) {
    return ConversationStatus.values[fromDb];
  }

  @override
  int mapToSql(ConversationStatus value) {
    if (value == null) return ConversationStatus.failure.index;
    return value.index;
  }
}
