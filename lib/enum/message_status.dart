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
  @JsonValue('FAILED')
  failed,
  @JsonValue('UNKNOWN')
  unknown
}
