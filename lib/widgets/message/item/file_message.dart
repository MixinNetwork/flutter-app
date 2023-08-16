import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mime/mime.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

import '../../../constants/brightness_theme_data.dart';
import '../../../enum/media_status.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/logger.dart';
import '../../interactive_decorated_box.dart';
import '../../status.dart';
import '../../toast.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';
import '../message_style.dart';
import 'transcript_message.dart';

class FileMessage extends HookConsumerWidget {
  const FileMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const MessageBubble(
        outerTimeAndStatusWidget: MessageDatetimeAndStatus(),
        child: MessageFile(),
      );
}

class MessageFile extends HookConsumerWidget {
  const MessageFile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTranscriptPage = useIsTranscriptPage();
    final mediaStatus =
        useMessageConverter(converter: (state) => state.mediaStatus);
    final relationship =
        useMessageConverter(converter: (state) => state.relationship);
    final mediaUrl = useMessageConverter(converter: (state) => state.mediaUrl);
    final mediaName =
        useMessageConverter(converter: (state) => state.mediaName ?? '');
    final extension = useMessageConverter(converter: (state) {
      var extension = '';
      if (state.mediaName != null) {
        final mimeType = lookupMimeType(state.mediaName!);
        // Only show the extension which is valid.
        if (mimeType != null) {
          extension =
              p.extension(state.mediaName!).trim().replaceFirst('.', '');
        }
      }
      return extension.isEmpty ? 'FILE' : extension.toUpperCase();
    });
    final mediaSizeText =
        useMessageConverter(converter: (state) => filesize(state.mediaSize));

    final isMessageSentOut = (isTranscriptPage &&
            TranscriptPage.of(context)?.relationship == UserRelationship.me) ||
        (!isTranscriptPage && relationship == UserRelationship.me);

    return InteractiveDecoratedBox(
      onTap: () async {
        final message = context.message;
        if (message.mediaStatus == MediaStatus.canceled) {
          if (isMessageSentOut && message.mediaUrl?.isNotEmpty == true) {
            if (isTranscriptPage) {
              final transcriptMessageId = TranscriptPage.of(context)?.messageId;
              await context.accountServer
                  .reUploadTranscriptAttachment(transcriptMessageId!);
            } else {
              await context.accountServer.reUploadAttachment(message);
            }
          } else {
            await context.accountServer.downloadAttachment(message.messageId);
          }
        } else if (message.mediaStatus == MediaStatus.done &&
            message.mediaUrl != null) {
          if (message.mediaUrl?.isEmpty ?? true) return;
          if (_shouldOpenDirectly(mediaName)) {
            final path = context.accountServer
                .convertMessageAbsolutePath(message, isTranscriptPage);
            final openResult = await OpenFile.open(path);
            if (openResult.type != ResultType.done) {
              i('open file result: $mediaName ${openResult.type} ${openResult.message}');
              showToastFailed(
                  ToastError(context.l10n.unableToOpenFile(mediaName)));
            }
          } else {
            await saveAs(
                context, context.accountServer, message, isTranscriptPage);
          }
        } else if (message.mediaStatus == MediaStatus.pending) {
          await context.accountServer
              .cancelProgressAttachmentJob(message.messageId);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(builder: (context) {
            switch (mediaStatus) {
              case MediaStatus.canceled:
                return isMessageSentOut && mediaUrl?.isNotEmpty == true
                    ? const StatusUpload()
                    : const StatusDownload();
              case MediaStatus.pending:
                return const StatusPending();
              case MediaStatus.expired:
                return const StatusWarning();
              case null:
              case MediaStatus.done:
              case MediaStatus.read:
                break;
            }

            return Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: context.theme.statusBackground,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                extension,
                style: TextStyle(
                  fontSize: 12,
                  color: lightBrightnessThemeData.secondaryText,
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  mediaName.overflow,
                  style: TextStyle(
                    fontSize: context.messageStyle.secondaryFontSize,
                    color: context.theme.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  mediaSizeText,
                  style: TextStyle(
                    fontSize: context.messageStyle.tertiaryFontSize,
                    color: context.theme.secondaryText,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool _shouldOpenDirectly(String mediaName) {
  final extension = p.extension(mediaName).toLowerCase();
  const allowList = {
    // image
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.bmp',
    '.webp',
    // audio,video
    '.mp4',
    '.mp3',
    '.wav',
    '.m4a',
    '.m4v',
    '.mov',
    '.avi',
    '.mkv',
    '.flv',
    '.wmv',
    '.3gp',
    '.mpg',
    '.mpeg',
    '.ogv',
    '.ogm',
    '.ogg',
    '.webm',
    '.m3u8',
    '.ts',
    // document
    '.pdf',
    '.doc',
    '.docx',
    '.xls',
    '.xlsx',
    '.ppt',
    '.pptx',
    '.txt',
    '.rtf',
    '.csv',
    '.log',
  };
  return allowList.contains(extension);
}
