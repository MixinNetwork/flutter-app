import 'package:json_annotation/json_annotation.dart';

enum SystemConversationAction {
  @JsonValue('JOIN')
  join,
  @JsonValue('EXIT')
  exit,
  @JsonValue('ADD')
  add,
  @JsonValue('REMOVE')
  remove,
  @JsonValue('create')
  create,
  @JsonValue('update')
  update,
  @JsonValue('role')
  role
}
