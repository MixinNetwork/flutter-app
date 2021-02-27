import 'package:json_annotation/json_annotation.dart';

part 'blaze_message.g.dart';

@JsonSerializable()
class BlazeMessage {
  BlazeMessage({
    required this.id,
    required this.action,
    this.data,
    this.params,
    // this.error
  });

  factory BlazeMessage.fromJson(Map<String, dynamic> json) =>
      _$BlazeMessageFromJson(json);

  @JsonKey(name: 'id', disallowNullValue: true)
  String id;
  @JsonKey(name: 'action', disallowNullValue: true)
  String action;
  @JsonKey(name: 'params')
  dynamic params;
  @JsonKey(name: 'data')
  Map<String, dynamic>? data;

  Map<String, dynamic> toJson() => _$BlazeMessageToJson(this);
}
