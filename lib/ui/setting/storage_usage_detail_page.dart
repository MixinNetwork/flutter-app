import 'dart:io';

import 'package:filesize/filesize.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/utils/file.dart';
import 'package:flutter_app/utils/hook.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/widgets/cell.dart';
import 'package:flutter_app/widgets/dialog.dart';
import 'package:flutter_app/widgets/disable.dart';
import 'package:flutter_app/widgets/radio.dart';
import 'package:flutter_app/widgets/toast.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

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
      useMemoized(() => File(context.read<AccountServer>().getMediaFilePath())
          .watch(recursive: true)),
      initialData: null,
    ).data;

    final photosSize = useMemoizedFuture(
      () async => filesize(await getTotalSizeOfFile(
          context.read<AccountServer>().getImagesPath(conversationId))),
      '0 B',
      keys: [watchEvent],
    );
    final videosSize = useMemoizedFuture(
      () async => filesize(await getTotalSizeOfFile(
          context.read<AccountServer>().getVideosPath(conversationId))),
      '0 B',
      keys: [watchEvent],
    );
    final audiosSize = useMemoizedFuture(
      () async => filesize(await getTotalSizeOfFile(
          context.read<AccountServer>().getAudiosPath(conversationId))),
      '0 B',
      keys: [watchEvent],
    );
    final filesSize = useMemoizedFuture(
      () async => filesize(await getTotalSizeOfFile(
          context.read<AccountServer>().getFilesPath(conversationId))),
      '0 B',
      keys: [watchEvent],
    );

    final selected = useState(const Tuple4(false, false, false, false));

    return Scaffold(
      backgroundColor: BrightnessData.themeOf(context).background,
      appBar: MixinAppBar(
        title: Text(name),
        actions: [
          Disable(
            disable: selected.value.toList().every((element) => !element),
            child: MixinButton(
              backgroundTransparent: true,
              child: Center(
                child: Text(
                  Localization.of(context).clear,
                ),
              ),
              onTap: () => runFutureWithToast(
                context,
                () async {
                  final accountServer = context.read<AccountServer>();
                  if (selected.value.item1)
                    await _clear(accountServer.getImagesPath(conversationId));
                  if (selected.value.item2)
                    await _clear(accountServer.getVideosPath(conversationId));
                  if (selected.value.item3)
                    await _clear(accountServer.getAudiosPath(conversationId));
                  if (selected.value.item4)
                    await _clear(accountServer.getFilesPath(conversationId));
                }(),
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
              child: Column(
                children: [
                  CellItem(
                    title: RadioItem(
                      groupValue: true,
                      value: selected.value.item1,
                      title: Text(Localization.of(context).photos),
                      onChanged: (bool value) =>
                          selected.value = selected.value.withItem1(!value),
                    ),
                    description: Text(
                      photosSize,
                      style: TextStyle(
                        color: BrightnessData.themeOf(context).secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  CellItem(
                    title: RadioItem(
                      groupValue: true,
                      value: selected.value.item2,
                      title: Text(Localization.of(context).videos),
                      onChanged: (bool value) =>
                          selected.value = selected.value.withItem2(!value),
                    ),
                    description: Text(
                      videosSize,
                      style: TextStyle(
                        color: BrightnessData.themeOf(context).secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  CellItem(
                    title: RadioItem(
                      groupValue: true,
                      value: selected.value.item3,
                      title: Text(Localization.of(context).audio),
                      onChanged: (bool value) =>
                          selected.value = selected.value.withItem3(!value),
                    ),
                    description: Text(
                      audiosSize,
                      style: TextStyle(
                        color: BrightnessData.themeOf(context).secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  CellItem(
                    title: RadioItem(
                      groupValue: true,
                      value: selected.value.item4,
                      title: Text(Localization.of(context).files),
                      onChanged: (bool value) =>
                          selected.value = selected.value.withItem4(!value),
                    ),
                    description: Text(
                      filesSize,
                      style: TextStyle(
                        color: BrightnessData.themeOf(context).secondaryText,
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
    if (!(await directory.exists())) return;
    final list = await directory.list().toList();
    await Future.wait(list.map((e) => e.delete(recursive: true)));
  }
}
