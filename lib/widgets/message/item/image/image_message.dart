import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';

import '../../../../account/account_server.dart';
import '../../../../db/mixin_database.dart' hide Offset, Message;
import '../../../../enum/media_status.dart';
import '../../../image.dart';
import '../../../interacter_decorated_box.dart';
import '../../../status.dart';
import '../../message_bubble.dart';
import '../../message_datetime_and_status.dart';
import 'image_preview_portal.dart';

class ImageMessageWidget extends StatelessWidget {
  const ImageMessageWidget({
    Key? key,
    required this.showNip,
    required this.message,
    required this.isCurrentUser,
  }) : super(key: key);

  final bool showNip;
  final MessageItem message;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) => ImageMessageLayout(
        imageWidthInPixel: message.mediaWidth!,
        imageHeightInPixel: message.mediaHeight!,
        builder: (context, width, height) => MessageBubble(
          messageId: message.messageId,
          quoteMessageId: message.quoteId,
          quoteMessageContent: message.quoteContent,
          isCurrentUser: isCurrentUser,
          padding: EdgeInsets.zero,
          showNip: showNip,
          includeNip: true,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: InteractableDecoratedBox(
              onTap: () {
                switch (message.mediaStatus) {
                  case MediaStatus.done:
                    ImagePreviewPage.push(
                      context,
                      conversationId: message.conversationId,
                      messageId: message.messageId,
                    );
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
                      errorBuilder: (_, __, ___) => ImageByBlurHashOrBase64(
                          imageData: message.thumbImage!),
                    ),
                    Center(
                      child: Builder(
                        builder: (BuildContext context) {
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
                              return const SizedBox();
                          }
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: isCurrentUser ? 12 : 4,
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
                          child: MessageDatetimeAndStatus(
                            isCurrentUser: isCurrentUser,
                            color: Colors.white,
                            message: message,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// The signature of the [ImageMessageLayout] builder function.
typedef ImageLayoutBuilder = Widget Function(
    BuildContext context, double width, double height);

/// Measure layout constraints and image actual size.
/// calculate a suitable size to layout image.
///
/// [builder] the aspectRatio (width/height) was constrained, which might not
/// equals the aspectRatio of origin image. because some image might too long
/// or too short.
class ImageMessageLayout extends StatelessWidget {
  const ImageMessageLayout({
    Key? key,
    required this.builder,
    required this.imageWidthInPixel,
    required this.imageHeightInPixel,
  })  : assert(imageHeightInPixel > 0),
        assert(imageWidthInPixel > 0),
        super(key: key);

  final ImageLayoutBuilder builder;

  final int imageWidthInPixel;
  final int imageHeightInPixel;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, boxConstraints) {
        final maxWidth = min(boxConstraints.maxWidth * 0.6, 300.0);
        final minWidth = max(boxConstraints.maxWidth * 0.2, 100.0);
        final width = max(
            min(imageWidthInPixel / MediaQuery.of(context).devicePixelRatio,
                maxWidth),
            minWidth);
        final aspectRatio = imageWidthInPixel / imageHeightInPixel;
        final height = width / aspectRatio;
        return builder(context, width, height);
      });
}
