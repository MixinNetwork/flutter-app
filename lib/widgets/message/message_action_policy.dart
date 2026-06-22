import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../db/mixin_database.dart' hide Message;
import '../../enum/media_status.dart';
import '../../utils/extension/extension.dart';
import '../../utils/platform.dart';

class MessageActionPolicy {
  const MessageActionPolicy({
    required this.message,
    required this.isTranscriptPage,
    required this.isPinnedPage,
    required this.role,
  });

  static const _pinStatuses = [
    MessageStatus.delivered,
    MessageStatus.read,
    MessageStatus.sent,
  ];

  final MessageItem message;
  final bool isTranscriptPage;
  final bool isPinnedPage;
  final Object? role;

  bool get canPin =>
      !isTranscriptPage &&
      message.type.canReply &&
      _pinStatuses.contains(message.status) &&
      role != null;

  bool get canReply =>
      !isTranscriptPage && message.type.canReply && !isPinnedPage;

  bool get canForward => !isTranscriptPage && message.canForward;

  bool get canSelect => !isTranscriptPage;

  bool get canSaveMobile =>
      kPlatformIsMobile && (message.type.isImage || message.type.isVideo);

  bool get canSaveDesktop =>
      kPlatformIsDesktop &&
      message.mediaStatus == MediaStatus.done &&
      message.mediaUrl?.isNotEmpty == true &&
      (message.type.isData ||
          message.type.isImage ||
          message.type.isVideo ||
          message.type.isAudio);

  bool get canRecall => !isTranscriptPage && message.canRecall;

  bool get canDelete => !isTranscriptPage && !isPinnedPage;

  bool get canAddSticker => message.type.isSticker;

  bool get canAddImageAsSticker => message.type.isImage && message.canForward;
}
