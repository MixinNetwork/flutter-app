import 'package:flutter/material.dart';

import 'brightness_observer.dart';
import 'buttons.dart';
import 'window/move_window.dart';

class MixinAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MixinAppBar({
    Key? key,
    this.title,
    this.actions = const [],
    this.backgroundColor,
    this.leading,
  }) : super(key: key);

  final Widget? title;
  final List<Widget> actions;
  final Color? backgroundColor;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final actionTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: BrightnessData.themeOf(context).accent,
    );
    return MoveWindow(
      child: AppBar(
        toolbarHeight: 64,
        title: title == null
            ? null
            : DefaultTextStyle(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: BrightnessData.themeOf(context).text,
                ),
                child: title!,
              ),
        actions: [
          ...actions
              .map((e) => MoveWindowBarrier(
                    child: DefaultTextStyle(style: actionTextStyle, child: e),
                  ))
              .toList(),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        centerTitle: true,
        backgroundColor:
            backgroundColor ?? BrightnessData.themeOf(context).primary,
        leading: MoveWindowBarrier(
          child: Builder(
            builder: (context) => ModalRoute.of(context)?.canPop ?? false
                ? const Center(child: MixinBackButton())
                : leading ?? const SizedBox(width: 56),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
