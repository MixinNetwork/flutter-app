import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:moor/moor.dart';

class ConversationCategoryTypeConverter
    extends TypeConverter<ConversationCategory, String> {
  @override
  ConversationCategory mapToDart(String fromDb) {
    switch (fromDb) {
      case 'CONTACT':
        return ConversationCategory.contact;
      default:
        return ConversationCategory.group;
    }
  }

  @override
  String mapToSql(ConversationCategory value) {
    if (value == null) {
      return null;
    }
    if (ConversationCategory.contact == value) {
      return 'CONTACT';
    } else {
      return 'GROUP';
    }
  }
}
