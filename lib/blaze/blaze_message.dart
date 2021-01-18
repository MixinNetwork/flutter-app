import 'package:json_annotation/json_annotation.dart';

part 'blaze_message.g.dart';

@JsonSerializable()
class BlazeMessage {
  BlazeMessage({
    this.id,
    this.action,
    this.data,
    // this.params,
    // this.error
  });

  factory BlazeMessage.fromJson(Map<String, dynamic> json) =>
      _$BlazeMessageFromJson(json);

  @JsonKey(name: 'id', nullable: false)
  String id;
  @JsonKey(name: 'action', nullable: false)
  String action;

  // @JsonKey(name: 'params')
  // BlazeMessageParam params;
  @JsonKey(name: 'data')
  Map<String, dynamic> data;

  // @JsonKey(name: 'error')
  // ResponseError error;

  Map<String, dynamic> toJson() => _$BlazeMessageToJson(this);
}
