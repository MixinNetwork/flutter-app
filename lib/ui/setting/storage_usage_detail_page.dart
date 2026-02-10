import 'dart:io';

import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../utils/extension/extension.dart';
import '../../utils/file.dart';
import '../../utils/hook.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../../widgets/dialog.dart';
import '../../widgets/disable.dart';
import '../../widgets/radio.dart';
import '../../widgets/toast.dart';

class StorageUsageDetailPage extends HookConsumerWidget {
  const StorageUsageDetailPage({
    required this.name,
    required this.conversationId,
    super.key,
  });

  final String name;
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchEvent = useMemoizedStream(
      () => File(
        context.accountServer.getMediaFilePath(),
      ).watch(recursive: true),
    ).data;

    final photosSize = useMemoizedFuture(
      () async => filesize(
        await getTotalSizeOfFile(
          context.accountServer.getImagesPath(conversationId),
        ),
      ),
      '0 B',
      keys: [watchEvent],
    ).requireData;
    final videosSize = useMemoizedFuture(
      () async => filesize(
        await getTotalSizeOfFile(
          context.accountServer.getVideosPath(conversationId),
        ),
      ),
      '0 B',
      keys: [watchEvent],
    ).requireData;
    final audiosSize = useMemoizedFuture(
      () async => filesize(
        await getTotalSizeOfFile(
          context.accountServer.getAudiosPath(conversationId),
        ),
      ),
      '0 B',
      keys: [watchEvent],
    ).requireData;
    final filesSize = useMemoizedFuture(
      () async => filesize(
        await getTotalSizeOfFile(
          context.accountServer.getFilesPath(conversationId),
        ),
      ),
      '0 B',
      keys: [watchEvent],
    ).requireData;

    final selected = useState<(bool, bool, bool, bool)>(const (
      false,
      false,
      false,
      false,
    ));

    return Scaffold(
      backgroundColor: context.theme.background,
      appBar: MixinAppBar(
        title: Text(name),
        actions: [
          Disable(
            disable: [
              selected.value.$1,
              selected.value.$2,
              selected.value.$3,
              selected.value.$4,
            ].every((element) => !element),
            child: MixinButton(
              backgroundTransparent: true,
              onTap: () => runFutureWithToast(() async {
                final accountServer = context.accountServer;
                if (selected.value.$1) {
                  await _clear(accountServer.getImagesPath(conversationId));
                }
                if (selected.value.$2) {
                  await _clear(accountServer.getVideosPath(conversationId));
                }
                if (selected.value.$3) {
                  await _clear(accountServer.getAudiosPath(conversationId));
                }
                if (selected.value.$4) {
                  await _clear(accountServer.getFilesPath(conversationId));
                }
              }()),
              child: Center(child: Text(context.l10n.clear)),
            ),
          ),
        ],
      ),
      body: Container(
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CellGroup(
              cellBackgroundColor: context.theme.settingCellBackgroundColor,
              child: Column(
                children: [
                  CellItem(
                    title: RadioItem(
                      groupValue: true,
                      value: selected.value.$1,
                      title: Text(context.l10n.photos),
                      onChanged: (value) {
                        final (_, item2, item3, item4) = selected.value;

                        selected.value = (!value, item2, item3, item4);
                      },
                    ),
                    description: Text(
                      photosSize,
                      style: TextStyle(
                        color: context.theme.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  CellItem(
                    title: RadioItem(
                      groupValue: true,
                      value: selected.value.$2,
                      title: Text(context.l10n.videos),
                      onChanged: (value) {
                        final (item1, _, item3, item4) = selected.value;

                        selected.value = (item1, !value, item3, item4);
                      },
                    ),
                    description: Text(
                      videosSize,
                      style: TextStyle(
                        color: context.theme.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  CellItem(
                    title: RadioItem(
                      groupValue: true,
                      value: selected.value.$3,
                      title: Text(context.l10n.audio),
                      onChanged: (value) {
                        final (item1, item2, _, item4) = selected.value;

                        selected.value = (item1, item2, !value, item4);
                      },
                    ),
                    description: Text(
                      audiosSize,
                      style: TextStyle(
                        color: context.theme.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  CellItem(
                    title: RadioItem(
                      groupValue: true,
                      value: selected.value.$4,
                      title: Text(context.l10n.files),
                      onChanged: (value) {
                        final (item1, item2, item3, _) = selected.value;

                        selected.value = (item1, item2, item3, !value);
                      },
                    ),
                    description: Text(
                      filesSize,
                      style: TextStyle(
                        color: context.theme.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clear(String path) async {
    final directory = Directory(path);
    if (!directory.existsSync()) return;
    final list = await directory.list().toList();
    await Future.wait(list.map((e) => e.delete(recursive: true)));
  }
}
