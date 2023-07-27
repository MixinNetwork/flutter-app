import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../bloc/setting_cubit.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../home/route/responsive_navigator_cubit.dart';

class StoragePage extends HookWidget {
  const StoragePage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingState = useBlocState<SettingCubit, SettingState>();

    return Scaffold(
      backgroundColor: context.theme.background,
      appBar: MixinAppBar(
        title: Text(context.l10n.dataAndStorageUsage),
      ),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CellGroup(
                cellBackgroundColor: context.theme.settingCellBackgroundColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CellItem(
                      title: Text(context.l10n.photos),
                      trailing: Transform.scale(
                          scale: 0.7,
                          child: CupertinoSwitch(
                            activeColor: context.theme.accent,
                            value: settingState.photoAutoDownload,
                            onChanged: (bool value) =>
                                context.settingCubit.photoAutoDownload = value,
                          )),
                    ),
                    CellItem(
                      title: Text(context.l10n.videos),
                      trailing: Transform.scale(
                          scale: 0.7,
                          child: CupertinoSwitch(
                            activeColor: context.theme.accent,
                            value: settingState.videoAutoDownload,
                            onChanged: (bool value) =>
                                context.settingCubit.videoAutoDownload = value,
                          )),
                    ),
                    CellItem(
                      title: Text(context.l10n.files),
                      trailing: Transform.scale(
                          scale: 0.7,
                          child: CupertinoSwitch(
                            activeColor: context.theme.accent,
                            value: settingState.fileAutoDownload,
                            onChanged: (bool value) =>
                                context.settingCubit.fileAutoDownload = value,
                          )),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 14, top: 10),
                child: Text(
                  context.l10n.storageAutoDownloadDescription,
                  style: TextStyle(
                    color: context.theme.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ),
              CellGroup(
                cellBackgroundColor: context.theme.settingCellBackgroundColor,
                child: CellItem(
                  title: Text(context.l10n.storageUsage),
                  onTap: () => context
                      .read<ResponsiveNavigatorCubit>()
                      .pushPage(ResponsiveNavigatorCubit.storageUsage),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
