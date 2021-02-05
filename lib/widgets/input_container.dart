import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/draft_cubit.dart';
import 'package:flutter_app/utils/file.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/hoer_overlay.dart';
import 'package:flutter_app/widgets/sticker_page/sticker_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/generated/l10n.dart';

import 'action_button.dart';
import 'dash_path_border.dart';
import 'interacter_decorated_box.dart';

class InputContainer extends StatelessWidget {
  const InputContainer({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final actionColor = BrightnessData.themeOf(context).icon;

    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BrightnessData.themeOf(context).primary,
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
                  final file = await selectFile();

                  if (file.isImage) {
                    if (!await _PreviewImage.push(context, file)) return;
                    return Provider.of<AccountServer>(context, listen: false)
                        .sendImageMessage(
                      BlocProvider.of<ConversationCubit>(context)
                          .state
                          .conversationId,
                      File(file.path),
                    );
                  }
                  Provider.of<AccountServer>(context, listen: false)
                      .sendAttachment(
                    BlocProvider.of<ConversationCubit>(context)
                        .state
                        .conversationId,
                    file,
                  );
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
                        color: BrightnessData.themeOf(context).text,
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

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({Key key, this.xFile}) : super(key: key);

  final XFile xFile;

  static Future<bool> push(BuildContext context, XFile xFile) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => _PreviewImage(xFile: xFile),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: BrightnessData.themeOf(context).primary,
        ),
        child: Column(
          children: [
            SizedBox(
              height: 58,
              child: Row(
                children: [
                  ActionButton(
                    name: Resources.assetsImagesIcClosePng,
                    color: BrightnessData.themeOf(context).icon,
                    onTap: () => Navigator.pop(context, false),
                  ),
                  Text(
                    Localization.of(context).preview,
                    style: TextStyle(
                      color: BrightnessData.themeOf(context).text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 1,
                  right: 16,
                  left: 16,
                  bottom: 30,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: BrightnessData.themeOf(context).listSelected,
                    borderRadius: BorderRadius.circular(8),
                    border: DashPathBorder.all(
                      borderSide: BorderSide(
                        color: BrightnessData.dynamicColor(
                          context,
                          const Color.fromRGBO(229, 231, 235, 1),
                          darkColor: const Color.fromRGBO(255, 255, 255, 0.8),
                        ),
                      ),
                      dashArray: CircularIntervalList([4, 4]),
                    ),
                  ),
                  child: Image.file(File(xFile.path)),
                ),
              ),
            ),
            ClipOval(
              child: InteractableDecoratedBox.color(
                onTap: () => Navigator.pop(context, true),
                decoration: BoxDecoration(
                  color: BrightnessData.themeOf(context).accent,
                ),
                child: SizedBox.fromSize(
                  size: const Size.square(50),
                  child: Center(
                    child: SvgPicture.asset(
                      Resources.assetsImagesIcArrowRightSvg,
                      color: BrightnessData.dynamicColor(
                        context,
                        const Color.fromRGBO(255, 255, 255, 1),
                        darkColor: const Color.fromRGBO(255, 255, 255, 0.9),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
}
