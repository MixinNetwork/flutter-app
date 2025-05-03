import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';

import '../constants/constants.dart';
import '../crypto/signal/signal_key_request.dart';
import '../enum/message_category.dart';
import 'blaze_message_param.dart';
import 'blaze_message_param_session.dart';

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
  @JsonKey(name: 'params', toJson: dynamicToJson)
  dynamic params;
  @JsonKey(name: 'data', toJson: dynamicToJson)
  dynamic data;
  @JsonKey(name: 'error')
  MixinError? error;

  Map<String, dynamic> toJson() => _$BlazeMessageToJson(this);

  // ignore: prefer_expression_function_bodies
  bool isReceiveMessageAction() {
    return action == kCreateMessage ||
        action == kAcknowledgeMessageReceipt ||
        action == kCreateCall ||
        action == kCreateKraken;
  }
}

BlazeMessage createParamBlazeMessage(BlazeMessageParam param) =>
    BlazeMessage(id: const Uuid().v4(), action: kCreateMessage, params: param);

BlazeMessage createPendingBlazeMessage(BlazeMessageParamOffset offset) =>
    BlazeMessage(
      id: const Uuid().v4(),
      action: kListPendingMessage,
      params: offset,
    );

BlazeMessage createConsumeSessionSignalKeys(BlazeMessageParam param) =>
    BlazeMessage(
      id: const Uuid().v4(),
      action: kConsumeSessionSignalKeys,
      params: param,
    );

BlazeMessage createSignalKeyMessage(BlazeMessageParam param) => BlazeMessage(
  id: const Uuid().v4(),
  action: kCreateSignalKeyMessages,
  params: param,
);

BlazeMessage createCountSignalKeys() =>
    BlazeMessage(id: const Uuid().v4(), action: kCountSignalKeys);

BlazeMessage createSyncSignalKeys(BlazeMessageParam param) =>
    BlazeMessage(id: const Uuid().v4(), action: kSyncSignalKeys, params: param);

BlazeMessageParam createConsumeSignalKeysParam(
  List<BlazeMessageParamSession> recipients,
) => BlazeMessageParam(recipients: recipients);

BlazeMessageParam createPlainJsonParam(
  String conversationId,
  String userId,
  String encoded, {
  String? sessionId,
}) => BlazeMessageParam(
  conversationId: conversationId,
  recipientId: userId,
  messageId: const Uuid().v4(),
  category: MessageCategory.plainJson,
  data: encoded,
  status: MessageStatus.sending.toString(),
  sessionId: sessionId,
);

BlazeMessageParam createSyncSignalKeysParam(SignalKeyRequest? request) =>
    BlazeMessageParam(keys: request);
