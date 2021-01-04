import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/back_button.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';

class MixinAppBar extends StatelessWidget {
  const MixinAppBar({
    Key key,
    this.title,
    this.actions,
  }) : super(key: key);

  final dynamic title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => builderAppBar(
        context,
        title: title,
        actions: actions,
      );

  static PreferredSizeWidget builderAppBar(
    BuildContext context, {
    dynamic title,
    List<Widget> actions,
  }) {
    assert(title is Widget || title is String);
    final actionTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: BrightnessData.dynamicColor(
        context,
        const Color.fromRGBO(61, 117, 227, 1),
        darkColor: const Color.fromRGBO(65, 145, 255, 1),
      ),
    );
    return AppBar(
      title: title is Widget ? title : Text(title),
      actions: actions
          ?.map((e) => DefaultTextStyle(style: actionTextStyle, child: e))
          ?.toList(),
      elevation: 0,
      centerTitle: true,
      backgroundColor: BrightnessData.dynamicColor(
        context,
        const Color.fromRGBO(255, 255, 255, 1),
        darkColor: const Color.fromRGBO(44, 49, 54, 1),
      ),
      leading: Builder(
        builder: (context) => ModalRoute.of(context)?.canPop ?? false
            ? const MixinBackButton()
            : const SizedBox(width: 56),
      ),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: BrightnessData.dynamicColor(
          context,
          const Color.fromRGBO(51, 51, 51, 1),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.9),
        ),
      ),
    );
  }
}
