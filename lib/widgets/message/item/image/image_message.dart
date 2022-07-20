import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../../enum/media_status.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/hook.dart';
import '../../../cache_image.dart';
import '../../../image.dart';
import '../../../interactive_decorated_box.dart';
import '../../../status.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_datetime_and_status.dart';
import '../unknown_message.dart';
import 'image_preview_page.dart';

class ImageMessageWidget extends HookWidget {
  const ImageMessageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaWidth =
        useMessageConverter(converter: (state) => state.mediaWidth);
    final mediaHeight =
        useMessageConverter(converter: (state) => state.mediaHeight);

    if (mediaWidth == null || mediaHeight == null) {
      return const UnknownMessage();
    }

    return ImageMessageLayout(
      imageWidthInPixel: mediaWidth,
      imageHeightInPixel: mediaHeight,
      builder: (context, width, height) => MessageBubble(
        padding: EdgeInsets.zero,
        includeNip: true,
        clip: true,
        child: MessageImage(
          size: Size(width, height),
          showStatus: true,
        ),
      ),
    );
  }
}

class MessageImage extends HookWidget {
  const MessageImage({
    super.key,
    this.size,
    required this.showStatus,
  });

  final Size? size;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final isTranscriptPage = useIsTranscriptPage();
    final type = useMessageConverter(converter: (state) => state.type);
    final conversationId =
        useMessageConverter(converter: (state) => state.conversationId);
    final isCurrentUser = useIsCurrentUser();
    final thumbImage =
        useMessageConverter(converter: (state) => state.thumbImage ?? '');
    final mediaUrl = useMessageConverter(converter: (state) => state.mediaUrl);
    final mediaMimeType =
        useMessageConverter(converter: (state) => state.mediaMimeType);
    final mediaSize =
        useMessageConverter(converter: (state) => state.mediaSize);

    final playing = useImagePlaying(context);

    final isUnDownloadGiphyGif = useMessageConverter(
      converter: (message) =>
          message.mediaMimeType == 'image/gif' &&
          (mediaSize == null || mediaSize == 0),
    );

    final Widget thumbWidget;
    if (isUnDownloadGiphyGif) {
      // un-downloaded giphy gif image.
      thumbWidget = CacheImage(
        thumbImage,
        controller: playing,
        placeholder: () => ColoredBox(color: context.theme.secondaryText),
      );
    } else {
      thumbWidget = ImageByBlurHashOrBase64(imageData: thumbImage);
    }

    return InteractiveDecoratedBox(
      onTap: () {
        final message = context.message;
        switch (message.mediaStatus) {
          case MediaStatus.done:
            ImagePreviewPage.push(
              context,
              conversationId: message.conversationId,
              messageId: message.messageId,
              isTranscriptPage: isTranscriptPage,
            );
            break;
          case MediaStatus.canceled:
            if (message.relationship == UserRelationship.me &&
                message.mediaUrl?.isNotEmpty == true) {
              if (isUnDownloadGiphyGif) {
                context.accountServer.reUploadGiphyGif(message);
              } else {
                context.accountServer.reUploadAttachment(message);
              }
            } else {
              context.accountServer.downloadAttachment(message.messageId);
            }
            break;
          case MediaStatus.pending:
            context.accountServer
                .cancelProgressAttachmentJob(message.messageId);
            break;
          case null:
          case MediaStatus.expired:
          case MediaStatus.read:
            break;
        }
      },
      child: SizedBox.fromSize(
        size: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: MixinFileImage(
                File(context.accountServer.convertAbsolutePath(
                    type, conversationId, mediaUrl, isTranscriptPage)),
                controller: playing,
              ),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => thumbWidget,
            ),
            Center(
              child: HookBuilder(
                builder: (BuildContext context) {
                  final mediaStatus = useMessageConverter(
                      converter: (state) => state.mediaStatus);
                  final relationship = useMessageConverter(
                      converter: (state) => state.relationship);

                  switch (mediaStatus) {
                    case MediaStatus.canceled:
                      return relationship == UserRelationship.me &&
                              mediaUrl?.isNotEmpty == true
                          ? const StatusUpload()
                          : const StatusDownload();
                    case MediaStatus.pending:
                      return const StatusPending();
                    case MediaStatus.expired:
                      return const StatusWarning();
                    case MediaStatus.done:
                    case MediaStatus.read:
                    case null:
                      return const SizedBox();
                  }
                },
              ),
            ),
            if (showStatus)
              Positioned(
                bottom: 4,
                right: isCurrentUser ? 12 : 4,
                child: const DecoratedBox(
                  decoration: ShapeDecoration(
                    color: Color.fromRGBO(0, 0, 0, 0.3),
                    shape: StadiumBorder(),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 3,
                      horizontal: 5,
                    ),
                    child: MessageDatetimeAndStatus(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
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
    super.key,
    required this.builder,
    required this.imageWidthInPixel,
    required this.imageHeightInPixel,
  })  : assert(imageHeightInPixel > 0),
        assert(imageWidthInPixel > 0);

  final ImageLayoutBuilder builder;

  final int imageWidthInPixel;
  final int imageHeightInPixel;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, boxConstraints) {
        final maxWidth = min(boxConstraints.maxWidth * 0.6, 300);
        final minWidth = max(boxConstraints.maxWidth * 0.2, 200);
        final width = max(
                min(imageWidthInPixel / MediaQuery.of(context).devicePixelRatio,
                    maxWidth),
                minWidth)
            .toDouble();
        final aspectRatio = imageWidthInPixel / imageHeightInPixel;
        final height = min(
          width / aspectRatio,
          MediaQuery.of(context).size.height * 2 / 3,
        );
        return builder(context, width, height);
      });
}
