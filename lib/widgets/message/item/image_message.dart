import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset, Message;
import 'package:flutter_app/enum/media_status.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';

import '../../interacter_decorated_box.dart';
import '../../status.dart';
import '../message_bubble.dart';
import '../message_datetime.dart';
import '../message_status.dart';

class ImageMessageWidget extends StatelessWidget {
  const ImageMessageWidget({
    Key? key,
    required this.message,
    required this.isCurrentUser,
  }) : super(key: key);

  final MessageItem message;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, boxConstraints) {
          final maxWidth = min(boxConstraints.maxWidth * 0.6, 200);
          final width = min(message.mediaWidth!, maxWidth).toDouble();
          final scale = message.mediaWidth! / message.mediaHeight!;
          final height = width / scale;

          return InteractableDecoratedBox(
            onTap: () {
              if (message.mediaStatus == MediaStatus.canceled) {
                if (message.relationship == UserRelationship.me &&
                    message.mediaUrl?.isNotEmpty == true) {
                  // TODO upload
                  context.read<AccountServer>().uploadAttachment(message);
                } else {
                  context.read<AccountServer>().downloadAttachment(message);
                }
              }
            },
            child: MessageBubble(
              showNip: false,
              isCurrentUser: isCurrentUser,
              padding: const EdgeInsets.all(2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: height,
                  width: width,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (message.thumbImage != null &&
                          message.mediaUrl == null)
                        Image.memory(
                          base64Decode(message.thumbImage!),
                          fit: BoxFit.cover,
                        ),
                      if (message.mediaUrl != null)
                        Image.file(
                          File(message.mediaUrl!),
                          fit: BoxFit.cover,
                        ),
                      Center(
                        child: Builder(
                          builder: (BuildContext context) {
                            switch (message.mediaStatus) {
                              case MediaStatus.canceled:
                                if (message.relationship ==
                                        UserRelationship.me &&
                                    message.mediaUrl?.isNotEmpty == true)
                                  return const StatusUpload();
                                else
                                  return const StatusDownload();
                                break;
                              case MediaStatus.pending:
                                return const StatusPending();
                              case MediaStatus.expired:
                                return const StatusWarning();
                              default:
                                return const SizedBox();
                            }
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: DecoratedBox(
                          decoration: const ShapeDecoration(
                            color: Color.fromRGBO(0, 0, 0, 0.3),
                            shape: StadiumBorder(),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 3,
                              horizontal: 5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MessageDatetime(dateTime: message.createdAt),
                                MessageStatusWidget(status: message.status),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}
