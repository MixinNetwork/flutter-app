import 'package:flutter/material.dart';
import 'package:flutter_app/constants/assets.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';

import 'action_button.dart';

class InputContainer extends StatelessWidget {
  const InputContainer({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final actionColor = BrightnessData.dynamicColor(
      context,
      const Color.fromRGBO(47, 48, 50, 1),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.9),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrightnessData.dynamicColor(
          context,
          const Color.fromRGBO(255, 255, 255, 1),
          darkColor: const Color.fromRGBO(44, 49, 54, 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ActionButton(
              name: Assets.assetsImagesIcFilePng,
              color: actionColor,
              onTap: () {},
            ),
            const SizedBox(width: 6),
            ActionButton(
              name: Assets.assetsImagesIcStickerPng,
              color: actionColor,
              onTap: () {},
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 32,
                ),
                child: TextField(
                  maxLines: 5,
                  minLines: 1,
                  onEditingComplete: () {},
                  onSubmitted: (_) {
                  },
                  style: TextStyle(
                    color: BrightnessData.dynamicColor(
                      context,
                      const Color.fromRGBO(51, 51, 51, 1),
                      darkColor: const Color.fromRGBO(255, 255, 255, 0.9),
                    ),
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ActionButton(
              name: Assets.assetsImagesIcSendPng,
              color: actionColor,
              onTap: () {

              },
            ),
          ],
        ),
      ),
    );
  }
}
