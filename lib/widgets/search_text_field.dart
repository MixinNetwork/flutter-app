import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

import '../constants/resources.dart';
import '../utils/extension/extension.dart';
import '../utils/hook.dart';
import 'animated_visibility.dart';
import 'interactive_decorated_box.dart';

class SearchTextField extends HookWidget {
  const SearchTextField({
    Key? key,
    this.focusNode,
    required this.controller,
    this.onChanged,
    this.fontSize = 14,
    this.hintText,
    this.autofocus = false,
    this.showClear = false,
    this.onTapClear,
    this.leading,
  }) : super(key: key);

  final FocusNode? focusNode;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final double fontSize;

  final String? hintText;
  final bool autofocus;

  final bool showClear;
  final VoidCallback? onTapClear;

  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final _focusNode = useMemoized(() => focusNode ?? FocusNode());
    final backgroundColor = context.dynamicColor(
      const Color.fromRGBO(245, 247, 250, 1),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
    );
    final hintColor = context.theme.secondaryText;

    useEffect(() {
      void notifyChanged() {
        if (!controller.value.composing.composed) return;
        onChanged?.call(controller.text);
      }

      // listen controller state to update onChanged, in case value updated by
      // controller by onChanged is not called.
      controller.addListener(notifyChanged);
      return () {
        controller.removeListener(notifyChanged);
      };
    }, [controller, onChanged]);

    return InteractiveDecoratedBox(
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: const StadiumBorder(),
      ),
      cursor: SystemMouseCursors.text,
      onTap: _focusNode.requestFocus,
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: SvgPicture.asset(
                Resources.assetsImagesIcSearchSmallSvg,
                color: hintColor,
              ),
            ),
            if (leading != null) leading!,
            Expanded(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.centerLeft,
                child: TextField(
                  focusNode: _focusNode,
                  autofocus: autofocus,
                  controller: controller,
                  style: TextStyle(
                    color: context.theme.text,
                    fontSize: fontSize,
                  ),
                  scrollPadding: EdgeInsets.zero,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    hintText: hintText,
                    border: InputBorder.none,
                    fillColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(
                      color: hintColor,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ),
            ),
            HookBuilder(builder: (context) {
              final stream = useValueNotifierConvertSteam(controller);
              final isNotEmpty = useMemoizedStream(
                () => stream.map((event) => event.text.trim().isNotEmpty),
                initialData: showClear,
              ).requireData;

              return AnimatedVisibility(
                visible: showClear || isNotEmpty,
                child: _SearchClearIcon(onTap: () {
                  controller.text = '';
                  onTapClear?.call();
                }),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SearchClearIcon extends HookWidget {
  const _SearchClearIcon({Key? key, required this.onTap}) : super(key: key);

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InteractiveDecoratedBox(
        cursor: SystemMouseCursors.basic,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(right: 16, left: 8),
          child: Icon(
            Icons.close,
            color: context.theme.secondaryText,
            size: 16,
          ),
        ),
      );
}
