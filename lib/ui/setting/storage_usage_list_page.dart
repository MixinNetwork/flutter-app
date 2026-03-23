import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:watcher/watcher.dart';

import '../../db/dao/conversation_dao.dart';
import '../../db/extension/conversation.dart';
import '../../ui/provider/account_server_provider.dart';
import '../../ui/provider/ui_context_providers.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/avatar_view/avatar_view.dart';
import '../../widgets/cell.dart';
import '../provider/responsive_navigator_provider.dart';

class StorageUsageListPage extends HookConsumerWidget {
  const StorageUsageListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    return Scaffold(
      backgroundColor: theme.background,
      appBar: MixinAppBar(title: Text(l10n.storageUsage)),
      body: const _Content(),
    );
  }
}

class _Content extends HookConsumerWidget {
  const _Content();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final accountServer = ref.read(accountServerProvider).requireValue;
    final watchEvent = useMemoizedStream(
      () => DirectoryWatcher(
        accountServer.getMediaFilePath(),
      ).events.throttleTime(const Duration(milliseconds: 400)),
    ).data;

    final list = useMemoizedFuture<List<(ConversationStorageUsage, int)>?>(
      () async {
        try {
          final list = await accountServer.database.conversationDao
              .conversationStorageUsage()
              .get();
          final result = await Future.wait(
            list.map(
              (e) async => (
                e,
                await accountServer.getConversationMediaSize(
                  e.conversationId,
                ),
              ),
            ),
          );
          result.sort((a, b) => b.$2 - a.$2);
          return result;
        } catch (e) {
          return [];
        }
      },
      null,
      keys: [watchEvent],
    ).data;

    if (list == null) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(theme.accent),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 40),
      itemBuilder: (_, index) {
        final (item, size) = list[index];
        return _Item(item: item, size: size);
      },
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemCount: list.length,
    );
  }
}

class _Item extends HookConsumerWidget {
  const _Item({required this.item, required this.size});

  final ConversationStorageUsage item;
  final int size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final sizeString = useMemoized(() => filesize(size), [item, size]);
    return Align(
      child: CellGroup(
        padding: EdgeInsets.zero,
        cellBackgroundColor: theme.settingCellBackgroundColor,
        child: CellItem(
          leading: ConversationAvatarWidget(
            conversationId: item.conversationId,
            fullName: item.fullName,
            groupIconUrl: item.iconUrl,
            avatarUrl: item.avatarUrl,
            category: item.category,
            size: 50,
            userId: item.ownerId,
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(conversationValidName(item.name, item.fullName)),
              Text(
                sizeString,
                style: TextStyle(
                  color: theme.secondaryText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          onTap: () => ref
              .read(responsiveNavigatorProvider.notifier)
              .pushPage(
                ResponsiveNavigatorStateNotifier.storageUsageDetail,
                arguments: (
                  conversationValidName(item.name, item.fullName),
                  item.conversationId,
                ),
              ),
        ),
      ),
    );
  }
}
