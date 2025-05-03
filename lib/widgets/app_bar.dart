import 'package:flutter/material.dart';

import '../utils/extension/extension.dart';
import 'buttons.dart';
import 'window/move_window.dart';

class MixinAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MixinAppBar({
    super.key,
    this.title,
    this.actions = const [],
    this.backgroundColor,
    this.leading,
  });

  final Widget? title;
  final List<Widget> actions;
  final Color? backgroundColor;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final actionTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: context.theme.accent,
    );
    return MoveWindow(
      child: AppBar(
        toolbarHeight: 64,
        title:
            title == null
                ? null
                : DefaultTextStyle.merge(
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.theme.text,
                  ),
                  child: title!,
                ),
        actions: [
          ...actions.map(
            (e) => MoveWindowBarrier(
              child: DefaultTextStyle.merge(style: actionTextStyle, child: e),
            ),
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        centerTitle: true,
        backgroundColor: backgroundColor ?? context.theme.primary,
        leading: MoveWindowBarrier(
          child: Builder(
            builder:
                (context) =>
                    leading ??
                    (ModalRoute.of(context)?.canPop ?? false
                        ? const Center(child: MixinBackButton())
                        : const SizedBox(width: 56)),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
