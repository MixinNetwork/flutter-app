import 'package:moor/moor.dart';

import '../../enum/message_action.dart';

class MessageActionConverter extends TypeConverter<MessageAction, String> {
  const MessageActionConverter();

  @override
  MessageAction? mapToDart(String? fromDb) =>
      const MessageActionJsonConverter().fromJson(fromDb);

  @override
  String? mapToSql(MessageAction? value) =>
      const MessageActionJsonConverter().toJson(value);
}
