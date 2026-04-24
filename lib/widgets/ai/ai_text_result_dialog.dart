import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/extension/extension.dart';
import '../dialog.dart';
import '../toast.dart';

enum AiTextResultAction { replace, insert }

Future<AiTextResultAction?> showAiTextResultDialog({
  required BuildContext context,
  required String title,
  required String result,
  String? original,
  bool allowReplace = true,
}) => showMixinDialog<AiTextResultAction>(
  context: context,
  constraints: const BoxConstraints(maxWidth: 560),
  child: AlertDialogLayout(
    minWidth: 420,
    minHeight: 0,
    titleMarginBottom: 20,
    title: Text(title),
    content: _AiTextResultContent(original: original, result: result),
    actions: [
      MixinButton(
        backgroundTransparent: true,
        child: const Text('Copy'),
        onTap: () {
          Clipboard.setData(ClipboardData(text: result));
          showToastSuccessful(context: context);
          Navigator.pop(context);
        },
      ),
      const MixinButton(
        backgroundTransparent: true,
        value: AiTextResultAction.insert,
        child: Text('Insert'),
      ),
      if (allowReplace)
        const MixinButton(
          value: AiTextResultAction.replace,
          child: Text('Replace'),
        ),
    ],
  ),
);

class _AiTextResultContent extends StatelessWidget {
  const _AiTextResultContent({required this.result, this.original});

  final String? original;
  final String result;

  @override
  Widget build(BuildContext context) {
    final original = this.original?.trim();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: SingleChildScrollView(
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: context.theme.text,
            fontSize: 14,
            fontWeight: FontWeight.normal,
            height: 1.45,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (original != null && original.isNotEmpty) ...[
                const _SectionLabel('Original'),
                _TextBlock(original),
                const SizedBox(height: 16),
              ],
              const _SectionLabel('AI'),
              _TextBlock(result),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        color: context.theme.secondaryText,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class _TextBlock extends StatelessWidget {
  const _TextBlock(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.dynamicColor(
        const Color.fromRGBO(245, 247, 250, 1),
        darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
      ),
      borderRadius: const BorderRadius.all(Radius.circular(6)),
    ),
    child: SelectableText(text),
  );
}
