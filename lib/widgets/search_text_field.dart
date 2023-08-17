import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../constants/constants.dart';
import '../constants/resources.dart';
import '../utils/extension/extension.dart';
import '../utils/hook.dart';
import 'interactive_decorated_box.dart';

class SearchTextField extends HookConsumerWidget {
  const SearchTextField({
    super.key,
    this.focusNode,
    required this.controller,
    this.onChanged,
    this.fontSize = 14,
    this.hintText,
    this.autofocus = false,
    this.showClear = false,
    this.onTapClear,
    this.leading,
  });

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
  Widget build(BuildContext context, WidgetRef ref) {
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

    final textStream = useValueNotifierConvertSteam(controller);
    final hasText = useMemoizedStream(
          () => textStream.map((event) => event.text.isNotEmpty).distinct(),
        ).data ??
        controller.text.isNotEmpty;

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
                colorFilter: ColorFilter.mode(hintColor, BlendMode.srcIn),
              ),
            ),
            if (leading != null) leading!,
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Align(
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
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: true,
                        border: InputBorder.none,
                        fillColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        contentPadding: EdgeInsets.zero,
                      ),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          kDefaultTextInputLimit,
                        ),
                      ],
                    ),
                  ),
                  if (hintText != null && !hasText)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IgnorePointer(
                        child: Text(
                          hintText!,
                          style: TextStyle(
                            color: hintColor,
                            fontSize: fontSize,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (showClear || hasText)
              _SearchClearIcon(onTap: () {
                controller.text = '';
                onTapClear?.call();
              })
            else
              const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}

class _SearchClearIcon extends HookConsumerWidget {
  const _SearchClearIcon({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) => InteractiveDecoratedBox(
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
