import 'package:json_annotation/json_annotation.dart';

enum MessageStatus {
  @JsonValue('FAILED')
  failed,
  @JsonValue('UNKNOWN')
  unknown,
  @JsonValue('SENDING')
  sending,
  @JsonValue('SENT')
  sent,
  @JsonValue('DELIVERED')
  delivered,
  @JsonValue('READ')
  read,
}
