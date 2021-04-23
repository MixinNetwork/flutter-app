import 'package:flutter_app/blaze/blaze_message_param_session.dart';
import 'package:flutter_app/blaze/blaze_param.dart';
import 'package:flutter_app/constants/constants.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';

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

BlazeMessage createParamBlazeMessage(BlazeMessageParam param) =>
    BlazeMessage(id: const Uuid().v4(), action: createMessage, params: param);

BlazeMessage createConsumeSessionSignalKeys(BlazeMessageParam param) =>
    BlazeMessage(
        id: const Uuid().v4(), action: consumeSessionSignalKeys, params: param);

BlazeMessage createSignalKeyMessage(BlazeMessageParam param) =>
    BlazeMessage(id: const Uuid().v4(), action: createSignalKeyMessages, params: param);

BlazeMessageParam createConsumeSignalKeysParam(
        List<BlazeMessageParamSession> recipients) =>
    BlazeMessageParam(recipients: recipients);
