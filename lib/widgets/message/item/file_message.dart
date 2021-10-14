import 'dart:io';

import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mime/mime.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:open_file/open_file.dart';

import '../../../constants/brightness_theme_data.dart';
import '../../../enum/media_status.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/file.dart';
import '../../interactive_decorated_box.dart';
import '../../status.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';

class FileMessage extends HookWidget {
  const FileMessage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isTranscriptPage = useIsTranscriptPage();
    final mediaStatus =
        useMessageConverter(converter: (state) => state.mediaStatus);
    final relationship =
        useMessageConverter(converter: (state) => state.relationship);
    final mediaUrl = useMessageConverter(converter: (state) => state.mediaUrl);
    final mediaName = useMessageConverter(
        converter: (state) => state.mediaName?.overflow ?? '');
    final extension = useMessageConverter(converter: (state) {
      var extension = 'FILE';
      if (state.mediaName != null) {
        final _lookupMimeType = lookupMimeType(state.mediaName!);
        if (_lookupMimeType != null) {
          extension = extensionFromMime(_lookupMimeType).toUpperCase();
        }
      }
      return extension;
    });
    final mediaSizeText =
        useMessageConverter(converter: (state) => filesize(state.mediaSize));

    return MessageBubble(
      outerTimeAndStatusWidget: const MessageDatetimeAndStatus(),
      child: InteractiveDecoratedBox(
        onTap: () async {
          final message = context.message;
          if (message.mediaStatus == MediaStatus.canceled) {
            if (message.relationship == UserRelationship.me &&
                message.mediaUrl?.isNotEmpty == true) {
              await context.accountServer.reUploadAttachment(message);
            } else {
              await context.accountServer.downloadAttachment(message);
            }
          } else if (message.mediaStatus == MediaStatus.done &&
              message.mediaUrl != null) {
            if (message.mediaUrl?.isEmpty ?? true) return;

            final path = context.accountServer
                .convertMessageAbsolutePath(message, isTranscriptPage);
            if (Platform.isAndroid || Platform.isIOS) {
              await OpenFile.open(path);
            } else {
              await saveFileToSystem(context, path,
                  suggestName: message.mediaName);
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
                  if (relationship == UserRelationship.me &&
                      mediaUrl?.isNotEmpty == true) {
                    return const StatusUpload();
                  } else {
                    return const StatusDownload();
                  }
                case MediaStatus.pending:
                  return const StatusPending();
                case MediaStatus.expired:
                  return const StatusWarning();
                default:
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
                children: [
                  Text(
                    mediaName,
                    style: TextStyle(
                      fontSize: MessageItemWidget.secondaryFontSize,
                      color: context.theme.text,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    mediaSizeText,
                    style: TextStyle(
                      fontSize: MessageItemWidget.tertiaryFontSize,
                      color: context.theme.secondaryText,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
