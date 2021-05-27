import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../enum/message_status.dart';
import '../../utils/string_extension.dart';
import '../mixin_database.dart';

Job createAckJob(String action, String messageId, MessageStatus status) {
  final blazeMessage = BlazeAckMessage(
      messageId: messageId,
      status: EnumToString.convertToString(status)!.toUpperCase());
  final jobId =
      '${blazeMessage.messageId}${blazeMessage.status}$action'.nameUuid();
  debugPrint('createAckJob jobId: $jobId, status: $status');
  return Job(
      jobId: jobId,
      action: action,
      priority: 5,
      blazeMessage: jsonEncode(blazeMessage),
      createdAt: DateTime.now(),
      runCount: 0);
}
