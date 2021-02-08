import 'package:flutter_app/enum/message_action.dart';
import 'package:moor/moor.dart';

class MessageActionConverter extends TypeConverter<MessageAction, String> {
  const MessageActionConverter();

  @override
  MessageAction mapToDart(String fromDb) =>
      const MessageActionJsonConverter().fromJson(fromDb);

  @override
  String mapToSql(MessageAction value) =>
      const MessageActionJsonConverter().toJson(value);
}
