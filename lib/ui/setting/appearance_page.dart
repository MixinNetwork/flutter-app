import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bloc/setting_cubit.dart';
import '../../utils/extension/extension.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/brightness_observer.dart';

import '../../widgets/cell.dart';
import '../../widgets/radio.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.theme.background,
        appBar: MixinAppBar(
          title: Text(context.l10n.appearance),
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
                  context.l10n.settingTheme,
                  style: TextStyle(
                    color: context.theme.secondaryText,
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
                        title: Text(context.l10n.settingThemeAuto),
                        groupValue: context.watch<SettingCubit>().brightness,
                        onChanged: (value) =>
                            context.read<SettingCubit>().brightness = value,
                        value: null,
                      ),
                      trailing: null,
                    ),
                    CellItem(
                      title: RadioItem<Brightness?>(
                        title: Text(context.l10n.settingThemeLight),
                        groupValue: context.watch<SettingCubit>().brightness,
                        onChanged: (value) =>
                            context.read<SettingCubit>().brightness = value,
                        value: Brightness.light,
                      ),
                      trailing: null,
                    ),
                    CellItem(
                      title: RadioItem<Brightness?>(
                        title: Text(context.l10n.settingThemeNight),
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
