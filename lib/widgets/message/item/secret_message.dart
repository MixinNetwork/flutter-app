import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../brightness_observer.dart';

class SecretMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 4,
            horizontal: 8,
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () =>
                  launch(Localization.of(context).aboutEncryptedInfoUrl),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: BrightnessData.themeOf(context).encrypt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    Localization.of(context).aboutEncryptedInfo,
                    style: TextStyle(
                      fontSize: 14,
                      color: BrightnessData.dynamicColor(
                        context,
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
