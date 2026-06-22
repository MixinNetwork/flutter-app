import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/resources.dart';
import '../../../../db/mixin_database.dart';
import '../../../../enum/message_category.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../widgets/message/item/image/image_message.dart';
import '../../../../widgets/message/item/video/video_message.dart';
import '../../../../widgets/message/message.dart';
import '../../desktop_shell_layout.dart';
import '../../notifier/chat_side_notifier.dart';
import '../shared_media_page.dart';
import 'shared_media_list.dart';

class MediaPage extends HookConsumerWidget {
  const MediaPage({
    required this.maxHeight,
    required this.conversationId,
    super.key,
  });

  final double maxHeight;
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatSideNotifier = context.read<ChatSideNotifier>();
    final columnCount = DesktopShellLayout.chatSideMediaColumnCount(
      routeMode: chatSideNotifier.isRouteMode,
    );
    final pageSize = DesktopShellLayout.chatSideMediaPageSize(
      maxHeight: maxHeight,
      routeMode: chatSideNotifier.isRouteMode,
    );
    final messageDao = context.database.messageDao;
    return SharedMediaList(
      conversationId: conversationId,
      pageSize: pageSize,
      categories: const {
        MessageCategory.plainImage,
        MessageCategory.signalImage,
        MessageCategory.plainVideo,
        MessageCategory.signalVideo,
      },
      emptyAsset: Resources.assetsImagesEmptyImageSvg,
      emptyText: context.l10n.noMedia,
      reloadData: (pageSize) =>
          messageDao.mediaMessages(conversationId, pageSize, 0).get(),
      loadBefore: (info, pageSize) =>
          messageDao.mediaMessagesBefore(info, conversationId, pageSize).get(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
      ),
      itemBuilder: (context, message) => _Item(message: message),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.message});

  final MessageItem message;

  @override
  Widget build(BuildContext context) {
    final Widget widget;

    if (message.type.isImage) {
      widget = const MessageImage(showStatus: false);
    } else if (message.type.isVideo) {
      widget = const _ItemVideo();
    } else {
      assert(false, 'Unsupported message type: ${message.type}');
      widget = const SizedBox();
    }
    return ShareMediaItemMenuWrapper(
      messageId: message.messageId,
      child: MessageContext.fromMessageItem(message: message, child: widget),
    );
  }
}

class _ItemVideo extends HookConsumerWidget {
  const _ItemVideo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final durationText = useMessageConverter(
      converter: (state) => Duration(
        milliseconds: int.tryParse(state.mediaDuration ?? '') ?? 0,
      ).asMinutesSeconds,
    );
    return MessageVideo(
      overlay: Stack(
        fit: StackFit.expand,
        children: [
          const Center(child: VideoMessageMediaStatusWidget(done: SizedBox())),
          Positioned(
            left: 0,
            bottom: 0,
            right: 0,
            height: 20,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 5),
                  SvgPicture.asset(Resources.assetsImagesVideoMessageSvg),
                  const SizedBox(width: 8),
                  Text(
                    durationText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
