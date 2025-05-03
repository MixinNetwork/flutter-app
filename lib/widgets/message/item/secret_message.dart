import 'package:flutter/widgets.dart';

import '../../../utils/extension/extension.dart';
import '../../../utils/uri_utils.dart';

import '../message_style.dart';

class SecretMessage extends StatelessWidget {
  const SecretMessage({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => openUri(context, context.l10n.secretUrl),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.theme.encrypt,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                context.l10n.messageE2ee,
                style: TextStyle(
                  fontSize: context.messageStyle.secondaryFontSize,
                  color: context.dynamicColor(const Color.fromRGBO(0, 0, 0, 1)),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
