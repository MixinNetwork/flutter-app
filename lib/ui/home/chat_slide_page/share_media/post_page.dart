import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/paging/load_more_paging.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/utils/hook.dart';
import 'package:flutter_app/utils/markdown.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/full_screen_portal.dart';
import 'package:flutter_app/widgets/interacter_decorated_box.dart';
import 'package:flutter_app/widgets/message/item/post_message.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart' hide Text;
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:flutter_app/generated/l10n.dart';

class PostPage extends HookWidget {
  const PostPage({
    Key? key,
    required this.maxHeight,
  }) : super(key: key);

  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final size = useMemoized(() => maxHeight / 90 * 2, [maxHeight]).toInt();
    final conversationId =
        useBlocStateConverter<ConversationCubit, ConversationState?, String?>(
      converter: (state) => state?.conversationId,
      when: (conversationId) => conversationId != null,
    )!;

    final messagesDao = context.read<AccountServer>().database.messagesDao;

    final mediaCubit = useBloc(
      () => LoadMorePagingBloc<MessageItem>(
        reloadData: () =>
            messagesDao.postMessages(conversationId, size, 0).get(),
        loadMoreData: (list) async {
          if (list.isEmpty) return [];
          final last = list.last;
          final rowId =
              await messagesDao.messageRowId(last.messageId).getSingleOrNull();
          if (rowId == null) return [];
          final items = await messagesDao
              .postMessagesBefore(rowId, conversationId, size)
              .get();
          return [...list, ...items];
        },
        isSameKey: (a, b) => a.messageId == b.messageId,
      ),
      keys: [conversationId],
    );
    useEffect(
      () => messagesDao.insertOrReplaceMessageStream
          .switchMap<MessageItem>((value) async* {
            for (final item in value) yield item;
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

    if (map.isEmpty)
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(Resources.assetsImagesEmptyFileSvg,
              color: BrightnessData.themeOf(context).secondaryText,
            ),
            const SizedBox(height: 24),
            Text(
              Localization.of(context).noPost,
              style: TextStyle(
                fontSize: 12,
                color: BrightnessData.themeOf(context).secondaryText,
              ),
            ),
          ],
        ),
      );

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
                      color: BrightnessData.themeOf(context).primary,
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        DateFormat.yMMMd().format(e.key),
                        style: TextStyle(
                          fontSize: 14,
                          color: BrightnessData.themeOf(context).secondaryText,
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
            onTap: () => FullScreenPortal.of(context).emit(true),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BrightnessData.themeOf(context).sidebarSelected,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  MarkdownBody(
                    data: message.thumbImage?.postLengthOptimize() ??
                        message.content!.postOptimize(),
                    extensionSet: ExtensionSet.gitHubWeb,
                    styleSheet: markdownStyleSheet(context),
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
