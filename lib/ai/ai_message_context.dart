import 'dart:convert';

import '../blaze/vo/transcript_minimal.dart';
import '../db/dao/message_dao.dart';
import '../db/extension/message.dart';
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

  if (message.type.isTranscript) {
    return _transcriptContextText(content) ?? '[transcript]';
  }

  final caption = message.caption?.trim();
  if (caption != null && caption.isNotEmpty) {
    return caption;
  }

  if (message.type.isImage) {
    return '[image]';
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

String? _transcriptContextText(String? content) {
  if (content == null || content.isEmpty) {
    return null;
  }
  try {
    final decoded = jsonDecode(content);
    if (decoded is! List) {
      return content;
    }
    final lines = decoded
        .map((json) {
          final item = TranscriptMinimal.fromJson(
            Map<String, dynamic>.from(json as Map),
          );
          final text =
              messagePreviewOptimize(null, item.category, item.content) ??
              item.content ??
              '[${item.category}]';
          return '${item.name}: $text';
        })
        .join('\n');
    if (lines.isEmpty) {
      return null;
    }
    return lines;
  } catch (_) {
    return content;
  }
}

String aiMessageContextLine(
  MessageItem message, {
  String? relation,
  int? maxTextLength,
}) {
  final relationText = relation == null ? '' : ', relation=$relation';
  final text = _truncateAiContextText(
    aiMessageContextText(message),
    maxTextLength,
  );
  final line =
      '[${message.createdAt.toIso8601String()}] '
      '${message.userFullName ?? message.userId} '
      '(message_id=${message.messageId}$relationText): $text';
  final quote = aiMessageQuotedItem(message);
  if (quote == null) {
    return line;
  }
  return '$line\n  ${aiQuoteMessageContextLine(quote)}';
}

QuoteMessageItem? aiMessageQuotedItem(MessageItem message) {
  final raw = message.quoteContent?.trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return mapToQuoteMessage(decoded);
    }
    if (decoded is Map) {
      return mapToQuoteMessage(Map<String, dynamic>.from(decoded));
    }
  } catch (_) {
    return null;
  }
  return null;
}

String aiQuoteMessageContextLine(
  QuoteMessageItem message, {
  String prefix = 'quoted_message',
  int? maxTextLength = 1000,
}) {
  final text = _truncateAiContextText(
    aiQuoteMessageContextText(message),
    maxTextLength,
  );
  return '$prefix: [${message.createdAt.toIso8601String()}] '
      '${message.userFullName ?? message.userId} '
      '(message_id=${message.messageId}): $text';
}

String aiQuoteMessageContextText(QuoteMessageItem message) {
  final content = message.content?.trim();
  if ((message.type.isText || message.type.isPost) &&
      content != null &&
      content.isNotEmpty) {
    return content;
  }
  if (content != null && content.isNotEmpty) {
    return content;
  }

  final mediaName = message.mediaName?.trim();
  if (mediaName != null && mediaName.isNotEmpty) {
    return '[${message.type}] $mediaName';
  }

  final assetName = message.assetName?.trim();
  if (assetName != null && assetName.isNotEmpty) {
    return '[${message.type}] $assetName';
  }

  return messagePreviewOptimize(
        message.status,
        message.type,
        message.content,
      ) ??
      '[${message.type}]';
}

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

String _truncateAiContextText(String text, int? maxLength) {
  if (maxLength == null || text.length <= maxLength) {
    return text;
  }
  if (maxLength <= 3) {
    return text.substring(0, maxLength);
  }
  return '${text.substring(0, maxLength - 3)}...';
}
