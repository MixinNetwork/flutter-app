import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bloc/setting_cubit.dart';
import '../../generated/l10n.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/brightness_observer.dart';
import '../../widgets/cell.dart';
import '../../widgets/radio.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: BrightnessData.themeOf(context).background,
        appBar: MixinAppBar(
          title: Text(Localization.of(context).appearance),
          actions: const [],
        ),
        body: const Align(
          alignment: Alignment.topCenter,
          child: _Body(),
        ),
      );
}

class _Body extends StatelessWidget {
  const _Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      child: Container(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 14),
                child: Text(
                  Localization.of(context).settingTheme,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CellItem(
                      title: RadioItem<Brightness?>(
                        title: Text(Localization.of(context).settingThemeAuto),
                        groupValue: context.watch<SettingCubit>().brightness,
                        onChanged: (value) =>
                            context.read<SettingCubit>().brightness = value,
                        value: null,
                      ),
                      trailing: null,
                    ),
                    CellItem(
                      title: RadioItem<Brightness?>(
                        title: Text(Localization.of(context).settingThemeLight),
                        groupValue: context.watch<SettingCubit>().brightness,
                        onChanged: (value) =>
                            context.read<SettingCubit>().brightness = value,
                        value: Brightness.light,
                      ),
                      trailing: null,
                    ),
                    CellItem(
                      title: RadioItem<Brightness?>(
                        title: Text(Localization.of(context).settingThemeNight),
                        groupValue: context.watch<SettingCubit>().brightness,
                        onChanged: (value) =>
                            context.read<SettingCubit>().brightness = value,
                        value: Brightness.dark,
                      ),
                      trailing: null,
                    ),
                  ],
                ),
              )
            ],
          )));
}
