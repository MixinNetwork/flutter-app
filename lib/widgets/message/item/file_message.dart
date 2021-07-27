import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mime/mime.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

import '../../../account/account_server.dart';
import '../../../constants/brightness_theme_data.dart';
import '../../../db/mixin_database.dart' hide Offset, Message;
import '../../../enum/media_status.dart';
import '../../../generated/l10n.dart';
import '../../brightness_observer.dart';
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
                await context.read<AccountServer>().reUploadAttachment(message);
              } else {
                await context.read<AccountServer>().downloadAttachment(message);
              }
            } else if (message.mediaStatus == MediaStatus.done &&
                message.mediaUrl != null) {
              if (message.mediaUrl?.isEmpty ?? true) return;
              final path = await getSavePath(
                confirmButtonText: Localization.of(context).save,
                suggestedName: message.mediaName ?? basename(message.mediaUrl!),
              );
              if (path?.isEmpty ?? true) return;
              await File(context
                      .read<AccountServer>()
                      .convertMessageAbsolutePath(message))
                  .copy(path!);
            } else if (message.mediaStatus == MediaStatus.pending) {
              context
                  .read<AccountServer>()
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
                      color: BrightnessData.themeOf(context).statusBackground,
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
                              fontSize: MessageItemWidget.subtextFontSize,
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
                      fontSize: MessageItemWidget.textFontSize,
                      color: BrightnessData.themeOf(context).text,
                    ),
                  ),
                  Text(
                    filesize(message.mediaSize),
                    style: TextStyle(
                      fontSize: MessageItemWidget.subtextFontSize,
                      color: BrightnessData.themeOf(context).secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
