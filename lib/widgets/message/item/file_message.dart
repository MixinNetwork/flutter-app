import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mime/mime.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:path/path.dart';

import '../../../constants/brightness_theme_data.dart';
import '../../../db/mixin_database.dart' hide Offset, Message;
import '../../../enum/media_status.dart';

import '../../../utils/extension/extension.dart';
import '../../interacter_decorated_box.dart';
import '../../status.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';

class FileMessage extends StatelessWidget {
  const FileMessage({
    Key? key,
    required this.showNip,
    required this.isCurrentUser,
    required this.message,
  }) : super(key: key);

  final bool showNip;
  final bool isCurrentUser;
  final MessageItem message;

  @override
  Widget build(BuildContext context) => MessageBubble(
        messageId: message.messageId,
        quoteMessageId: message.quoteId,
        quoteMessageContent: message.quoteContent,
        showNip: showNip,
        isCurrentUser: isCurrentUser,
        outerTimeAndStatusWidget: MessageDatetimeAndStatus(
          isCurrentUser: isCurrentUser,
          message: message,
        ),
        child: InteractableDecoratedBox(
          onTap: () async {
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
              final path = await getSavePath(
                confirmButtonText: context.l10n.save,
                suggestedName: message.mediaName ?? basename(message.mediaUrl!),
              );
              if (path?.isEmpty ?? true) return;
              await File(context
                      .accountServer
                      .convertMessageAbsolutePath(message))
                  .copy(path!);
            } else if (message.mediaStatus == MediaStatus.pending) {
              context
                  .accountServer
                  .cancelProgressAttachmentJob(message.messageId);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: Builder(builder: (context) {
                  switch (message.mediaStatus) {
                    case MediaStatus.canceled:
                      if (message.relationship == UserRelationship.me &&
                          message.mediaUrl?.isNotEmpty == true) {
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

                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.theme.statusBackground,
                    ),
                    child: SizedBox.fromSize(
                      size: const Size.square(38),
                      child: Center(
                        child: Builder(builder: (context) {
                          var extension = 'FILE';
                          if (message.mediaName != null) {
                            final _lookupMimeType =
                                lookupMimeType(message.mediaName!);
                            if (_lookupMimeType != null) {
                              extension = extensionFromMime(_lookupMimeType)
                                  .toUpperCase();
                            }
                          }
                          return Text(
                            extension,
                            style: TextStyle(
                              fontSize: 12,
                              // force light style
                              color: lightBrightnessThemeData.secondaryText,
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.mediaName ?? '',
                    style: TextStyle(
                      fontSize: MessageItemWidget.secondaryFontSize,
                      color: context.theme.text,
                    ),
                  ),
                  Text(
                    filesize(message.mediaSize),
                    style: TextStyle(
                      fontSize: MessageItemWidget.tertiaryFontSize,
                      color: context.theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
