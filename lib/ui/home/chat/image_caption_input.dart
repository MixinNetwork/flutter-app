import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/constants.dart';
import '../../../ui/provider/ui_context_providers.dart';
import '../../../widgets/high_light_text.dart';

class ImageCaptionInputWidget extends HookConsumerWidget {
  const ImageCaptionInputWidget({
    required this.textEditingController,
    super.key,
  });

  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final backgroundColor = ref.watch(
      dynamicColorProvider((
        color: const Color.fromRGBO(245, 247, 250, 1),
        darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
      )),
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        color: backgroundColor,
      ),
      alignment: Alignment.center,
      child: TextField(
        maxLines: 3,
        minLines: 1,
        controller: textEditingController,
        style: TextStyle(
          color: theme.text,
          fontSize: 14,
        ),
        inputFormatters: [LengthLimitingTextInputFormatter(kMaxTextLength)],
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          hintText: l10n.addACaption,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintStyle: TextStyle(
            color: theme.secondaryText,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
        ),
        selectionHeightStyle: ui.BoxHeightStyle.includeLineSpacingMiddle,
        contextMenuBuilder: (context, state) =>
            MixinAdaptiveSelectionToolbar(editableTextState: state),
      ),
    );
  }
}
