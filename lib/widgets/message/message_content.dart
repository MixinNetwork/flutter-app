import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../db/extension/message_category.dart';
import '../../db/mixin_database.dart' hide Message;
import '../../enum/message_category.dart';
import 'item/action/action_message.dart';
import 'item/action_card/action_message.dart';
import 'item/audio_message.dart';
import 'item/contact_message_widget.dart';
import 'item/file_message.dart';
import 'item/image/image_message.dart';
import 'item/location/location_message_widget.dart';
import 'item/post_message.dart';
import 'item/recall_message.dart';
import 'item/sticker_message.dart';
import 'item/text/text_message.dart';
import 'item/transcript_message.dart';
import 'item/transfer/inscription_message/inscription_message.dart';
import 'item/transfer/safe_transfer_message.dart';
import 'item/transfer/transfer_message.dart';
import 'item/unknown_message.dart';
import 'item/video/video_message.dart';
import 'item/waiting_message.dart';

class MessageContent extends StatelessWidget {
  const MessageContent({required this.message, super.key});

  final MessageItem message;

  @override
  Widget build(BuildContext context) {
    if (message.type.isIllegalMessageCategory ||
        message.status == MessageStatus.unknown) {
      return const UnknownMessage();
    }

    if (message.status == MessageStatus.failed) {
      return const WaitingMessage();
    }

    if (message.type.isTranscript) {
      return const TranscriptMessageWidget();
    }

    if (message.type.isLocation) {
      return const LocationMessageWidget();
    }

    if (message.type.isPost) {
      return const PostMessage();
    }

    if (message.type == MessageCategory.systemAccountSnapshot) {
      return const TransferMessage();
    }

    if (message.type == MessageCategory.systemSafeSnapshot) {
      return const SafeTransferMessage();
    }

    if (message.type.isContact) {
      return const ContactMessageWidget();
    }

    if (message.type == MessageCategory.appButtonGroup) {
      return const ActionMessage();
    }

    if (message.type == MessageCategory.appCard) {
      return const ActionCardMessage();
    }

    if (message.type.isData) {
      return const FileMessage();
    }

    if (message.type.isText) {
      return const TextMessage();
    }

    if (message.type.isSticker) {
      return const StickerMessageWidget();
    }

    if (message.type.isImage) {
      return const ImageMessageWidget();
    }

    if (message.type.isVideo || message.type.isLive) {
      return const VideoMessageWidget();
    }

    if (message.type.isAudio) {
      return const AudioMessage();
    }

    if (message.type.isRecall) {
      return const RecallMessage();
    }

    if (message.type == MessageCategory.systemSafeInscription) {
      return const InscriptionMessage();
    }

    return const UnknownMessage();
  }
}
