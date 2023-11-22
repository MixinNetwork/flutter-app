import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../constants/resources.dart';
import '../../../../enum/media_status.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/platform.dart';
import '../../../../utils/uri_utils.dart';
import '../../../cache_image.dart';
import '../../../image.dart';
import '../../../interactive_decorated_box.dart';
import '../../../status.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_datetime_and_status.dart';
import '../../message_style.dart';
import '../transcript_message.dart';
import 'video_preview_page.dart';

const _kDefaultVideoSize = 200;

class VideoMessageWidget extends HookConsumerWidget {
  const VideoMessageWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaWidth =
        useMessageConverter(converter: (state) => state.mediaWidth);
    final mediaHeight =
        useMessageConverter(converter: (state) => state.mediaHeight);

    return LayoutBuilder(
      builder: (context, boxConstraints) {
        final maxWidth = min(boxConstraints.maxWidth * 0.6, 200);
        final width =
            min(mediaWidth ?? _kDefaultVideoSize, maxWidth).toDouble();
        final scale = (mediaWidth ?? _kDefaultVideoSize) /
            (mediaHeight ?? _kDefaultVideoSize);
        final height = width / scale;

        return MessageBubble(
          padding: EdgeInsets.zero,
          includeNip: true,
          clip: true,
          child: SizedBox(
            width: width,
            height: height,
            child: const MessageVideo(),
          ),
        );
      },
    );
  }
}

class MessageVideo extends HookConsumerWidget {
  const MessageVideo({
    super.key,
    this.overlay,
  });

  final Widget? overlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentUser = useIsCurrentUser();
    final isTranscriptPage = useIsTranscriptPage();

    final thumbImage =
        useMessageConverter(converter: (state) => state.thumbImage);
    final thumbUrl = useMessageConverter(converter: (state) => state.thumbUrl);

    final relationship =
        useMessageConverter(converter: (state) => state.relationship);

    final isMessageSentOut = (isTranscriptPage &&
            TranscriptPage.of(context)?.relationship == UserRelationship.me) ||
        (!isTranscriptPage && relationship == UserRelationship.me);

    return InteractiveDecoratedBox(
      onTap: () {
        final message = context.message;
        if (message.mediaStatus == MediaStatus.canceled) {
          if (isMessageSentOut && message.mediaUrl?.isNotEmpty == true) {
            if (isTranscriptPage) {
              final transcriptMessageId = TranscriptPage.of(context)!.messageId;
              context.accountServer
                  .reUploadTranscriptAttachment(transcriptMessageId);
            } else {
              context.accountServer.reUploadAttachment(message);
            }
          } else {
            context.accountServer.downloadAttachment(message.messageId);
          }
        } else if (message.mediaStatus == MediaStatus.done &&
            message.mediaUrl != null) {
          final path = context.accountServer
              .convertMessageAbsolutePath(message, isTranscriptPage);
          if (kPlatformIsDarwin) {
            showVideoPreviewPage(context, path);
          } else if (Platform.isIOS || Platform.isAndroid) {
            OpenFile.open(path);
          } else {
            openUri(context, Uri.file(path).toString());
          }
        } else if (message.mediaStatus == MediaStatus.pending) {
          context.accountServer.cancelProgressAttachmentJob(message.messageId);
        } else if (message.type.isLive && message.mediaUrl != null) {
          launchUrlString(message.mediaUrl!);
        }
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbImage != null)
              ImageByBlurHashOrBase64(imageData: thumbImage),
            if (thumbUrl != null) CacheImage(thumbUrl),
            overlay ?? _VideoMessageOverlayInfo(isCurrentUser: isCurrentUser),
          ],
        ),
      ),
    );
  }
}

class VideoMessageMediaStatusWidget extends HookConsumerWidget {
  const VideoMessageMediaStatusWidget({
    super.key,
    this.done,
  });

  final Widget? done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaStatus =
        useMessageConverter(converter: (state) => state.mediaStatus);
    final relationship =
        useMessageConverter(converter: (state) => state.relationship);
    final mediaUrl = useMessageConverter(converter: (state) => state.mediaUrl);

    final isTranscriptPage = useIsTranscriptPage();
    final isMessageSentOut = (isTranscriptPage &&
            TranscriptPage.of(context)?.relationship == UserRelationship.me) ||
        (!isTranscriptPage && relationship == UserRelationship.me);

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
        return done ??
            SvgPicture.asset(
              Resources.assetsImagesPlaySvg,
              width: 38,
              height: 38,
            );
    }
  }
}

class _VideoMessageOverlayInfo extends HookConsumerWidget {
  const _VideoMessageOverlayInfo({
    required this.isCurrentUser,
  });

  final bool isCurrentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVideo =
        useMessageConverter(converter: (state) => state.type.isVideo);
    return Stack(
      fit: StackFit.expand,
      children: [
        const Center(
          child: VideoMessageMediaStatusWidget(),
        ),
        if (isVideo)
          HookBuilder(builder: (context) {
            final durationText = useMessageConverter(
              converter: (state) => Duration(
                      milliseconds:
                          int.tryParse(state.mediaDuration ?? '') ?? 0)
                  .asMinutesSeconds,
            );
            return Positioned(
              top: 6,
              left: isCurrentUser ? 6 : 14,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(0, 0, 0, 0.3),
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    durationText,
                    style: TextStyle(
                      fontSize: context.messageStyle.tertiaryFontSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }),
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
    );
  }
}
