import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/back_button.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';

class MixinAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MixinAppBar({
    Key? key,
    this.title,
    this.actions = const [],
  }) : super(key: key);

  final dynamic title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    assert(title is Widget || title is String);
    final actionTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: BrightnessData.themeOf(context).accent,
    );
    return AppBar(
      toolbarHeight: 64,
      title: DefaultTextStyle(
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: BrightnessData.themeOf(context).text,
        ),
        child: title is Widget
            ? title
            : Text(
                title,
              ),
      ),
      actions: actions
          .map((e) => DefaultTextStyle(style: actionTextStyle, child: e))
          .toList(),
      elevation: 0,
      centerTitle: true,
      backgroundColor: BrightnessData.themeOf(context).primary,
      leading: Builder(
        builder: (context) => ModalRoute.of(context)?.canPop ?? false
            ? const MixinBackButton()
            : const SizedBox(width: 56),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
