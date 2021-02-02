import 'package:json_annotation/json_annotation.dart';

enum SystemSessionAction {
  @JsonValue('PROVISION')
  provision,
  @JsonValue('DESTROY')
  destroy,
}
