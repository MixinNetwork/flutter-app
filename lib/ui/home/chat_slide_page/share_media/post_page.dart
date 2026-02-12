import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../../../bloc/paging/load_more_paging_state.dart';
import '../../../../constants/resources.dart';
import '../../../../db/mixin_database.dart';
import '../../../../enum/message_category.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/hook.dart';
import '../../../../widgets/message/item/post_message.dart';
import '../../../../widgets/message/message.dart';
import '../shared_media_page.dart';

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
    final size = useMemoized(() => maxHeight / 90 * 2, [maxHeight]).toInt();

    final messageDao = context.database.messageDao;

    final mediaCubit = useBloc(
      () => LoadMorePagingBloc<MessageItem>(
        reloadData: () =>
            messageDao.postMessages(conversationId, size, 0).get(),
        loadMoreData: (list) async {
          if (list.isEmpty) return [];
          final last = list.last;
          final info = await messageDao.messageOrderInfo(last.messageId);
          if (info == null) return [];
          final items = await messageDao
              .postMessagesBefore(info, conversationId, size)
              .get();
          return [...list, ...items];
        },
        isSameKey: (a, b) => a.messageId == b.messageId,
      ),
      keys: [conversationId],
    );
    useEffect(
      () => messageDao
          .watchInsertOrReplaceMessageStream(conversationId)
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
          .listen(mediaCubit.insertOrReplace)
          .cancel,
      [conversationId],
    );
    final map =
        useBlocStateConverter<
          LoadMorePagingBloc<MessageItem>,
          LoadMorePagingState<MessageItem>,
          Map<DateTime, List<MessageItem>>
        >(
          bloc: mediaCubit,
          converter: (state) =>
              groupBy<MessageItem, DateTime>(state.list, (messageItem) {
                final local = messageItem.createdAt.toLocal();
                return DateTime(local.year, local.month, local.day);
              }),
        );

    final scrollController = useScrollController();

    if (map.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              Resources.assetsImagesEmptyFileSvg,
              colorFilter: ColorFilter.mode(
                context.theme.secondaryText.withValues(alpha: 0.4),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.noPosts,
              style: TextStyle(
                fontSize: 12,
                color: context.theme.secondaryText,
              ),
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
          mediaCubit.loadMore();
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
                      color: context.theme.primary,
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        DateFormat.yMMMd().format(e.key.toLocal()),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.theme.secondaryText,
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

class _Item extends StatelessWidget {
  const _Item({required this.message});

  final MessageItem message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
    child: ShareMediaItemMenuWrapper(
      messageId: message.messageId,
      child: MessageContext.fromMessageItem(
        message: message,
        child: MessagePost(
          content: message.content ?? '',
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.theme.sidebarSelected,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          showStatus: false,
        ),
      ),
    ),
  );
}
