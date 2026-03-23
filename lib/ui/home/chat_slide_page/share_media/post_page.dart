import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
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
import '../../../../widgets/message/item/post_message.dart';
import '../../../../widgets/message/message.dart';
import '../../../provider/database_provider.dart';
import '../../../provider/ui_context_providers.dart';
import '../shared_media_page.dart';

typedef _PostPageArgs = ({
  Database database,
  String conversationId,
  int size,
});

final _postPagingControllerProvider = Provider.autoDispose
    .family<LoadMorePagingController<MessageItem>, _PostPageArgs>((ref, args) {
      final messageDao = args.database.messageDao;
      final controller = LoadMorePagingController<MessageItem>(
        reloadData: () =>
            messageDao.postMessages(args.conversationId, args.size, 0).get(),
        loadMoreData: (list) async {
          if (list.isEmpty) return [];
          final last = list.last;
          final info = await messageDao.messageOrderInfo(last.messageId);
          if (info == null) return [];
          final items = await messageDao
              .postMessagesBefore(info, args.conversationId, args.size)
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
              MessageCategory.plainPost,
              MessageCategory.signalPost,
            ].contains(event.type),
          )
          .listen(controller.insertOrReplace);
      ref.onDispose(subscription.cancel);
      ref.onDispose(controller.dispose);
      return controller;
    });

final _postGroupedItemsProvider = StreamProvider.autoDispose
    .family<Map<DateTime, List<MessageItem>>, _PostPageArgs>((ref, args) {
      final controller = ref.watch(_postPagingControllerProvider(args));
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

class PostPage extends HookConsumerWidget {
  const PostPage({
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
    final size = useMemoized(() => maxHeight / 90 * 2, [maxHeight]).toInt();
    final database = ref.read(databaseProvider).requireValue;
    final args = (
      database: database,
      conversationId: conversationId,
      size: size,
    );
    final postController = ref.watch(_postPagingControllerProvider(args));
    final map =
        ref.watch(_postGroupedItemsProvider(args)).value ??
        const <DateTime, List<MessageItem>>{};

    final scrollController = useScrollController();

    if (map.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              Resources.assetsImagesEmptyFileSvg,
              colorFilter: ColorFilter.mode(
                theme.secondaryText.withValues(alpha: 0.4),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noPosts,
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
          postController.loadMore();
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
                  SliverList(
                    delegate: SliverChildBuilderDelegate((
                      context,
                      index,
                    ) {
                      final message = e.value[index];
                      return _Item(message: message);
                    }, childCount: e.value.length),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Item extends ConsumerWidget {
  const _Item({required this.message});

  final MessageItem message;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
    child: ShareMediaItemMenuWrapper(
      messageId: message.messageId,
      child: MessageContext.fromMessageItem(
        message: message,
        child: MessagePost(
          content: message.content ?? '',
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ref.watch(
              brightnessThemeDataProvider.select(
                (value) => value.sidebarSelected,
              ),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          showStatus: false,
        ),
      ),
    ),
  );
}
