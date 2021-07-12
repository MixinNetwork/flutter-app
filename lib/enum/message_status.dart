import 'package:json_annotation/json_annotation.dart';

enum MessageStatus {
  @JsonValue('UNKNOWN')
  unknown,
  @JsonValue('FAILED')
  failed,
  @JsonValue('SENDING')
  sending,
  @JsonValue('SENT')
  sent,
  @JsonValue('DELIVERED')
  delivered,
  @JsonValue('READ')
  read,
}
