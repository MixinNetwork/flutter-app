import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';

class WindowTitleBar extends StatelessWidget {
  const WindowTitleBar({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) {
      return child;
    }
    return Column(
      children: [
        const _TitleBar(),
        Expanded(child: child),
      ],
    );
  }
}

class _TitleBar extends HookWidget {
  const _TitleBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = useState(0);

    void maximizeOrRestore() {
      appWindow.maximizeOrRestore();
      state.value += 1;
    }

    final buttonColors = WindowButtonColors(
      iconNormal: context.theme.icon,
      iconMouseOver: context.theme.icon,
      iconMouseDown: context.theme.icon,
      mouseOver: context.theme.listSelected,
      mouseDown: context.theme.listSelected,
    );

    return Container(
      height: appWindow.titleBarHeight,
      color: context.theme.primary,
      child: Row(
        children: [
          Expanded(
            child: MoveWindow(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 16),
                      Image.asset(
                        Resources.assetsIconsWindowsAppIconPng,
                        width: 18,
                        height: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mixin',
                        style: Theme.of(context).textTheme.bodyText1?.copyWith(
                              color: context.theme.text,
                              fontSize: 13,
                              height: 1,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          MinimizeWindowButton(colors: buttonColors),
          if (appWindow.isMaximized)
            _RestoreWindowButton(
              colors: buttonColors,
              onPressed: maximizeOrRestore,
            )
          else
            MaximizeWindowButton(
              colors: buttonColors,
              onPressed: maximizeOrRestore,
            ),
          CloseWindowButton(
            colors: WindowButtonColors(
              mouseOver: const Color(0xFFD32F2F),
              mouseDown: const Color(0xFFB71C1C),
              iconNormal: context.theme.icon,
              iconMouseOver: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestoreWindowButton extends WindowButton {
  _RestoreWindowButton(
      {Key? key,
      WindowButtonColors? colors,
      VoidCallback? onPressed,
      bool? animate})
      : super(
          key: key,
          colors: colors,
          animate: animate ?? false,
          iconBuilder: (buttonContext) =>
              RestoreIcon(color: buttonContext.iconColor),
          onPressed: onPressed ?? () => appWindow.maximizeOrRestore(),
        );
}
