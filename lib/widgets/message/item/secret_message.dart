import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../ui/provider/ui_context_providers.dart';
import '../../../utils/uri_utils.dart';

import '../message_style.dart';

class SecretMessage extends ConsumerWidget {
  const SecretMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final textColor = ref.watch(
      dynamicColorProvider(
        (
          color: const Color.fromRGBO(0, 0, 0, 1),
          darkColor: null,
        ),
      ),
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () =>
                openUri(context, l10n.secretUrl, container: ref.container),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.encrypt,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  l10n.messageE2ee,
                  style: TextStyle(
                    fontSize: context.messageStyle.secondaryFontSize,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
