import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n.dart';
import '../../utils/hook.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/brightness_observer.dart';
import '../../widgets/cell.dart';
import '../home/bloc/multi_auth_cubit.dart';
import '../home/route/responsive_navigator_cubit.dart';

class StoragePage extends HookWidget {
  const StoragePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authState = useBlocState<MultiAuthCubit, MultiAuthState>();

    return Scaffold(
      backgroundColor: BrightnessData.themeOf(context).background,
      appBar: MixinAppBar(
        title: Text(Localization.of(context).dataAndStorageUsage),
      ),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CellGroup(
                cellBackgroundColor: BrightnessData.dynamicColor(
                  context,
                  Colors.white,
                  darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CellItem(
                      title: Text(Localization.of(context).photos),
                      trailing: Transform.scale(
                          scale: 0.7,
                          child: CupertinoSwitch(
                            activeColor: BrightnessData.themeOf(context).accent,
                            value: authState.currentPhotoAutoDownload,
                            onChanged: (bool value) => context
                                .read<MultiAuthCubit>()
                                .setCurrentSetting(photoAutoDownload: value),
                          )),
                    ),
                    CellItem(
                      title: Text(Localization.of(context).videos),
                      trailing: Transform.scale(
                          scale: 0.7,
                          child: CupertinoSwitch(
                            activeColor: BrightnessData.themeOf(context).accent,
                            value: authState.currentVideoAutoDownload,
                            onChanged: (bool value) => context
                                .read<MultiAuthCubit>()
                                .setCurrentSetting(videoAutoDownload: value),
                          )),
                    ),
                    CellItem(
                      title: Text(Localization.of(context).files),
                      trailing: Transform.scale(
                          scale: 0.7,
                          child: CupertinoSwitch(
                            activeColor: BrightnessData.themeOf(context).accent,
                            value: authState.currentFileAutoDownload,
                            onChanged: (bool value) => context
                                .read<MultiAuthCubit>()
                                .setCurrentSetting(fileAutoDownload: value),
                          )),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 14, top: 10),
                child: Text(
                  Localization.of(context).storageAutoDownloadDescription,
                  style: TextStyle(
                    color: BrightnessData.themeOf(context).secondaryText,
                    fontSize: 14,
                  ),
                ),
              ),
              CellGroup(
                cellBackgroundColor: BrightnessData.dynamicColor(
                  context,
                  Colors.white,
                  darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
                ),
                child: CellItem(
                  title: Text(Localization.of(context).storageUsage),
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
