import 'package:moor/moor.dart';

import '../../enum/message_category.dart';

class MessageCategoryTypeConverter
    extends TypeConverter<MessageCategory, String> {
  const MessageCategoryTypeConverter();

  @override
  MessageCategory? mapToDart(String? fromDb) =>
      const MessageCategoryJsonConverter().fromJson(fromDb);

  @override
  String? mapToSql(MessageCategory? value) =>
      const MessageCategoryJsonConverter().toJson(value);
}
