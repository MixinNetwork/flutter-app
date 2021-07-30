import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../home/bloc/multi_auth_cubit.dart';
import '../home/route/responsive_navigator_cubit.dart';

class StoragePage extends HookWidget {
  const StoragePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authState = useBlocState<MultiAuthCubit, MultiAuthState>();

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
                cellBackgroundColor: context.dynamicColor(
                  Colors.white,
                  darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CellItem(
                      title: Text(context.l10n.photos),
                      trailing: Transform.scale(
                          scale: 0.7,
                          child: CupertinoSwitch(
                            activeColor: context.theme.accent,
                            value: authState.currentPhotoAutoDownload,
                            onChanged: (bool value) => context.multiAuthCubit
                                .setCurrentSetting(photoAutoDownload: value),
                          )),
                    ),
                    CellItem(
                      title: Text(context.l10n.videos),
                      trailing: Transform.scale(
                          scale: 0.7,
                          child: CupertinoSwitch(
                            activeColor: context.theme.accent,
                            value: authState.currentVideoAutoDownload,
                            onChanged: (bool value) => context.multiAuthCubit
                                .setCurrentSetting(videoAutoDownload: value),
                          )),
                    ),
                    CellItem(
                      title: Text(context.l10n.files),
                      trailing: Transform.scale(
                          scale: 0.7,
                          child: CupertinoSwitch(
                            activeColor: context.theme.accent,
                            value: authState.currentFileAutoDownload,
                            onChanged: (bool value) => context.multiAuthCubit
                                .setCurrentSetting(fileAutoDownload: value),
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
                cellBackgroundColor: context.dynamicColor(
                  Colors.white,
                  darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
                ),
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
