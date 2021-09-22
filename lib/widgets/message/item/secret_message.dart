import 'package:flutter/widgets.dart';

import '../../../utils/extension/extension.dart';
import '../../../utils/uri_utils.dart';

import '../message.dart';

class SecretMessage extends StatelessWidget {
  const SecretMessage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => openUri(context, context.l10n.aboutEncryptedInfoUrl),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.theme.encrypt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    context.l10n.aboutEncryptedInfo,
                    style: TextStyle(
                      fontSize: MessageItemWidget.secondaryFontSize,
                      color: context.dynamicColor(
                        const Color.fromRGBO(0, 0, 0, 1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
