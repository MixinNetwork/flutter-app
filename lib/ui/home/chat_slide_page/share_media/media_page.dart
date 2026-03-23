import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../../../constants/resources.dart';
import '../../../../db/database.dart';
import '../../../../db/mixin_database.dart';
import '../../../../enum/message_category.dart';
import '../../../../paging/load_more_paging_controller.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../widgets/message/item/image/image_message.dart';
import '../../../../widgets/message/item/video/video_message.dart';
import '../../../../widgets/message/message.dart';
import '../../../provider/database_provider.dart';
import '../../../provider/ui_context_providers.dart';
import '../../providers/home_scope_providers.dart';
import '../shared_media_page.dart';

typedef _MediaPageArgs = ({
  Database database,
  String conversationId,
  int size,
});

final _mediaPagingControllerProvider = Provider.autoDispose
    .family<LoadMorePagingController<MessageItem>, _MediaPageArgs>((ref, args) {
      final messageDao = args.database.messageDao;
      final controller = LoadMorePagingController<MessageItem>(
        reloadData: () =>
            messageDao.mediaMessages(args.conversationId, args.size, 0).get(),
        loadMoreData: (list) async {
          if (list.isEmpty) return [];
          final last = list.last;
          final info = await messageDao.messageOrderInfo(last.messageId);
          if (info == null) return [];
          final items = await messageDao
              .mediaMessagesBefore(info, args.conversationId, args.size)
              .get();
          return [...list, ...items];
        },
        isSameKey: (a, b) => a.messageId == b.messageId,
      );
      final subscription = messageDao
          .watchInsertOrReplaceMessageStream(args.conversationId)
          .switchMap<MessageItem>((value) async* {
            for (final item in value) {
              yield item;
            }
          })
          .where(
            (event) => [
              MessageCategory.plainImage,
              MessageCategory.signalImage,
              MessageCategory.plainVideo,
              MessageCategory.signalVideo,
            ].contains(event.type),
          )
          .listen(controller.insertOrReplace);
      ref.onDispose(subscription.cancel);
      ref.onDispose(controller.dispose);
      return controller;
    });

final _mediaGroupedItemsProvider = StreamProvider.autoDispose
    .family<Map<DateTime, List<MessageItem>>, _MediaPageArgs>((ref, args) {
      final controller = ref.watch(_mediaPagingControllerProvider(args));
      return (() async* {
        Map<DateTime, List<MessageItem>> group(List<MessageItem> list) =>
            groupBy<MessageItem, DateTime>(list, (messageItem) {
              final local = messageItem.createdAt.toLocal();
              return DateTime(local.year, local.month, local.day);
            });

        yield group(controller.state.list);
        yield* controller.stream.map((state) => group(state.list)).distinct();
      })();
    });

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
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final column = useMemoized(() => maxHeight / 90 * 2, [maxHeight]).toInt();
    final routeMode = ref.watch(
      chatSideControllerProvider.select((value) => value.routeMode),
    );
    final database = ref.read(databaseProvider).requireValue;
    final size = column * (routeMode ? 4 : 3);
    final args = (
      database: database,
      conversationId: conversationId,
      size: size,
    );
    final mediaController = ref.watch(_mediaPagingControllerProvider(args));
    final map =
        ref.watch(_mediaGroupedItemsProvider(args)).value ??
        const <DateTime, List<MessageItem>>{};

    final scrollController = useScrollController();

    if (map.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              Resources.assetsImagesEmptyImageSvg,
              colorFilter: ColorFilter.mode(
                theme.secondaryText.withValues(alpha: 0.4),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noMedia,
              style: TextStyle(fontSize: 12, color: theme.secondaryText),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is! ScrollUpdateNotification) return false;
        if (notification.scrollDelta == null) return false;
        if (notification.scrollDelta! < 0) return false;

        final dimension = notification.metrics.viewportDimension / 2;

        if (notification.metrics.maxScrollExtent - notification.metrics.pixels <
            dimension) {
          mediaController.loadMore();
        }

        return false;
      },
      child: CustomScrollView(
        controller: scrollController,
        slivers: map.entries
            .map(
              (e) => MultiSliver(
                pushPinnedChildren: true,
                children: [
                  SliverPinnedHeader(
                    child: Container(
                      color: theme.primary,
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        DateFormat.yMMMd().format(e.key.toLocal()),
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.secondaryText,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((
                        context,
                        index,
                      ) {
                        final message = e.value[index];
                        return _Item(message: message);
                      }, childCount: e.value.length),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: routeMode ? 4 : 3,
                        mainAxisSpacing: 5,
                        crossAxisSpacing: 5,
                      ),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
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
