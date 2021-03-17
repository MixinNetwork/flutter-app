import 'package:json_annotation/json_annotation.dart';

part 'recall_message.g.dart';

@JsonSerializable()
class RecallMessage {
  RecallMessage(this.messageId);

  factory RecallMessage.fromJson(Map<String, dynamic> json) =>
      _$RecallMessageFromJson(json);

  @JsonKey(name: 'message_id')
  String messageId;

  Map<String, dynamic> toJson() => _$RecallMessageToJson(this);
}
