import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../constants/constants.dart';
import '../../../utils/extension/extension.dart';
import '../../../widgets/high_light_text.dart';

class ImageCaptionInputWidget extends HookWidget {
  const ImageCaptionInputWidget({
    required this.textEditingController,
    super.key,
  });

  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 40),
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      color: context.dynamicColor(
        const Color.fromRGBO(245, 247, 250, 1),
        darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
      ),
    ),
    alignment: Alignment.center,
    child: TextField(
      maxLines: 3,
      minLines: 1,
      controller: textEditingController,
      style: TextStyle(color: context.theme.text, fontSize: 14),
      inputFormatters: [LengthLimitingTextInputFormatter(kMaxTextLength)],
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        isDense: true,
        hintText: context.l10n.addACaption,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        hintStyle: TextStyle(color: context.theme.secondaryText, fontSize: 14),
        contentPadding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
      ),
      selectionHeightStyle: ui.BoxHeightStyle.includeLineSpacingMiddle,
      contextMenuBuilder:
          (context, state) =>
              MixinAdaptiveSelectionToolbar(editableTextState: state),
    ),
  );
}
