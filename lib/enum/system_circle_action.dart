import 'package:json_annotation/json_annotation.dart';

enum SystemCircleAction {
  @JsonValue('CREATE')
  create,
  @JsonValue('DELETE')
  delete,
  @JsonValue('UPDATE')
  update,
  @JsonValue('ADD')
  add,
  @JsonValue('REMOVE')
  remove,
}
