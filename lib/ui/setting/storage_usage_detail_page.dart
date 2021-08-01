import 'dart:io';

import 'package:filesize/filesize.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tuple/tuple.dart';

import '../../utils/extension/extension.dart';
import '../../utils/file.dart';
import '../../utils/hook.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../../widgets/dialog.dart';
import '../../widgets/disable.dart';
import '../../widgets/radio.dart';
import '../../widgets/toast.dart';

class StorageUsageDetailPage extends HookWidget {
  const StorageUsageDetailPage({
    Key? key,
    required this.name,
    required this.conversationId,
  }) : super(key: key);

  final String name;
  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final watchEvent = useStream(
      useMemoized(() => File(context.accountServer.getMediaFilePath())
          .watch(recursive: true)),
      initialData: null,
    ).data;

    final photosSize = useMemoizedFuture(
      () async => filesize(await getTotalSizeOfFile(
          context.accountServer.getImagesPath(conversationId))),
      '0 B',
      keys: [watchEvent],
    );
    final videosSize = useMemoizedFuture(
      () async => filesize(await getTotalSizeOfFile(
          context.accountServer.getVideosPath(conversationId))),
      '0 B',
      keys: [watchEvent],
    );
    final audiosSize = useMemoizedFuture(
      () async => filesize(await getTotalSizeOfFile(
          context.accountServer.getAudiosPath(conversationId))),
      '0 B',
      keys: [watchEvent],
    );
    final filesSize = useMemoizedFuture(
      () async => filesize(await getTotalSizeOfFile(
          context.accountServer.getFilesPath(conversationId))),
      '0 B',
      keys: [watchEvent],
    );

    final selected = useState<Tuple4<bool, bool, bool, bool>>(
        const Tuple4(false, false, false, false));

    return Scaffold(
      backgroundColor: context.theme.background,
      appBar: MixinAppBar(
        title: Text(name),
        actions: [
          Disable(
            disable: selected.value
                .toList()
                .cast<bool>()
                .every((element) => !element),
            child: MixinButton(
              backgroundTransparent: true,
              onTap: () => runFutureWithToast(
                context,
                () async {
                  final accountServer = context.accountServer;
                  if (selected.value.item1) {
                    await _clear(accountServer.getImagesPath(conversationId));
                  }
                  if (selected.value.item2) {
                    await _clear(accountServer.getVideosPath(conversationId));
                  }
                  if (selected.value.item3) {
                    await _clear(accountServer.getAudiosPath(conversationId));
                  }
                  if (selected.value.item4) {
                    await _clear(accountServer.getFilesPath(conversationId));
                  }
                }(),
              ),
              child: Center(
                child: Text(
                  context.l10n.clear,
                ),
              ),
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
              cellBackgroundColor: context.dynamicColor(
                Colors.white,
                darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
              ),
              child: Column(
                children: [
                  CellItem(
                    title: RadioItem(
                      groupValue: true,
                      value: selected.value.item1,
                      title: Text(context.l10n.photos),
                      onChanged: (bool value) =>
                          selected.value = selected.value.withItem1(!value),
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
                      value: selected.value.item2,
                      title: Text(context.l10n.videos),
                      onChanged: (bool value) =>
                          selected.value = selected.value.withItem2(!value),
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
                      value: selected.value.item3,
                      title: Text(context.l10n.audio),
                      onChanged: (bool value) =>
                          selected.value = selected.value.withItem3(!value),
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
                      value: selected.value.item4,
                      title: Text(context.l10n.files),
                      onChanged: (bool value) =>
                          selected.value = selected.value.withItem4(!value),
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
