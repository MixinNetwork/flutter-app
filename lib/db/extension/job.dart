import 'dart:convert';

import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../utils/extension/extension.dart';
import '../../utils/logger.dart';
import '../mixin_database.dart';

Job createAckJob(
  String action,
  String messageId,
  MessageStatus status, {
  int? expireAt,
}) {
  final blazeMessage = BlazeAckMessage(
    messageId: messageId,
    status: enumConvertToString(status)!.toUpperCase(),
    expireAt: expireAt,
  );
  final jobId =
      '${blazeMessage.messageId}${blazeMessage.status}$action'.nameUuid();
  d('createAckJob jobId: $jobId, status: $status expireAt: $expireAt');
  return Job(
      jobId: jobId,
      action: action,
      priority: 5,
      blazeMessage: jsonEncode(blazeMessage),
      createdAt: DateTime.now(),
      runCount: 0);
}
