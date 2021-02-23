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
import 'package:flutter_app/ui/home/bloc/mention_cubit.dart';
import 'package:flutter_app/ui/home/bloc/multi_auth_cubit.dart';
import 'package:flutter_app/ui/home/bloc/participants_cubit.dart';
import 'package:flutter_app/utils/file.dart';
import 'package:flutter_app/utils/reg_exp_utils.dart';
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
import 'mention_panel.dart';

class InputContainer extends StatelessWidget {
  const InputContainer({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => MentionCubit(
          userDao: context.read<AccountServer>().database.userDao,
          multiAuthCubit: BlocProvider.of<MultiAuthCubit>(context),
          participantsCubit: BlocProvider.of<ParticipantsCubit>(context),
        ),
        child: Builder(
          builder: (context) => ListenableProvider<TextEditingController>(
            create: (BuildContext _) {
              final textEditingController = HighlightTextEditingController(
                highlightTextStyle: TextStyle(
                  color: BrightnessData.themeOf(context).accent,
                ),
                participantsCubit: BlocProvider.of<ParticipantsCubit>(context),
              );
              textEditingController.addListener(() {
                final mention = mentionRegExp
                    .stringMatch(textEditingController.text)
                    ?.replaceFirst('@', '');
                BlocProvider.of<MentionCubit>(context).add(mention);
              });
              return textEditingController;
            },
            dispose: (BuildContext context,
                    TextEditingController textEditingController) =>
                textEditingController?.dispose(),
            child: LayoutBuilder(
              builder: (context, BoxConstraints constraints) => SizedBox(
                height: 56,
                child: MentionPanelPortalEntry(
                  constraints: constraints,
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
                          _FileButton(
                              actionColor:
                                  BrightnessData.themeOf(context).icon),
                          const SizedBox(width: 6),
                          const _StickerButton(),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: 32,
                              ),
                              child: Focus(
                                onKey: (FocusNode node, RawKeyEvent event) {
                                  if (setEquals(
                                      RawKeyboard.instance.keysPressed,
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
                                  controller:
                                      context.read<TextEditingController>(),
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
                            color: BrightnessData.themeOf(context).icon,
                            onTap: () => _sendMessage(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

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

class _StickerButton extends StatelessWidget {
  const _StickerButton({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HoverOverlay(
      child: ActionButton(
        name: Resources.assetsImagesIcStickerPng,
        color: BrightnessData.themeOf(context).icon,
      ),
      childAnchor: Alignment.topCenter,
      overlayAnchor: Alignment.bottomCenter,
      offset: const Offset(0, -17),
      overlayBuilder: (BuildContext context) => const StickerPage(),
    );
  }
}

class _FileButton extends StatelessWidget {
  const _FileButton({
    Key key,
    @required this.actionColor,
  }) : super(key: key);

  final Color actionColor;

  @override
  Widget build(BuildContext context) {
    return ActionButton(
      name: Resources.assetsImagesIcFilePng,
      color: actionColor,
      onTap: () async {
        final file = await selectFile();

        if (file.isImage) {
          if (!await _PreviewImage.push(context, file)) return;
          return Provider.of<AccountServer>(context, listen: false)
              .sendImageMessage(
            BlocProvider.of<ConversationCubit>(context).state.conversationId,
            File(file.path),
          );
        }
        Provider.of<AccountServer>(context, listen: false).sendAttachment(
          BlocProvider.of<ConversationCubit>(context).state.conversationId,
          file,
        );
      },
    );
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

class HighlightTextEditingController extends TextEditingController {
  HighlightTextEditingController({
    this.highlightTextStyle,
    this.participantsCubit,
  });

  final TextStyle highlightTextStyle;
  final ParticipantsCubit participantsCubit;

  @override
  set text(String newText) {
    super.text = newText;
  }

  @override
  TextSpan buildTextSpan({
    @required BuildContext context,
    TextStyle style,
    @required bool withComposing,
  }) {
    if (!value.isComposingRangeValid || !withComposing)
      return _buildTextSpan(text, style);

    return TextSpan(style: style, children: <TextSpan>[
      _buildTextSpan(value.composing.textBefore(value.text), style),
      _buildTextSpan(
        value.composing.textInside(value.text),
        style.merge(
          const TextStyle(decoration: TextDecoration.underline),
        ),
      ),
      _buildTextSpan(value.composing.textAfter(value.text), style),
    ]);
  }

  TextSpan _buildTextSpan(String text, TextStyle style) {
    final children = <InlineSpan>[];
    text.splitMapJoin(mentionNumberRegExp, onMatch: (match) {
      final text = match[0];
      final index = participantsCubit.state
          .indexWhere((user) => '@${user.identityNumber} ' == text);
      children.add(TextSpan(
          text: text,
          style: index > -1 ? style?.merge(highlightTextStyle) : style));
      return text;
    }, onNonMatch: (text) {
      children.add(TextSpan(text: text, style: style));
      return text;
    });
    return TextSpan(
      style: style,
      children: children,
    );
  }
}
