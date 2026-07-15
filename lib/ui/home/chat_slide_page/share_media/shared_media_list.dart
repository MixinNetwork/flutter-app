import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../../../db/dao/message_dao.dart';
import '../../../../db/mixin_database.dart';
import '../../../../utils/extension/extension.dart';
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
      () => groupBy<MessageItem, DateTime>(messages.value, (messageItem) {
        final local = messageItem.createdAt.toLocal();
        return DateTime(local.year, local.month, local.day);
      }),
      [messages.value],
    );
    final scrollController = useScrollController();

    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              emptyAsset,
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
                        DateFormat.yMMMd().format(entry.key.toLocal()),
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
                        (context, index) =>
                            itemBuilder(context, entry.value[index]),
                        childCount: entry.value.length,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              itemBuilder(context, entry.value[index]),
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
