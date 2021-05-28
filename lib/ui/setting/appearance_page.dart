import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bloc/setting_cubits.dart';
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
        body: const Align(alignment: Alignment.topCenter, child: _Body()),
      );
}

class _Body extends StatelessWidget {
  const _Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: CellGroup(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 14, top: 24),
              child: Text(
                Localization.of(context).settingTheme,
                style: TextStyle(
                  color: BrightnessData.themeOf(context).secondaryText,
                  fontSize: 14,
                ),
              ),
            ),
            CellItem(
              title: RadioItem<Brightness?>(
                title: Text(Localization.of(context).settingThemeAuto),
                groupValue: context.watch<BrightnessCubit>().state,
                onChanged: (value) =>
                    context.read<BrightnessCubit>().emit(value),
                value: null,
              ),
              trailing: null,
            ),
            CellItem(
              title: RadioItem<Brightness?>(
                title: Text(Localization.of(context).settingThemeLight),
                groupValue: context.watch<BrightnessCubit>().state,
                onChanged: (value) =>
                    context.read<BrightnessCubit>().emit(value),
                value: Brightness.light,
              ),
              trailing: null,
            ),
            CellItem(
              title: RadioItem<Brightness?>(
                title: Text(Localization.of(context).settingThemeNight),
                groupValue: context.watch<BrightnessCubit>().state,
                onChanged: (value) =>
                    context.read<BrightnessCubit>().emit(value),
                value: Brightness.dark,
              ),
              trailing: null,
            ),
          ],
        )),
      );
}
