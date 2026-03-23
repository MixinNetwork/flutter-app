import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../ui/provider/ui_context_providers.dart';
import 'buttons.dart';
import 'window/move_window.dart';

class MixinAppBar extends ConsumerWidget implements PreferredSizeWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final actionTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: theme.accent,
    );
    return MoveWindow(
      child: AppBar(
        toolbarHeight: 64,
        title: title == null
            ? null
            : DefaultTextStyle.merge(
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.text,
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
        backgroundColor: backgroundColor ?? theme.primary,
        leading: MoveWindowBarrier(
          child: Builder(
            builder: (context) =>
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
