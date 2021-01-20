import 'package:json_annotation/json_annotation.dart';

enum ConversationStatus {
  @JsonValue(0)
  start,
  @JsonValue(1)
  failure,
  @JsonValue(2)
  success,
  @JsonValue(3)
  quit,
}

