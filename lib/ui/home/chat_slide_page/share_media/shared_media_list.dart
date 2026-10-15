import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:vector_graphics/vector_graphics_compat.dart'
    show RenderingStrategy;

import '../../../../db/dao/message_dao.dart';
import '../../../../db/mixin_database.dart';
import '../../../../utils/datetime_format_utils.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../widgets/deferred_mount.dart';
import '../../../../widgets/near_edge_scroll_listener.dart';

typedef SharedMediaInitialLoader =
    Future<List<MessageItem>> Function(int pageSize);
typedef SharedMediaBeforeLoader =
    Future<List<MessageItem>> Function(MessageOrderInfo anchor, int pageSize);
typedef SharedMediaItemBuilder =
    Widget Function(BuildContext context, MessageItem message);

class SharedMediaList extends HookConsumerWidget {
  const SharedMediaList({
    required this.conversationId,
    required this.pageSize,
    required this.categories,
    required this.emptyAsset,
    required this.emptyText,
    required this.reloadData,
    required this.loadBefore,
    required this.itemBuilder,
    super.key,
    this.gridDelegate,
  });

  final String conversationId;
  final int pageSize;
  final Set<String> categories;
  final String emptyAsset;
  final String emptyText;
  final SharedMediaInitialLoader reloadData;
  final SharedMediaBeforeLoader loadBefore;
  final SharedMediaItemBuilder itemBuilder;
  final SliverGridDelegate? gridDelegate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageDao = context.database.messageDao;
    final messages = useState(const <MessageItem>[]);
    final loading = useRef(false);
    useEffect(() {
      var active = true;
      reloadData(pageSize).then((value) {
        if (active) messages.value = value;
      });
      return () => active = false;
    }, [conversationId, pageSize]);
    useEffect(
      () => messageDao
          .watchInsertOrReplaceMessageStream(conversationId)
          .switchMap<MessageItem>((value) async* {
            for (final item in value) {
              yield item;
            }
          })
          .where((event) => categories.contains(event.type))
          .listen((item) {
            final index = messages.value.indexWhere(
              (message) => message.messageId == item.messageId,
            );
            messages.value =
                index == -1 ? [item, ...messages.value] : [...messages.value]
                  ..[index] = item;
          })
          .cancel,
      [conversationId],
    );

    final grouped = useMemoized(
      // Each load groups every message again; a local date reads the time
      // zone, so the day of each message comes from a cache.
      () => groupBy<MessageItem, int>(
        messages.value,
        (messageItem) => localDay(messageItem.createdAt),
      ),
      [messages.value],
    );
    final scrollController = useScrollController();
    // The item built for each message. A page load rebuilds the list, and the
    // same widget lets an unchanged item skip its rebuild; a post item laid
    // out its markdown again otherwise.
    final items = useRef(<String, (MessageItem, Widget)>{});
    // A page fills the panel and more, and a post lays out up to 400px of
    // markdown, so new items show over a few frames from the top.
    Widget item(BuildContext context, MessageItem message) {
      final cached = items.value[message.messageId];
      final child = cached != null && identical(cached.$1, message)
          ? cached.$2
          : itemBuilder(context, message);
      items.value[message.messageId] = (message, child);
      return DeferredMount(defer: cached == null, child: child);
    }

    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              emptyAsset,
              renderingStrategy: RenderingStrategy.raster,
              colorFilter: ColorFilter.mode(
                context.theme.secondaryText.withValues(alpha: 0.4),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              emptyText,
              style: TextStyle(
                fontSize: 12,
                color: context.theme.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    return NearEdgeScrollListener(
      onNearEnd: () async {
        if (loading.value || messages.value.isEmpty) return;
        loading.value = true;
        try {
          final info = await messageDao.messageOrderInfo(
            messages.value.last.messageId,
          );
          if (info == null) return;
          messages.value = [
            ...messages.value,
            ...await loadBefore(info, pageSize),
          ];
        } finally {
          loading.value = false;
        }
      },
      child: CustomScrollView(
        controller: scrollController,
        slivers: grouped.entries
            .map(
              (entry) => MultiSliver(
                pushPinnedChildren: true,
                children: [
                  SliverPinnedHeader(
                    child: Container(
                      color: context.theme.primary,
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        cachedDateFormat(
                          DateFormat.YEAR_ABBR_MONTH_DAY,
                        ).format(entry.value.first.createdAt.toLocal()),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.theme.secondaryText,
                        ),
                      ),
                    ),
                  ),
                  if (gridDelegate == null)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => item(context, entry.value[index]),
                        childCount: entry.value.length,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => item(context, entry.value[index]),
                          childCount: entry.value.length,
                        ),
                        gridDelegate: gridDelegate!,
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
