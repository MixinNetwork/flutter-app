import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

enum MessageAction {
  join,
  exit,
  add,
  remove,
  create,
  update,
  role,
  expire,
}

class MessageActionJsonConverter extends EnumJsonConverter<MessageAction> {
  const MessageActionJsonConverter();

  @override
  List<MessageAction> enumValues() => MessageAction.values;
}
