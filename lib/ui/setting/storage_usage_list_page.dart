import 'dart:io';

// ignore: import_of_legacy_library_into_null_safe
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../../account/account_server.dart';
import '../../db/extension/conversation.dart';
import '../../db/mixin_database.dart';
import '../../generated/l10n.dart';
import '../../utils/hook.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/avatar_view/avatar_view.dart';
import '../../widgets/brightness_observer.dart';
import '../../widgets/cell.dart';
import '../home/route/responsive_navigator_cubit.dart';

class StorageUsageListPage extends HookWidget {
  const StorageUsageListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: BrightnessData.themeOf(context).background,
        appBar: MixinAppBar(
          title: Text(Localization.of(context).storageUsage),
          actions: const [],
        ),
        body: const _Content(),
      );
}

class _Content extends HookWidget {
  const _Content({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final watchEvent = useStream(
      useMemoized(() => File(context.read<AccountServer>().getMediaFilePath())
          .watch(recursive: true)),
      initialData: null,
    ).data;

    final list =
        useMemoizedFuture<List<Tuple2<ConversationStorageUsage, int>>?>(
            () async {
      try {
        final accountServer = context.read<AccountServer>();
        final list = await accountServer.database.conversationDao
            .conversationStorageUsage()
            .get();
        final result = await Future.wait(
          list.map(
            (e) async => Tuple2(
              e,
              await accountServer.getConversationMediaSize(e.conversationId),
            ),
          ),
        );
        result.sort((a, b) => b.item2 - a.item2);
        return result;
      } catch (e) {
        return [];
      }
    }, null, keys: [watchEvent]);

    if (list == null)
      return Center(
        child: CircularProgressIndicator(
          valueColor:
              AlwaysStoppedAnimation(BrightnessData.themeOf(context).accent),
        ),
      );

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 40),
      itemBuilder: (_, index) {
        final item = list[index].item1;
        final size = list[index].item2;
        return _Item(item: item, size: size);
      },
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: list.length,
    );
  }
}

class _Item extends HookWidget {
  const _Item({
    Key? key,
    required this.item,
    required this.size,
  }) : super(key: key);

  final ConversationStorageUsage item;
  final int size;

  @override
  Widget build(BuildContext context) {
    final sizeString = useMemoized(() => filesize(size), [item, size]);
    return Align(
      alignment: Alignment.center,
      child: CellGroup(
        padding: EdgeInsets.zero,
        child: CellItem(
          leading: ConversationAvatarWidget(
            conversationId: item.conversationId,
            fullName: item.fullName,
            groupIconUrl: item.iconUrl,
            avatarUrl: item.avatarUrl,
            category: item.category,
            size: 50,
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(conversationValidName(item.name, item.fullName)),
              Text(
                sizeString,
                style: TextStyle(
                  color: BrightnessData.themeOf(context).secondaryText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          onTap: () => context.read<ResponsiveNavigatorCubit>().pushPage(
                ResponsiveNavigatorCubit.storageUsageDetail,
                arguments: Tuple2(
                  conversationValidName(item.name, item.fullName),
                  item.conversationId,
                ),
              ),
        ),
      ),
    );
  }
}
