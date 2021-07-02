import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../account/account_server.dart';
import '../constants/resources.dart';
import '../db/mixin_database.dart' hide Offset;
import '../generated/l10n.dart';
import '../ui/home/bloc/conversation_cubit.dart';
import '../ui/home/bloc/mention_cubit.dart';
import '../ui/home/bloc/multi_auth_cubit.dart';
import '../ui/home/bloc/participants_cubit.dart';
import '../ui/home/bloc/quote_message_cubit.dart';
import '../utils/callback_text_editing_action.dart';
import '../utils/file.dart';
import '../utils/hook.dart';
import '../utils/platform.dart';
import '../utils/reg_exp_utils.dart';
import '../utils/text_utils.dart';
import 'action_button.dart';
import 'brightness_observer.dart';
import 'dash_path_border.dart';
import 'hover_overlay.dart';
import 'interacter_decorated_box.dart';
import 'mention_panel.dart';
import 'message/item/quote_message.dart';
import 'sticker_page/bloc/cubit/sticker_albums_cubit.dart';
import 'sticker_page/sticker_page.dart';

class InputContainer extends HookWidget {
  const InputContainer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final conversationId =
        useBlocStateConverter<ConversationCubit, ConversationState?, String?>(
      converter: (state) => state?.conversationId,
      when: (state) => state != null,
    );

    useEffect(() {
      context.read<QuoteMessageCubit>().emit(null);
    }, [conversationId]);

    final hasParticipant = useStream(
            useMemoized(() {
              final database = context.read<AccountServer>().database;
              return CombineLatestStream([
                database.conversationDao
                    .conversationItem(conversationId!)
                    .watchSingleOrNull(),
                database.participantsDao
                    .findParticipantById(
                      conversationId,
                      context
                          .read<MultiAuthCubit>()
                          .state
                          .current!
                          .account
                          .userId,
                    )
                    .watchSingleOrNull(),
              ], (list) {
                if (list[0] == null) return true;
                return list[1] != null;
              }).debounceTime(const Duration(milliseconds: 500));
            }, [
              conversationId,
              context.read<MultiAuthCubit>().state.current?.account.userId,
            ]),
            initialData: true)
        .data!;

    return hasParticipant
        ? const _InputContainer()
        : Container(
            decoration: BoxDecoration(
              color: BrightnessData.themeOf(context).primary,
            ),
            height: 56,
            alignment: Alignment.center,
            child: Text(
              Localization.of(context).groupCantSendDes,
              style: TextStyle(
                color: BrightnessData.themeOf(context).secondaryText,
              ),
            ),
          );
  }
}

class _InputContainer extends HookWidget {
  const _InputContainer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mentionCubit = useBloc(
      () => MentionCubit(
        userDao: context.read<AccountServer>().database.userDao,
        multiAuthCubit: BlocProvider.of<MultiAuthCubit>(context),
        participantsCubit: BlocProvider.of<ParticipantsCubit>(context),
      ),
    );

    final conversationId =
        useBlocStateConverter<ConversationCubit, ConversationState?, String?>(
      converter: (state) =>
          (state?.isLoaded ?? false) ? state?.conversationId : null,
    );

    final draft =
        useBlocStateConverter<ConversationCubit, ConversationState?, String?>(
      converter: (state) => state?.conversation?.draft,
    );

    final conversationItem = useBlocStateConverter<ConversationCubit,
        ConversationState?, ConversationItem?>(
      converter: (state) => state?.conversation,
    );

    final textEditingController = useMemoized(
      () {
        final textEditingController = HighlightTextEditingController(
          initialText: conversationItem?.draft,
          highlightTextStyle: TextStyle(
            color: BrightnessData.themeOf(context).accent,
          ),
          participantsCubit: BlocProvider.of<ParticipantsCubit>(context),
        )..selection = TextSelection.fromPosition(
            TextPosition(
              affinity: TextAffinity.downstream,
              offset: draft?.length ?? 0,
            ),
          );
        return textEditingController;
      },
      [conversationItem?.draft, conversationId],
    );

