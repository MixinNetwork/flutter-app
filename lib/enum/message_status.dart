import 'package:json_annotation/json_annotation.dart';

enum MessageStatus {
  @JsonValue('SENDING')
  sending,
  @JsonValue('SENT')
  sent,
  @JsonValue('DELIVERED')
  delivered,
  @JsonValue('READ')
  read,
  @JsonValue('UNKNOWN')
  unknown,
  @JsonValue('FAILED')
  failed,
}
