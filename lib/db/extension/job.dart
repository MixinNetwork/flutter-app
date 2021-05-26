import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../constants/constants.dart';
import '../../enum/message_status.dart';
import '../../utils/string_extension.dart';
import '../mixin_database.dart';

Job createAckJob(String messageId, MessageStatus status) {
  final blazeMessage = BlazeAckMessage(
      messageId: messageId,
      status: EnumToString.convertToString(status)!.toUpperCase());
  final jobId =
      '${blazeMessage.messageId}${blazeMessage.status}$acknowledgeMessageReceipts'
          .nameUuid();
  debugPrint('createAckJob jobId: $jobId, status: $status');
  return Job(
      jobId: jobId,
      action: acknowledgeMessageReceipts,
      priority: 5,
      blazeMessage: jsonEncode(blazeMessage),
      createdAt: DateTime.now(),
      runCount: 0);
}
