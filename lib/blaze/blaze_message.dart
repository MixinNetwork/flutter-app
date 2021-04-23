import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

part 'blaze_message.g.dart';

@JsonSerializable()
class BlazeMessage {
  BlazeMessage({
    required this.id,
    required this.action,
    this.data,
    this.params,
    this.error,
  });

  factory BlazeMessage.fromJson(Map<String, dynamic> json) =>
      _$BlazeMessageFromJson(json);

  @JsonKey(name: 'id')
  String id;
  @JsonKey(name: 'action')
  String action;
  @JsonKey(name: 'params')
  dynamic params;
  @JsonKey(name: 'data')
  Map<String, dynamic>? data;
  @JsonKey(name: 'error')
  MixinError? error;

  Map<String, dynamic> toJson() => _$BlazeMessageToJson(this);
}
