import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../bloc/setting_cubit.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../widgets/app_bar.dart';
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
                  context.l10n.theme,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CellItem(
                      title: RadioItem<Brightness?>(
                        title: Text(context.l10n.followSystem),
                        groupValue: context.watch<SettingCubit>().brightness,
                        onChanged: (value) =>
                            context.settingCubit.brightness = value,
                        value: null,
                      ),
                      trailing: null,
                    ),
                    CellItem(
                      title: RadioItem<Brightness?>(
                        title: Text(context.l10n.light),
                        groupValue: context.watch<SettingCubit>().brightness,
                        onChanged: (value) =>
                            context.settingCubit.brightness = value,
                        value: Brightness.light,
                      ),
                      trailing: null,
                    ),
                    CellItem(
                      title: RadioItem<Brightness?>(
                        title: Text(context.l10n.dark),
                        groupValue: context.watch<SettingCubit>().brightness,
                        onChanged: (value) =>
                            context.settingCubit.brightness = value,
                        value: Brightness.dark,
                      ),
                      trailing: null,
                    ),
                  ],
                ),
              ),
              const _MessageAvatarSetting(),
            ],
          )));
}

class _MessageAvatarSetting extends HookWidget {
  const _MessageAvatarSetting({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final showAvatar = useBlocStateConverter<SettingCubit, SettingState, bool>(
      converter: (style) => style.messageShowAvatar,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 14, top: 22),
          child: Text(
            context.l10n.avatar,
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
            title: Text(context.l10n.showAvatar),
            trailing: Transform.scale(
                scale: 0.7,
                child: CupertinoSwitch(
                  activeColor: context.theme.accent,
                  value: showAvatar,
                  onChanged: (bool value) =>
                      context.settingCubit.messageShowAvatar = value,
                )),
          ),
        )
      ],
    );
  }
}
