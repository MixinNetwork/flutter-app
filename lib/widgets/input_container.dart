import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/constants/assets.dart';
import 'package:flutter_app/ui/home/bloc/draft_cubit.dart';
import 'package:flutter_app/ui/home/bloc/message_bloc.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/hoer_overlay.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            HoverOverlay(
              child: ActionButton(
                name: Assets.assetsImagesIcStickerPng,
                color: actionColor,
              ),
              childAnchor: Alignment.topCenter,
              overlayAnchor: Alignment.bottomCenter,
              offset: const Offset(0, -17),
              overlayBuilder: (BuildContext context) => const _StickerPage(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 32,
                ),
                child: Focus(
                  onKey: (FocusNode node, RawKeyEvent event) {
                    if (setEquals(RawKeyboard.instance.keysPressed,
                        {LogicalKeyboardKey.enter})) {
                      final textEditingController =
                          BlocProvider.of<DraftCubit>(context)
                              .textEditingController;

                      final text = textEditingController.value.text;
                      final valid =
                          textEditingController.value.isComposingRangeValid;
                      if (text?.trim()?.isNotEmpty == true && !valid) {
                        textEditingController.text = '';
                        BlocProvider.of<MessageBloc>(context).send(text);
                      }

                      return valid
                          ? KeyEventResult.ignored
                          : KeyEventResult.handled;
                    }

                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    maxLines: 5,
                    minLines: 1,
                    controller: BlocProvider.of<DraftCubit>(context)
                        .textEditingController,
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
            ),
            const SizedBox(width: 16),
            ActionButton(
              name: Assets.assetsImagesIcSendPng,
              color: actionColor,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _StickerPage extends StatelessWidget {
  const _StickerPage({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 464,
      height: 407,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        color: BrightnessData.dynamicColor(
          context,
          const Color.fromRGBO(255, 255, 255, 1),
          darkColor: const Color.fromRGBO(62, 65, 72, 1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          children: [
            const Expanded(child: SizedBox()),
            Container(
              width: double.infinity,
              height: 60,
              color: BrightnessData.dynamicColor(
                context,
                const Color.fromRGBO(0, 0, 0, 0.05),
                darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
