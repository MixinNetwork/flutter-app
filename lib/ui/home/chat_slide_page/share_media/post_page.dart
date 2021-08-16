import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart' hide Text;
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../../../bloc/paging/load_more_paging.dart';
import '../../../../constants/resources.dart';
import '../../../../db/mixin_database.dart';
import '../../../../enum/message_category.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/hook.dart';
import '../../../../widgets/full_screen_portal.dart';
import '../../../../widgets/interacter_decorated_box.dart';
import '../../../../widgets/message/item/post_message.dart';

class PostPage extends HookWidget {
  const PostPage({
    Key? key,
    required this.maxHeight,
    required this.conversationId,
  }) : super(key: key);

  final double maxHeight;
  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final size = useMemoized(() => maxHeight / 90 * 2, [maxHeight]).toInt();

    final messageDao = context.database.messageDao;

    final mediaCubit = useBloc(
      () => LoadMorePagingBloc<MessageItem>(
        reloadData: () =>
            messageDao.postMessages(conversationId, size, 0).get(),
        loadMoreData: (list) async {
          if (list.isEmpty) return [];
          final last = list.last;
          final rowId =
              await messageDao.messageRowId(last.messageId).getSingleOrNull();
          if (rowId == null) return [];
          final items = await messageDao
              .postMessagesBefore(rowId, conversationId, size)
              .get();
          return [...list, ...items];
        },
        isSameKey: (a, b) => a.messageId == b.messageId,
      ),
      keys: [conversationId],
    );
    useEffect(
      () => messageDao.insertOrReplaceMessageStream
          .switchMap<MessageItem>((value) async* {
            for (final item in value) {
              yield item;
            }
          })
          .where((event) =>
              event.conversationId == conversationId &&
              [
                MessageCategory.plainPost,
                MessageCategory.signalPost,
              ].contains(event.type))
          .listen(mediaCubit.insertOrReplace)
          .cancel,
      [conversationId],
    );
    final map = useBlocStateConverter<LoadMorePagingBloc<MessageItem>,
        LoadMorePagingState<MessageItem>, Map<DateTime, List<MessageItem>>>(
      bloc: mediaCubit,
      converter: (state) => groupBy<MessageItem, DateTime>(
        state.list,
        (messageItem) {
          final local = messageItem.createdAt.toLocal();
          return DateTime(local.year, local.month, local.day);
        },
      ),
    );

    if (map.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              Resources.assetsImagesEmptyFileSvg,
              color: context.theme.secondaryText.withOpacity(0.4),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.noPost,
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
      onNotification: (ScrollNotification notification) {
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
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final message = e.value[index];
                        return _Item(message: message);
                      },
                      childCount: e.value.length,
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
  const _Item({
    Key? key,
    required this.message,
  }) : super(key: key);

  final MessageItem message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: FullScreenPortal(
          portalBuilder: (BuildContext context) =>
              PostPreview(message: message),
          builder: (BuildContext context) => InteractableDecoratedBox(
            onTap: () => context.read<FullScreenVisibleCubit>().emit(true),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.theme.sidebarSelected,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  MarkdownBody(
                    data: message.content!
                        .postOptimize(10)
                        .postLengthOptimize(256),
                    extensionSet: ExtensionSet.gitHubWeb,
                    styleSheet: context.markdownStyleSheet,
                    softLineBreakPattern: true,
                    imageBuilder: (_, __, ___) => const SizedBox(),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: SvgPicture.asset(
                      Resources.assetsImagesPostDetailSvg,
                      width: 20,
                      height: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
