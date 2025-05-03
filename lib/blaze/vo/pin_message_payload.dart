import 'package:json_annotation/json_annotation.dart';

part 'pin_message_payload.g.dart';

@JsonSerializable()
class PinMessagePayload {
  PinMessagePayload({required this.action, required this.messageIds});

  factory PinMessagePayload.fromJson(Map<String, dynamic> json) =>
      _$PinMessagePayloadFromJson(json);

  @JsonKey(name: 'action')
  final PinMessagePayloadAction? action;
  @JsonKey(name: 'message_ids')
  final List<String> messageIds;

  Map<String, dynamic> toJson() => _$PinMessagePayloadToJson(this);
}

enum PinMessagePayloadAction {
  @JsonValue('PIN')
  pin,
  @JsonValue('UNPIN')
  unpin,
}
