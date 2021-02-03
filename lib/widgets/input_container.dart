import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/draft_cubit.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/hoer_overlay.dart';
import 'package:flutter_app/widgets/sticker_page/sticker_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

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
              name: Resources.assetsImagesIcFilePng,
              color: actionColor,
              onTap: () async {
                final file = await openFile();
                // todo send file
                // ignore: avoid_print
                print(
                    'path: ${file.path}, name: ${file.name}, mimeType: ${file.mimeType}');
              },
            ),
            const SizedBox(width: 6),
            HoverOverlay(
              child: ActionButton(
                name: Resources.assetsImagesIcStickerPng,
                color: actionColor,
              ),
              childAnchor: Alignment.topCenter,
              overlayAnchor: Alignment.bottomCenter,
              offset: const Offset(0, -17),
              overlayBuilder: (BuildContext context) => const StickerPage(),
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
                      return _sendMessage(context)
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
              name: Resources.assetsImagesIcSendPng,
              color: actionColor,
              onTap: () => _sendMessage(context),
            ),
          ],
        ),
      ),
    );
  }

  bool _sendMessage(BuildContext context) {
    final textEditingController =
        BlocProvider.of<DraftCubit>(context).textEditingController;

    final text = textEditingController.value.text;
    final valid = textEditingController.value.isComposingRangeValid;
    if (text?.trim()?.isNotEmpty == true && !valid) {
      textEditingController.text = '';
      Provider.of<AccountServer>(context, listen: false).sendTextMessage(
        BlocProvider.of<ConversationCubit>(context).state.conversationId,
        text,
      );
    }
    return valid;
  }
}
