import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/ui/home/bloc/multi_auth_cubit.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator_cubit.dart';
import 'package:flutter_app/utils/hook.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/widgets/cell.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

class StoragePage extends HookWidget {
  const StoragePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authState = useBlocState<MultiAuthCubit, MultiAuthState>();

    return Scaffold(
      backgroundColor: BrightnessData.themeOf(context).background,
      appBar: MixinAppBar(
        title: Text(Localization.of(context).dataAndStorageUsage),
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CellGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CellItem(
                      title: Text(Localization.of(context).photos),
                      trailing: CupertinoSwitch(
                        activeColor: BrightnessData.themeOf(context).accent,
                        value: authState.currentPhotoAutoDownload,
                        onChanged: (bool value) => context
                            .read<MultiAuthCubit>()
                            .setCurrentSetting(photoAutoDownload: value),
                      ),
                    ),
                    CellItem(
                      title: Text(Localization.of(context).videos),
                      trailing: CupertinoSwitch(
                        activeColor: BrightnessData.themeOf(context).accent,
                        value: authState.currentVideoAutoDownload,
                        onChanged: (bool value) => context
                            .read<MultiAuthCubit>()
                            .setCurrentSetting(videoAutoDownload: value),
                      ),
                    ),
                    CellItem(
                      title: Text(Localization.of(context).files),
                      trailing: CupertinoSwitch(
                        activeColor: BrightnessData.themeOf(context).accent,
                        value: authState.currentFileAutoDownload,
                        onChanged: (bool value) => context
                            .read<MultiAuthCubit>()
                            .setCurrentSetting(fileAutoDownload: value),
                      ),
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
