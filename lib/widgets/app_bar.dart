import 'package:flutter/material.dart';

import 'back_button.dart';
import 'brightness_observer.dart';
import 'window/move_window.dart';

class MixinAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MixinAppBar({
    Key? key,
    this.title,
    this.actions = const [],
    this.backgroundColor,
  }) : super(key: key);

  final Widget? title;
  final List<Widget> actions;
  final Color? backgroundColor;

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
        actions: actions
            .map((e) => MoveWindowBarrier(
                  child: DefaultTextStyle(style: actionTextStyle, child: e),
                ))
            .toList(),
        elevation: 0,
        centerTitle: true,
        backgroundColor:
            backgroundColor ?? BrightnessData.themeOf(context).primary,
        leading: MoveWindowBarrier(
          child: Builder(
            builder: (context) => ModalRoute.of(context)?.canPop ?? false
                ? const MixinBackButton()
                : const SizedBox(width: 56),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
