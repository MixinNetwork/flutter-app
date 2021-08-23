import 'package:collection/collection.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../../../bloc/paging/load_more_paging.dart';
import '../../../../constants/brightness_theme_data.dart';
import '../../../../constants/resources.dart';
import '../../../../db/mixin_database.dart';
import '../../../../enum/media_status.dart';
import '../../../../enum/message_category.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/file.dart';
import '../../../../utils/hook.dart';
import '../../../../widgets/interacter_decorated_box.dart';
import '../../../../widgets/status.dart';

class FilePage extends HookWidget {
  const FilePage({
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
            messageDao.fileMessages(conversationId, size, 0).get(),
        loadMoreData: (list) async {
          if (list.isEmpty) return [];
          final last = list.last;
          final rowId =
              await messageDao.messageRowId(last.messageId).getSingleOrNull();
          if (rowId == null) return [];
          final items = await messageDao
              .fileMessagesBefore(rowId, conversationId, size)
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
                MessageCategory.plainData,
                MessageCategory.signalData,
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
              context.l10n.noFile,
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
  Widget build(BuildContext context) => InteractableDecoratedBox(
        onTap: () async {
          if (message.mediaStatus == MediaStatus.canceled) {
            if (message.relationship == UserRelationship.me &&
                message.mediaUrl?.isNotEmpty == true) {
              await context.accountServer.reUploadAttachment(message);
            } else {
              await context.accountServer.downloadAttachment(message);
            }
          } else if (message.mediaStatus == MediaStatus.done &&
              message.mediaUrl != null) {
            if (message.mediaUrl?.isEmpty ?? true) return;
            await saveFileToSystem(
              context,
              context.accountServer.convertMessageAbsolutePath(message),
              suggestName: message.mediaName,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox.fromSize(
                size: const Size.square(50),
                child: Builder(builder: (context) {
                  switch (message.mediaStatus) {
                    case MediaStatus.canceled:
                      if (message.relationship == UserRelationship.me &&
                          message.mediaUrl?.isNotEmpty == true) {
                        return const StatusUpload();
                      } else {
                        return const StatusDownload();
                      }
                    case MediaStatus.pending:
                      return StatusPending(messageId: message.messageId);
                    case MediaStatus.expired:
                      return const StatusWarning();
                    default:
                      break;
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: context.theme.statusBackground,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Builder(builder: (context) {
                      var extension = 'FILE';
                      if (message.mediaName != null) {
                        final _lookupMimeType =
                            lookupMimeType(message.mediaName!);
                        if (_lookupMimeType != null) {
                          extension =
                              extensionFromMime(_lookupMimeType).toUpperCase();
                        }
                      }
                      return Text(
                        extension,
                        style: TextStyle(
                          fontSize: 16,
                          color: lightBrightnessThemeData.secondaryText,
                        ),
                      );
                    }),
                  );
                }),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.mediaName?.overflow ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: context.theme.text,
                    ),
                    maxLines: 1,
                  ),
                  Text(
                    filesize(message.mediaSize),
                    style: TextStyle(
                      fontSize: 14,
                      color: context.theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
