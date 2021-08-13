import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/widgets/cache_image.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../../../bloc/paging/load_more_paging.dart';
import '../../../../constants/resources.dart';
import '../../../../db/mixin_database.dart';
import '../../../../enum/media_status.dart';
import '../../../../enum/message_category.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/hook.dart';
import '../../../../widgets/image.dart';
import '../../../../widgets/interacter_decorated_box.dart';
import '../../../../widgets/message/item/image/image_preview_portal.dart';
import '../../chat_page.dart';

class MediaPage extends HookWidget {
  const MediaPage({
    Key? key,
    required this.maxHeight,
    required this.conversationId,
  }) : super(key: key);

  final double maxHeight;
  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final column = useMemoized(() => maxHeight / 90 * 2, [maxHeight]).toInt();
    final routeMode = context.read<ChatSideCubit>().state.routeMode;
    final size = column * (routeMode ? 4 : 3);

    final messageDao = context.database.messageDao;

    final mediaCubit = useBloc(
      () => LoadMorePagingBloc<MessageItem>(
        reloadData: () =>
            messageDao.mediaMessages(conversationId, size, 0).get(),
        loadMoreData: (list) async {
          if (list.isEmpty) return [];
          final last = list.last;
          final rowId =
              await messageDao.messageRowId(last.messageId).getSingleOrNull();
          if (rowId == null) return [];
          final items = await messageDao
              .mediaMessagesBefore(rowId, conversationId, size)
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
                MessageCategory.plainImage,
                MessageCategory.signalImage,
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
              Resources.assetsImagesEmptyImageSvg,
              color: context.theme.secondaryText.withOpacity(0.4),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.noMedia,
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
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          final message = e.value[index];
                          return _Item(message: message);
                        },
                        childCount: e.value.length,
                      ),
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
  const _Item({
    Key? key,
    required this.message,
  }) : super(key: key);

  final MessageItem message;

  @override
  Widget build(BuildContext context) => InteractableDecoratedBox(
        onTap: () {
          switch (message.mediaStatus) {
            case MediaStatus.done:
              ImagePreviewPage.push(
                context,
                conversationId: message.conversationId,
                messageId: message.messageId,
              );
              break;
            case MediaStatus.canceled:
              if (message.relationship == UserRelationship.me &&
                  message.mediaUrl?.isNotEmpty == true) {
                context.accountServer.reUploadAttachment(message);
              } else {
                context.accountServer.downloadAttachment(message);
              }
              ImagePreviewPage.push(
                context,
                conversationId: message.conversationId,
                messageId: message.messageId,
              );
              break;
            default:
              break;
          }
        },
        child: Image(
          image: MixinFileImage(
              File(context.accountServer.convertMessageAbsolutePath(message))),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => ImageByBase64(message.thumbImage!),
        ),
      );
}
