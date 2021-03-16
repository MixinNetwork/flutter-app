import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset, Message;
import 'package:flutter_app/enum/media_status.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/message/item/quote_message.dart';
import 'package:mime/mime.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/generated/l10n.dart';

import '../../interacter_decorated_box.dart';
import '../../status.dart';
import '../message_bubble.dart';
import '../message_datetime.dart';
import '../message_status.dart';

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
        quoteMessage: QuoteMessage(
          id: message.quoteId,
          content: message.quoteContent,
        ),
        showNip: showNip,
        isCurrentUser: isCurrentUser,
        outerTimeAndStatusWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MessageDatetime(dateTime: message.createdAt),
            if (isCurrentUser) MessageStatusWidget(status: message.status),
          ],
        ),
        child: InteractableDecoratedBox(
          onTap: () async {
            if (message.mediaStatus == MediaStatus.canceled) {
              if (message.relationship == UserRelationship.me &&
                  message.mediaUrl?.isNotEmpty == true) {
                context.read<AccountServer>().uploadAttachment(message);
              } else {
                context.read<AccountServer>().downloadAttachment(message);
              }
            } else if (message.mediaStatus == MediaStatus.done &&
                message.mediaUrl != null) {
              if (message.mediaUrl?.isEmpty ?? true) return;
              final path = await getSavePath(
                confirmButtonText: Localization.of(context).save,
                suggestedName: message.mediaName ?? basename(message.mediaUrl!),
              );
              if (path?.isEmpty ?? true) return;
              await File(message.mediaUrl!).copy(path!);
            }
          },
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: Builder(builder: (context) {
                      switch (message.mediaStatus) {
                        case MediaStatus.canceled:
                          if (message.relationship == UserRelationship.me &&
                              message.mediaUrl?.isNotEmpty == true)
                            return const StatusUpload();
                          else
                            return const StatusDownload();
                        case MediaStatus.pending:
                          return const StatusPending();
                        case MediaStatus.expired:
                          return const StatusWarning();
                        default:
                          break;
                      }

                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: BrightnessData.themeOf(context).listSelected,
                        ),
                        child: SizedBox.fromSize(
                          size: const Size.square(38),
                          child: Center(
                            child: Builder(builder: (context) {
                              var extension = 'FILE';
                              if (message.mediaName != null) {
                                final _lookupMimeType =
                                    lookupMimeType(message.mediaName!);
                                if (_lookupMimeType != null)
                                  extension = extensionFromMime(_lookupMimeType)
                                      .toUpperCase();
                              }
                              return Text(
                                extension,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: BrightnessData.themeOf(context)
                                      .secondaryText,
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
                          fontSize: 14,
                          color: BrightnessData.themeOf(context).text,
                        ),
                      ),
                      Text(
                        filesize(message.mediaSize),
                        style: TextStyle(
                          fontSize: 12,
                          color: BrightnessData.themeOf(context).secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
