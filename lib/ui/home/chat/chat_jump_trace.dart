import 'package:flutter/widgets.dart';

import '../../../utils/logger.dart';

const chatJumpTraceEnabled = bool.fromEnvironment('MIXIN_CHAT_JUMP_TRACE');

void traceChatJump(String message) {
  if (!chatJumpTraceEnabled) return;
  i('[chat-jump] $message');
}

String shortMessageId(String? messageId) {
  if (messageId == null || messageId.isEmpty) return '-';
  if (messageId.length <= 8) return messageId;
  return messageId.substring(0, 8);
}

String formatDouble(num? value) {
  if (value == null || !value.isFinite) return '$value';
  return value.toStringAsFixed(1);
}

String formatScrollMetrics(ScrollMetrics metrics) =>
    'px=${formatDouble(metrics.pixels)} '
    'min=${formatDouble(metrics.minScrollExtent)} '
    'max=${formatDouble(metrics.maxScrollExtent)} '
    'vp=${formatDouble(metrics.viewportDimension)}';
