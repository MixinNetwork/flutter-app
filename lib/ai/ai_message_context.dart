import '../db/extension/message_category.dart';
import '../db/mixin_database.dart';
import '../utils/message_optimize.dart';

String aiMessageContextText(MessageItem message) {
  final content = message.content?.trim();
  if ((message.type.isText || message.type.isPost) &&
      content != null &&
      content.isNotEmpty) {
    return content;
  }

  final caption = message.caption?.trim();
  if (caption != null && caption.isNotEmpty) {
    return caption;
  }

  final mediaName = message.mediaName?.trim();
  if (mediaName != null && mediaName.isNotEmpty) {
    return '[${message.type}] $mediaName';
  }

  return messagePreviewOptimize(
        message.status,
        message.type,
        message.content,
      ) ??
      '[${message.type}]';
}

String aiMessageContextLine(MessageItem message) =>
    '[${message.createdAt.toIso8601String()}] '
    '${message.userFullName ?? message.userId} '
    '(message_id=${message.messageId}): ${aiMessageContextText(message)}';

String aiMessageContextPreview(MessageItem message, {int maxLength = 96}) {
  final text = aiMessageContextText(message).replaceAll(RegExp(r'\s+'), ' ');
  if (text.length <= maxLength) {
    return text;
  }
  return '${text.substring(0, maxLength)}...';
}

Map<String, dynamic> aiMessageContextMetadata(MessageItem message) => {
  'messageId': message.messageId,
  'conversationId': message.conversationId,
  'senderId': message.userId,
  'senderName': message.userFullName ?? message.userId,
  'type': message.type,
  'createdAt': message.createdAt.toUtc().toIso8601String(),
  'preview': aiMessageContextPreview(message, maxLength: 180),
};
