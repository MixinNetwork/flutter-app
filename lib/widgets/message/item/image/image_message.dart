import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset, Message;
import 'package:flutter_app/enum/media_status.dart';
import 'package:flutter_app/widgets/image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';

import '../../../full_screen_portal.dart';
import '../../../interacter_decorated_box.dart';
import '../../../status.dart';
import '../../message_bubble.dart';
import '../../message_datetime.dart';
import '../../message_status.dart';
import '../quote_message.dart';
import 'image_preview_portal.dart';

class ImageMessageWidget extends StatelessWidget {
  const ImageMessageWidget({
    Key? key,
    required this.message,
    required this.isCurrentUser,
  }) : super(key: key);

  final MessageItem message;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) => FullScreenPortal(
        builder: (BuildContext context) => _ImageMessage(
          message: message,
          isCurrentUser: isCurrentUser,
        ),
        portalBuilder: (BuildContext context) => FutureBuilder<int>(
          future: context
              .read<AccountServer>()
              .database
              .messagesDao
              .mediaMessageRowIdByConversationId(
                message.conversationId,
                message.messageId,
              )
              .getSingle(),
          builder: (context, snapshot) {
            if (snapshot.data == null) return const SizedBox();
            return ImagePreviewPortal(
              conversationId: message.conversationId,
              messagesDao: context.read<AccountServer>().database.messagesDao,
              index: snapshot.data!,
            );
          },
        ),
      );
}

class _ImageMessage extends StatelessWidget {
  const _ImageMessage({
    Key? key,
    required this.message,
    required this.isCurrentUser,
  }) : super(key: key);

  final MessageItem message;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, boxConstraints) {
        final maxWidth = min(boxConstraints.maxWidth * 0.6, 200);
        final width = min(message.mediaWidth!, maxWidth).toDouble();
        final scale = message.mediaWidth! / message.mediaHeight!;
        final height = width / scale;

        return MessageBubble(
          quoteMessage: QuoteMessage(
            id: message.quoteId,
            content: message.quoteContent,
          ),
          showNip: false,
          isCurrentUser: isCurrentUser,
          padding: const EdgeInsets.all(2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: InteractableDecoratedBox(
              onTap: () {
                switch (message.mediaStatus) {
                  case MediaStatus.done:
                    FullScreenPortal.of(context).emit(true);
                    break;
                  case MediaStatus.canceled:
                    if (message.relationship == UserRelationship.me &&
                        message.mediaUrl?.isNotEmpty == true) {
                      context.read<AccountServer>().reUploadAttachment(message);
                    } else {
                      context.read<AccountServer>().downloadAttachment(message);
                    }
                    break;
                  default:
                    break;
                }
              },
              child: SizedBox(
                height: height,
                width: width,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(message.mediaUrl ?? ''),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          ImageByBase64(message.thumbImage!),
                    ),
                    Center(
                      child: Builder(
                        builder: (BuildContext context) {
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
}
