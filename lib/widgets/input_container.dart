import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/mention_cubit.dart';
import 'package:flutter_app/ui/home/bloc/multi_auth_cubit.dart';
import 'package:flutter_app/ui/home/bloc/participants_cubit.dart';
import 'package:flutter_app/ui/home/bloc/quote_message_cubit.dart';
import 'package:flutter_app/utils/file.dart';
import 'package:flutter_app/utils/reg_exp_utils.dart';
import 'package:flutter_app/utils/text_utils.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/hoer_overlay.dart';
import 'package:flutter_app/widgets/sticker_page/bloc/cubit/sticker_albums_cubit.dart';
import 'package:flutter_app/widgets/sticker_page/sticker_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset;

import 'action_button.dart';
import 'dash_path_border.dart';
import 'interacter_decorated_box.dart';
import 'mention_panel.dart';
import 'message/item/quote_message.dart';

class InputContainer extends StatelessWidget {
  const InputContainer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => MentionCubit(
          userDao: context.read<AccountServer>().database.userDao,
          multiAuthCubit: BlocProvider.of<MultiAuthCubit>(context),
          participantsCubit: BlocProvider.of<ParticipantsCubit>(context),
        ),
        child: Builder(
          builder: (context) => ChangeNotifierProvider<TextEditingController>(
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
                BlocProvider.of<MentionCubit>(context).send(mention);
              });
              return textEditingController;
            },
            child: LayoutBuilder(
              builder: (context, BoxConstraints constraints) =>
                  MentionPanelPortalEntry(
                constraints: constraints,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _QuoteMessage(),
                    SizedBox(
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
                                  child: const _SendTextField(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ActionButton(
                                name: Resources.assetsImagesIcSendSvg,
                                color: BrightnessData.themeOf(context).icon,
                                onTap: () => _sendMessage(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

void _sendMessage(BuildContext context) {
  final textEditingController = context.read<TextEditingController>();
  final text = textEditingController.value.text;
  if (text.trim().isEmpty) return;

  textEditingController.text = '';
  final conversationItem = BlocProvider.of<ConversationCubit>(context).state;
  if (conversationItem == null) return;

  context.read<AccountServer>().sendTextMessage(
        conversationItem.conversationId,
        text,
        quoteMessageId: context.read<QuoteMessageCubit>().state?.messageId,
      );

  context.read<QuoteMessageCubit>().emit(null);
}

class _SendTextField extends StatelessWidget {
  const _SendTextField();

  @override
  Widget build(BuildContext context) =>
      Selector2<TextEditingController, MentionCubit, bool>(
        selector: (context, TextEditingController controller,
                MentionCubit mentionCubit) =>
            controller.text.trim().isNotEmpty == true &&
            controller.value.composing.composed &&
            (mentionCubit.state.text?.isNotEmpty ?? true),
        builder: (context, sendable, child) => FocusableActionDetector(
          shortcuts: {
            if (sendable)
              LogicalKeySet(LogicalKeyboardKey.enter):
                  const SendMessageIntent(),
          },
          actions: {
            SendMessageIntent: CallbackAction<Intent>(
              onInvoke: (Intent intent) => _sendMessage(context),
            ),
          },
          child: TextField(
            maxLines: 5,
            minLines: 1,
            controller: context.read<TextEditingController>(),
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
      );
}

class _QuoteMessage extends StatelessWidget {
  const _QuoteMessage();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<QuoteMessageCubit, MessageItem?>(
        builder: (context, message) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: message != null ? 1 : 0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          builder: (BuildContext context, double progress, Widget? child) =>
              ClipRect(
            child: Align(
              alignment: const AlignmentDirectional(1.0, -1.0),
              heightFactor: progress,
              child: child,
            ),
          ),
          child: BlocBuilder<QuoteMessageCubit, MessageItem?>(
            buildWhen: (a, b) => b != null,
            builder: (context, message) {
              if (message == null) return const SizedBox();
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: BrightnessData.themeOf(context).popUp,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: QuoteMessage(
                        id: message.messageId,
                        message: message,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.read<QuoteMessageCubit>().emit(null),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        child: SvgPicture.asset(
                          Resources.assetsImagesCloseOvalSvg,
                          height: 22,
                          width: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
}

class _StickerButton extends StatelessWidget {
  const _StickerButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => StickerAlbumsCubit(context
            .read<AccountServer>()
            .database
            .stickerAlbumsDao
            .systemAlbums()
            .watch()),
        child: Builder(
          builder: (context) =>
              BlocConverter<StickerAlbumsCubit, List<StickerAlbum>, int>(
            converter: (state) => (state.length) + 2,
            builder: (context, tabLength) => DefaultTabController(
              length: tabLength,
              child: Builder(
                builder: (context) => HoverOverlay(
                  duration: const Duration(milliseconds: 200),
                  closeDuration: const Duration(milliseconds: 200),
                  closeWaitDuration: const Duration(milliseconds: 300),
                  inCurve: Curves.easeOut,
                  outCurve: Curves.easeOut,
                  portalBuilder: (context, progress, child) => Opacity(
                    opacity: progress,
                    child: child,
                  ),
                  child: InteractableDecoratedBox(
                    child: ActionButton(
                      name: Resources.assetsImagesIcStickerSvg,
                      color: BrightnessData.themeOf(context).icon,
                    ),
                  ),
                  childAnchor: Alignment.topCenter,
                  portalAnchor: Alignment.bottomCenter,
                  portal: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: StickerPage(
                      stickerAlbumsCubit:
                          BlocProvider.of<StickerAlbumsCubit>(context),
                      tabController: DefaultTabController.of(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _FileButton extends StatelessWidget {
  const _FileButton({
    Key? key,
    required this.actionColor,
  }) : super(key: key);

  final Color actionColor;

  @override
  Widget build(BuildContext context) {
    return ActionButton(
      name: Resources.assetsImagesIcFileSvg,
      color: actionColor,
      onTap: () async {
        final file = await selectFile();
        if (file == null) return;

        final conversationItem =
            BlocProvider.of<ConversationCubit>(context).state;
        if (conversationItem == null) return;
        if (file.isImage) {
          if ((await _PreviewImage.push(context, file)) != true) return;
          return await Provider.of<AccountServer>(context, listen: false)
              .sendImageMessage(
            conversationItem.conversationId,
            file,
          );
        } else if (file.isVideo) {
          return Provider.of<AccountServer>(context, listen: false)
              .sendVideoMessage(
            conversationItem.conversationId,
            file,
          );
        }
        await Provider.of<AccountServer>(context, listen: false)
            .sendDataMessage(
          conversationItem.conversationId,
          file,
        );
      },
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({
    Key? key,
    required this.xFile,
  }) : super(key: key);

  final XFile xFile;

  static Future<bool?> push(BuildContext context, XFile xFile) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => _PreviewImage(xFile: xFile),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocConverter<ConversationCubit, ConversationItem?, String?>(
        converter: (state) => state?.conversationId,
        when: (a, b) => a != b,
        listener: (context, switched) => Navigator.pop(context, false),
        child: DecoratedBox(
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
                      name: Resources.assetsImagesIcCloseSvg,
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
        ),
      );
}

class HighlightTextEditingController extends TextEditingController {
  HighlightTextEditingController({
    required this.highlightTextStyle,
    required this.participantsCubit,
  });

  final TextStyle highlightTextStyle;
  final ParticipantsCubit participantsCubit;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (!value.isComposingRangeValid || !withComposing)
      return _buildTextSpan(text, style);

    return TextSpan(style: style, children: <TextSpan>[
      _buildTextSpan(value.composing.textBefore(value.text), style),
      _buildTextSpan(
        value.composing.textInside(value.text),
        style?.merge(
          const TextStyle(decoration: TextDecoration.underline),
        ),
      ),
      _buildTextSpan(value.composing.textAfter(value.text), style),
    ]);
  }

  TextSpan _buildTextSpan(String text, TextStyle? style) {
    final children = <InlineSpan>[];
    text.splitMapJoin(
      mentionNumberRegExp,
      onMatch: (match) {
        final text = match[0];
        final index = participantsCubit.state.indexWhere(
            (user) => '@${user.identityNumber}' == text?.trimRight());
        children.add(TextSpan(
            text: text,
            style: index > -1 ? style?.merge(highlightTextStyle) : style));
        return text ?? '';
      },
      onNonMatch: (text) {
        children.add(TextSpan(text: text, style: style));
        return text;
      },
    );
    return TextSpan(
      style: style,
      children: children,
    );
  }
}

class SendMessageIntent extends Intent {
  const SendMessageIntent();
}
