import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../provider/responsive_navigator_provider.dart';
import '../provider/setting_provider.dart';
import '../provider/ui_context_providers.dart';

class StoragePage extends HookConsumerWidget {
  const StoragePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final (photoAutoDownload, videoAutoDownload, fileAutoDownload) = ref.watch(
      settingProvider.select(
        (value) => (
          value.photoAutoDownload,
          value.videoAutoDownload,
          value.fileAutoDownload,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: theme.background,
      appBar: MixinAppBar(title: Text(l10n.dataAndStorageUsage)),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CellGroup(
                cellBackgroundColor: theme.settingCellBackgroundColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CellItem(
                      title: Text(l10n.photos),
                      trailing: Transform.scale(
                        scale: 0.7,
                        child: CupertinoSwitch(
                          activeTrackColor: theme.accent,
                          value: photoAutoDownload,
                          onChanged: (value) =>
                              ref
                                      .read(settingProvider.notifier)
                                      .photoAutoDownload =
                                  value,
                        ),
                      ),
                    ),
                    CellItem(
                      title: Text(l10n.videos),
                      trailing: Transform.scale(
                        scale: 0.7,
                        child: CupertinoSwitch(
                          activeTrackColor: theme.accent,
                          value: videoAutoDownload,
                          onChanged: (value) =>
                              ref
                                      .read(settingProvider.notifier)
                                      .videoAutoDownload =
                                  value,
                        ),
                      ),
                    ),
                    CellItem(
                      title: Text(l10n.files),
                      trailing: Transform.scale(
                        scale: 0.7,
                        child: CupertinoSwitch(
                          activeTrackColor: theme.accent,
                          value: fileAutoDownload,
                          onChanged: (value) =>
                              ref
                                      .read(settingProvider.notifier)
                                      .fileAutoDownload =
                                  value,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 14, top: 10),
                child: Text(
                  l10n.storageAutoDownloadDescription,
                  style: TextStyle(
                    color: theme.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ),
              CellGroup(
                cellBackgroundColor: theme.settingCellBackgroundColor,
                child: CellItem(
                  title: Text(l10n.storageUsage),
                  onTap: () => ref
                      .read(responsiveNavigatorProvider.notifier)
                      .pushPage(
                        ResponsiveNavigatorStateNotifier.storageUsage,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
