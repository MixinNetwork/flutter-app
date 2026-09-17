import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/extension/extension.dart';
import 'app_bar.dart';
import 'buttons.dart';
import 'markdown.dart';

class MarkdownFilePreview extends StatelessWidget {
  const MarkdownFilePreview({required this.content, super.key});

  static Future<void> push(
    BuildContext context, {
    required String content,
  }) => showGeneralDialog(
    context: context,
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    requestFocus: true,
    pageBuilder:
        (
          buildContext,
          animation,
          secondaryAnimation,
        ) =>
            InheritedTheme.capture(
              from: context,
              to: Navigator.of(context, rootNavigator: true).context,
            ).wrap(
              MarkdownFilePreview(content: content),
            ),
  );

  final String content;

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
    },
    actions: {
      DismissIntent: CallbackAction<Intent>(
        onInvoke: (intent) => Navigator.maybePop(context),
      ),
    },
    autofocus: true,
    child: Material(
      color: context.theme.background,
      child: Column(
        children: [
          MixinAppBar(
            leading: const SizedBox(),
            actions: [MixinCloseButton(onTap: () => Navigator.pop(context))],
          ),
          Expanded(
            child: Markdown(
              data: content,
              maxContentWidth: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 32),
            ),
          ),
        ],
      ),
    ),
  );
}
