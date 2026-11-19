import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../constants/constants.dart';
import '../../../utils/extension/extension.dart';
import '../../../widgets/high_light_text.dart';
import '../../../widgets/text_field_hint.dart';
import '../../provider/setting_provider.dart';

class ImageCaptionInputWidget extends HookConsumerWidget {
  const ImageCaptionInputWidget({
    required this.textEditingController,
    super.key,
  });

  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize =
        14.0 +
        ref.watch(settingProvider.select((value) => value.chatFontSizeDelta));
    return Container(
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
        style: TextStyle(color: context.theme.text, fontSize: fontSize),
        inputFormatters: [LengthLimitingTextInputFormatter(kMaxTextLength)],
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          hint: TextFieldHint(
            context.l10n.addACaption,
            style: Theme.of(context).textTheme.bodyLarge!.merge(
              TextStyle(color: context.theme.secondaryText, fontSize: fontSize),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
        ),
        selectionHeightStyle: ui.BoxHeightStyle.includeLineSpacingMiddle,
        contextMenuBuilder: (context, state) =>
            MixinAdaptiveSelectionToolbar(editableTextState: state),
      ),
    );
  }
}
