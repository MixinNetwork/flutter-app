import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/resources.dart';
import '../../../../db/mixin_database.dart';
import '../../../../enum/message_category.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../widgets/message/item/post_message.dart';
import '../../../../widgets/message/message.dart';
import '../shared_media_page.dart';
import 'shared_media_list.dart';

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

    return SharedMediaList(
      conversationId: conversationId,
      pageSize: size,
      categories: const {
        MessageCategory.plainPost,
        MessageCategory.signalPost,
      },
      emptyAsset: Resources.assetsImagesEmptyFileSvg,
      emptyText: context.l10n.noPosts,
      reloadData: (pageSize) =>
          messageDao.postMessages(conversationId, pageSize, 0).get(),
      loadBefore: (info, pageSize) =>
          messageDao.postMessagesBefore(info, conversationId, pageSize).get(),
      itemBuilder: (context, message) => _Item(message: message),
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
