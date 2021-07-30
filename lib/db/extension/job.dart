import 'dart:convert';

import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../enum/message_status.dart';
import '../../utils/extension/extension.dart';
import '../../utils/logger.dart';
import '../mixin_database.dart';

Job createAckJob(String action, String messageId, MessageStatus status) {
  final blazeMessage = BlazeAckMessage(
      messageId: messageId,
      status: EnumToString.convertToString(status)!.toUpperCase());
  final jobId =
      '${blazeMessage.messageId}${blazeMessage.status}$action'.nameUuid();
  d('createAckJob jobId: $jobId, status: $status');
  return Job(
      jobId: jobId,
      action: action,
      priority: 5,
      blazeMessage: jsonEncode(blazeMessage),
      createdAt: DateTime.now(),
      runCount: 0);
}
