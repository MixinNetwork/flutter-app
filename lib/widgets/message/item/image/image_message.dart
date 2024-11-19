import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../../enum/media_status.dart';
import '../../../../utils/extension/extension.dart';
import '../../../cache_image.dart';
import '../../../image.dart';
import '../../../interactive_decorated_box.dart';
import '../../../status.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_datetime_and_status.dart';
import '../../message_style.dart';
import '../text/text_message.dart';
import '../transcript_message.dart';
import '../unknown_message.dart';
import 'image_preview_page.dart';

class ImageMessageWidget extends HookConsumerWidget {
  const ImageMessageWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaWidth =
        useMessageConverter(converter: (state) => state.mediaWidth);
    final mediaHeight =
        useMessageConverter(converter: (state) => state.mediaHeight);
    final caption = useMessageConverter(converter: (state) => state.caption);

    if (mediaWidth == null || mediaHeight == null) {
      return const UnknownMessage();
    }

    final hasCaption = caption != null && caption.trim().isNotEmpty;
    return ImageMessageLayout(
      imageWidthInPixel: mediaWidth,
      imageHeightInPixel: mediaHeight,
      builder: (context, width, height) => MessageBubble(
        showBubble: hasCaption,
        padding: EdgeInsets.zero,
        includeNip: !hasCaption,
        clip: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MessageImage(
                size: Size(width, height),
                showStatus: !hasCaption,
              ),
              if (hasCaption) ImageCaption(caption: caption),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageImage extends HookConsumerWidget {
  const MessageImage({
    required this.showStatus,
    super.key,
    this.size,
  });

  final Size? size;
  final bool showStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTranscriptPage = useIsTranscriptPage();
    final type = useMessageConverter(converter: (state) => state.type);
    final conversationId =
        useMessageConverter(converter: (state) => state.conversationId);
    final isCurrentUser = useIsCurrentUser();
    final thumbImage =
        useMessageConverter(converter: (state) => state.thumbImage ?? '');
    final mediaUrl = useMessageConverter(converter: (state) => state.mediaUrl);

    final isUnDownloadGiphyGif = useMessageConverter(
      converter: (message) =>
          message.mediaMimeType == 'image/gif' &&
          (message.mediaSize == null || message.mediaSize == 0),
    );

    final Widget thumbWidget;
    if (isUnDownloadGiphyGif) {
      // un-downloaded giphy gif image.
      thumbWidget = MixinImage.network(
        thumbImage,
        placeholder: () => ColoredBox(color: context.theme.secondaryText),
      );
    } else {
      thumbWidget = ImageByBlurHashOrBase64(imageData: thumbImage);
    }

    final relationship =
        useMessageConverter(converter: (state) => state.relationship);

    final isMessageSentOut = (isTranscriptPage &&
            TranscriptPage.of(context)?.relationship == UserRelationship.me) ||
        (!isTranscriptPage && relationship == UserRelationship.me);

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
          case MediaStatus.canceled:
            if (message.mediaUrl?.isNotEmpty == true && isMessageSentOut) {
              if (isTranscriptPage) {
                final transcriptMessageId =
                    TranscriptPage.of(context)?.messageId;
                assert(
                    transcriptMessageId != null, 'transcriptMessageId is null');
                if (transcriptMessageId != null) {
                  context.accountServer.reUploadTranscriptAttachment(
                    transcriptMessageId,
                  );
                }
              } else if (isUnDownloadGiphyGif) {
                context.accountServer.reUploadGiphyGif(message);
              } else {
                context.accountServer.reUploadAttachment(message);
              }
            } else {
              context.accountServer.downloadAttachment(message.messageId);
            }
          case MediaStatus.pending:
            context.accountServer
                .cancelProgressAttachmentJob(message.messageId);
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
            MixinImage.file(
              File(context.accountServer.convertAbsolutePath(
                  type, conversationId, mediaUrl, isTranscriptPage)),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => thumbWidget,
            ),
            Center(
              child: HookBuilder(
                builder: (BuildContext context) {
                  final mediaStatus = useMessageConverter(
                      converter: (state) => state.mediaStatus);

                  switch (mediaStatus) {
                    case MediaStatus.canceled:
                      return isMessageSentOut && mediaUrl?.isNotEmpty == true
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
    required this.builder,
    required this.imageWidthInPixel,
    required this.imageHeightInPixel,
    super.key,
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
                min(imageWidthInPixel / MediaQuery.devicePixelRatioOf(context),
                    maxWidth),
                minWidth)
            .toDouble();
        final aspectRatio = imageWidthInPixel / imageHeightInPixel;
        final height = min(
          width / aspectRatio,
          MediaQuery.sizeOf(context).height * 2 / 3,
        );
        return builder(context, width, height);
      });
}

class ImageCaption extends StatelessWidget {
  const ImageCaption({required this.caption, super.key});

  final String caption;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: MessageTextWidget(
          color: context.theme.text,
          fontSize: context.messageStyle.primaryFontSize,
          content: caption,
        ),
      );
}
