import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/brightness_observer.dart';

import '../../widgets/cell.dart';
import '../home/bloc/multi_auth_cubit.dart';

class NotificationPage extends HookWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentMessagePreview =
        useBlocStateConverter<MultiAuthCubit, MultiAuthState, bool>(
      converter: (state) => state.currentMessagePreview,
    );
    return Scaffold(
      backgroundColor: context.theme.background,
      appBar: MixinAppBar(
        title: Text(context.l10n.notification),
      ),
      body: Container(
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CellGroup(
              padding: const EdgeInsets.only(right: 10, left: 10),
              cellBackgroundColor: BrightnessData.dynamicColor(
                context,
                Colors.white,
                darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
              ),
              child: CellItem(
                title: Text(context.l10n.messagePreview),
                trailing: Transform.scale(
                  scale: 0.7,
                  child: CupertinoSwitch(
                    activeColor: context.theme.accent,
                    value: currentMessagePreview,
                    onChanged: (bool value) => context.multiAuthCubit
                        .setCurrentSetting(messagePreview: value),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 14, top: 10),
              child: Text(
                context.l10n.messagePreviewDescription,
                style: TextStyle(
                  color: context.theme.secondaryText,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