    final textEditingValueStream =
        useValueNotifierConvertSteam(textEditingController);

    useEffect(() {
      mentionCubit.setTextEditingValueStream(
        textEditingValueStream,
        textEditingController.value,
      );
    }, [identityHashCode(textEditingValueStream)]);

    useEffect(
        () => () {
              if (conversationId == null) return;
              context
                  .read<AccountServer>()
                  .database
                  .conversationDao
                  .updateDraft(
                    conversationId,
                    textEditingController.text,
                  );
            },
        [conversationId]);

    final focusNode = useFocusNode(onKey: (_, __) => KeyEventResult.ignored);

    useEffect(() {
      focusNode.requestFocus(null);
      final subscription =
          context.read<QuoteMessageCubit>().stream.listen((event) {
        if (event == null) return;
        focusNode.requestFocus(null);
      });
      return subscription.cancel;
    }, [conversationId]);

    return MultiProvider(
      providers: [
        BlocProvider.value(
          value: mentionCubit,
        ),
      ],
      child: LayoutBuilder(
        builder: (context, BoxConstraints constraints) =>
            MentionPanelPortalEntry(
          textEditingController: textEditingController,
          constraints: constraints,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _QuoteMessage(),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 56,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: BrightnessData.themeOf(context).primary,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const _StickerButton(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SendTextField(
                          focusNode: focusNode,
                          textEditingController: textEditingController,
                        ),
                      ),
                      const SizedBox(width: 16),
                      ActionButton(
                        name: Resources.assetsImagesIcSendSvg,
                        color: BrightnessData.themeOf(context).icon,
                        onTap: () =>
                            _sendMessage(context, textEditingController),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _sendPostMessage(
    BuildContext context, TextEditingController textEditingController) {
  final text = textEditingController.value.text.trim();
  if (text.isEmpty) return;

  final conversationItem = context.read<ConversationCubit>().state;
  if (conversationItem == null) return;

  context.read<AccountServer>().sendPostMessage(
      text, conversationItem.isPlainConversation,
      conversationId: conversationItem.conversationId,
      recipientId: conversationItem.userId);

  textEditingController.text = '';
  context.read<QuoteMessageCubit>().emit(null);
}

void _sendMessage(
    BuildContext context, TextEditingController textEditingController) {
  final text = textEditingController.value.text.trim();
  if (text.isEmpty) return;

  final conversationItem = context.read<ConversationCubit>().state;
  if (conversationItem == null) return;

  context.read<AccountServer>().sendTextMessage(
        text,
        conversationItem.isPlainConversation,
        conversationId: conversationItem.conversationId,
        recipientId: conversationItem.userId,
        quoteMessageId: context.read<QuoteMessageCubit>().state?.messageId,
      );

  textEditingController.text = '';
  context.read<QuoteMessageCubit>().emit(null);
}

class _SendTextField extends HookWidget {
  const _SendTextField({
    required this.focusNode,
    required this.textEditingController,
  });

  final FocusNode focusNode;
  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context) {
    final textEditingValueStream =
        useValueNotifierConvertSteam(textEditingController);

    final mentionCubit = context.read<MentionCubit>();
    final mentionStream = mentionCubit.stream;

    final sendable = useStream(
          useMemoized(
              () => Rx.combineLatest2<TextEditingValue, MentionState, bool>(
                  textEditingValueStream.startWith(textEditingController.value),
                  mentionStream.startWith(mentionCubit.state),
                  (textEditingValue, mentionState) =>
                      (textEditingValue.text.trim().isNotEmpty) &&
                      (textEditingValue.composing.composed) &&
                      mentionState.users.isEmpty).distinct(),
              [
                textEditingValueStream,
                mentionStream,
              ]),
        ).data ??
        true;

    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        color: BrightnessData.dynamicColor(
          context,
          const Color.fromRGBO(245, 247, 250, 1),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
        ),
      ),
      alignment: Alignment.center,
      child: FocusableActionDetector(
        autofocus: true,
        shortcuts: {
          if (sendable)
            const SingleActivator(LogicalKeyboardKey.enter):
                const SendMessageIntent(),
          SingleActivator(
            LogicalKeyboardKey.enter,
            meta: kPlatformIsDarwin,
            shift: true,
            alt: !kPlatformIsDarwin,
          ): const SendPostMessageIntent(),
          SingleActivator(
            LogicalKeyboardKey.keyV,
            meta: kPlatformIsDarwin,
            control: !kPlatformIsDarwin,
          ): const PasteIntent(),
        },
        actions: {
          SendMessageIntent: CallbackAction<Intent>(
            onInvoke: (Intent intent) =>
                _sendMessage(context, textEditingController),
          ),
          PasteIntent: CallbackTextEditingAction<Intent>(
            onInvoke: (Intent intent,
                TextEditingActionTarget? textEditingActionTarget,
                [_]) async {
              final uri = await Pasteboard.uri;
              if (uri != null) {
                final file = File(uri.toFilePath(windows: Platform.isWindows));

                if (!await file.exists()) return;

                await sendFile(context, file.xFile);
              } else {
                final bytes = await Pasteboard.image;
                if (bytes == null) {
                  return textEditingActionTarget!.renderEditable
                      .pasteText(SelectionChangedCause.keyboard);
                }

                if ((await _PreviewImage.push(context, bytes: bytes)) != true) {
                  return;
                }
                final conversationItem =
                    context.read<ConversationCubit>().state;
                if (conversationItem == null) return;

                await Provider.of<AccountServer>(context, listen: false)
                    .sendImageMessage(
                  conversationItem.isPlainConversation,
                  bytes: bytes,
                  conversationId: conversationItem.conversationId,
                  recipientId: conversationItem.userId,
                );
              }
            },
          ),
          SendPostMessageIntent: CallbackAction<Intent>(
            onInvoke: (_) => _sendPostMessage(context, textEditingController),
          ),
        },
        child: AnimatedSize(
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 200),
          child: TextField(
            maxLines: 7,
            minLines: 1,
            focusNode: focusNode,
            controller: textEditingController,
            style: TextStyle(
              color: BrightnessData.themeOf(context).text,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: Localization.of(context).chatInputHint,
              hintStyle: TextStyle(
                color: BrightnessData.themeOf(context).secondaryText,
                fontSize: 14,
              ),
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.only(
                left: 8,
                top: 8,
                right: 0,
                bottom: 8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> sendFile(
  BuildContext context,
  XFile file, {
  bool showImagePreview = true,
}) async {
  final conversationItem = context.read<ConversationCubit>().state;
  if (conversationItem == null) return;
  if (file.isImage) {
    if (showImagePreview &&
        (await _PreviewImage.push(context, xFile: file)) != true) return;
    return Provider.of<AccountServer>(context, listen: false).sendImageMessage(
      conversationItem.isPlainConversation,
      file: file,
      conversationId: conversationItem.conversationId,
      recipientId: conversationItem.userId,
    );
  } else if (file.isVideo) {
    return Provider.of<AccountServer>(context, listen: false).sendVideoMessage(
      file,
      conversationItem.isPlainConversation,
      conversationId: conversationItem.conversationId,
      recipientId: conversationItem.userId,
    );
  }
  await Provider.of<AccountServer>(context, listen: false).sendDataMessage(
    file,
    conversationItem.isPlainConversation,
    conversationId: conversationItem.conversationId,
    recipientId: conversationItem.userId,
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
              alignment: AlignmentDirectional.topEnd,
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
                        quoteMessageId: message.messageId,
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

class _StickerButton extends HookWidget {
  const _StickerButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final key = useMemoized(() => GlobalKey());

    final stickerAlbumsCubit = useBloc(
      () => StickerAlbumsCubit(context
          .read<AccountServer>()
          .database
          .stickerAlbumsDao
          .systemAlbums()
          .watch()),
    );

    final tabLength =
        useBlocStateConverter<StickerAlbumsCubit, List<StickerAlbum>, int>(
      bloc: stickerAlbumsCubit,
      converter: (state) => (state.length) + 2,
    );

    return BlocProvider.value(
      value: stickerAlbumsCubit,
      child: DefaultTabController(
        length: tabLength,
        child: HoverOverlay(
          key: key,
          delayDuration: const Duration(milliseconds: 50),
          duration: const Duration(milliseconds: 200),
          closeDuration: const Duration(milliseconds: 200),
          closeWaitDuration: const Duration(milliseconds: 300),
          inCurve: Curves.easeOut,
          outCurve: Curves.easeOut,
          portalBuilder: (context, progress, child) {
            final renderBox =
                key.currentContext?.findRenderObject() as RenderBox?;
            final offset = renderBox?.localToGlobal(Offset.zero);

            if (renderBox == null || offset == null || !renderBox.hasSize) {
              return const SizedBox();
            }

            final size = renderBox.size;
            return Opacity(
              opacity: progress,
              child: CustomSingleChildLayout(
                delegate: _StickerPagePositionedLayoutDelegate(
                  position: offset + Offset(size.width / 2, 0),
                ),
                child: child,
              ),
            );
          },
          portal: Padding(
            padding: const EdgeInsets.all(8),
            child: StickerPage(
              tabController: DefaultTabController.of(context),
              tabLength: tabLength,
            ),
          ),
          child: InteractableDecoratedBox(
            child: ActionButton(
              name: Resources.assetsImagesIcStickerSvg,
              color: BrightnessData.themeOf(context).icon,
            ),
          ),
        ),
      ),
    );
  }
}

class _StickerPagePositionedLayoutDelegate extends SingleChildLayoutDelegate {
  _StickerPagePositionedLayoutDelegate({
    required this.position,
  });

  final Offset position;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest);

  @override
  Offset getPositionForChild(Size size, Size childSize) => Offset(
      (position.dx - childSize.width / 2).clamp(0, size.width),
      position.dy - childSize.height);

  @override
  bool shouldRelayout(
          covariant _StickerPagePositionedLayoutDelegate oldDelegate) =>
      position != oldDelegate.position;
}

class _PreviewImage extends HookWidget {
  const _PreviewImage({
    Key? key,
    this.xFile,
    this.bytes,
  })  : assert(!(xFile != null && bytes != null)),
        assert(!(xFile == null && bytes == null)),
        super(key: key);

  final XFile? xFile;
  final Uint8List? bytes;

  static Future<bool?> push(
    BuildContext context, {
    XFile? xFile,
    Uint8List? bytes,
  }) =>
      Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => _PreviewImage(
            xFile: xFile,
            bytes: bytes,
          ),
          fullscreenDialog: true,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final conversationId =
        useBlocStateConverter<ConversationCubit, ConversationState?, String?>(
      converter: (state) => state?.conversationId,
      when: (conversationId) => conversationId != null,
    );

    useValueChanged<String?, void>(conversationId, (_, __) {
      Navigator.pop(context, false);
    });

    final image =
        xFile != null ? Image.file(File(xFile!.path)) : Image.memory(bytes!);

    return DecoratedBox(
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
                child: image,
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
}

class HighlightTextEditingController extends TextEditingController {
  HighlightTextEditingController({
    required this.highlightTextStyle,
    required this.participantsCubit,
    String? initialText,
  }) : super(text: initialText);

  final TextStyle highlightTextStyle;
  final ParticipantsCubit participantsCubit;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (!value.isComposingRangeValid || !withComposing) {
      return _buildTextSpan(text, style);
    }

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
        final index = participantsCubit.state
            .indexWhere((user) => user.identityNumber == match[1]);
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

class SendPostMessageIntent extends Intent {
  const SendPostMessageIntent();
}

class PasteIntent extends Intent {
  const PasteIntent();
}
