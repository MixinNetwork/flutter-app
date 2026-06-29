import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/resources.dart';
import '../../../../db/mixin_database.dart';
import '../../../../enum/message_category.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../widgets/message/item/file_message.dart';
import '../../../../widgets/message/message.dart';
import '../shared_media_page.dart';
import 'shared_media_list.dart';

class FilePage extends HookConsumerWidget {
  const FilePage({
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
        MessageCategory.plainData,
        MessageCategory.signalData,
      },
      emptyAsset: Resources.assetsImagesEmptyFileSvg,
      emptyText: context.l10n.noFiles,
      reloadData: (pageSize) =>
          messageDao.fileMessages(conversationId, pageSize, 0).get(),
      loadBefore: (info, pageSize) =>
          messageDao.fileMessagesBefore(info, conversationId, pageSize).get(),
      itemBuilder: (context, message) => _Item(message: message),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.message});

  final MessageItem message;

  @override
  Widget build(BuildContext context) => ShareMediaItemMenuWrapper(
    messageId: message.messageId,
    child: MessageContext.fromMessageItem(
      message: message,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: MessageFile(),
      ),
    ),
  );
}
