import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

import '../constants/resources.dart';
import '../utils/extension/extension.dart';
import 'interacter_decorated_box.dart';

class SearchTextField extends HookWidget {
  const SearchTextField({
    Key? key,
    this.focusNode,
    required this.controller,
    this.onChanged,
    this.fontSize = 14,
    this.hintText,
    this.autofocus = false,
  }) : super(key: key);

  final FocusNode? focusNode;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final double fontSize;

  final String? hintText;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    const outlineInputBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.transparent,
      ),
      borderRadius: BorderRadius.all(
        Radius.circular(20),
      ),
      gapPadding: 0,
    );
    final backgroundColor = context.dynamicColor(
      const Color.fromRGBO(245, 247, 250, 1),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
    );
    final hintColor = context.theme.secondaryText;

    useEffect(() {
      void notifyChanged() {
        onChanged?.call(controller.text);
      }

      // listen controller state to update onChanged, in case value updated by
      // controller by onChanged is not called.
      controller.addListener(notifyChanged);
      return () {
        controller.removeListener(notifyChanged);
      };
    }, [controller, onChanged]);

    return Center(
      child: TextField(
        focusNode: focusNode,
        autofocus: autofocus,
        controller: controller,
        style: TextStyle(
          color: context.theme.text,
          fontSize: fontSize,
        ),
        scrollPadding: EdgeInsets.zero,
        decoration: InputDecoration(
          isDense: true,
          border: outlineInputBorder,
          focusedBorder: outlineInputBorder,
          enabledBorder: outlineInputBorder,
          filled: true,
          fillColor: backgroundColor,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          prefixIconConstraints:
              const BoxConstraints.expand(width: 40, height: 32),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: SvgPicture.asset(
              Resources.assetsImagesIcSearchSmallSvg,
              color: hintColor,
            ),
          ),
          suffixIconConstraints:
              const BoxConstraints.expand(width: 32, height: 36),
          suffixIcon: Center(child: _SearchClearIcon(controller)),
          contentPadding: const EdgeInsets.only(right: 8),
          hintText: hintText,
          hintStyle: TextStyle(
            color: hintColor,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}

class _SearchClearIcon extends HookWidget {
  const _SearchClearIcon(this.controller, {Key? key}) : super(key: key);

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final editingText = useValueListenable(controller);
    if (editingText.text.isEmpty) {
      return const SizedBox();
    } else {
      return MouseRegion(
        cursor: SystemMouseCursors.basic,
        child: InteractiveDecoratedBox(
          onTap: () {
            controller.text = '';
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.close,
              color: context.theme.secondaryText,
            ),
          ),
        ),
      );
    }
  }
}
