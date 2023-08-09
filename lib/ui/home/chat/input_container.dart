import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui show BoxHeightStyle;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide StickerAlbum;
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../../../constants/constants.dart';
import '../../../constants/resources.dart';
import '../../../db/database_event_bus.dart';
import '../../../db/mixin_database.dart' hide Offset;
import '../../../enum/encrypt_category.dart';
import '../../../utils/app_lifecycle.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/file.dart';
import '../../../utils/hook.dart';
import '../../../utils/platform.dart';
import '../../../utils/reg_exp_utils.dart';
import '../../../utils/system/clipboard.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/actions/actions.dart';
import '../../../widgets/hover_overlay.dart';
import '../../../widgets/mention_panel.dart';
import '../../../widgets/menu.dart';
import '../../../widgets/message/item/quote_message.dart';
import '../../../widgets/message/item/text/mention_builder.dart';
import '../../../widgets/sticker_page/bloc/cubit/sticker_albums_cubit.dart';
import '../../../widgets/sticker_page/emoji_page.dart';
import '../../../widgets/sticker_page/sticker_page.dart';
import '../../../widgets/toast.dart';
import '../bloc/conversation_cubit.dart';
import '../bloc/mention_cubit.dart';
import '../bloc/quote_message_cubit.dart';
import '../bloc/recall_message_bloc.dart';
import '../route/responsive_navigator_cubit.dart';
import 'chat_page.dart';
import 'files_preview.dart';
import 'voice_recorder_bottom_bar.dart';

class InputContainer extends HookWidget {
  const InputContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final conversationId =
        useBlocStateConverter<ConversationCubit, ConversationState?, String?>(
      converter: (state) => state?.conversationId,
      when: (state) => state != null,
    );

    final hasParticipant =
        useBlocStateConverter<ConversationCubit, ConversationState?, bool>(
      converter: (state) {
        if (state?.conversation == null) return true;
        if (state?.conversation?.category == ConversationCategory.contact) {
          return true;
        }
        if (state?.conversation?.status == ConversationStatus.quit) {
          return false;
        }
        return state?.participant != null;
      },
    );

    useEffect(() {
      context.read<QuoteMessageCubit>().emit(null);
    }, [conversationId]);

    final voiceRecorderCubit = useBloc(
      () => VoiceRecorderCubit(context.audioMessageService),
      keys: [conversationId],
    );

    if (!hasParticipant) {
      return Container(
        decoration: BoxDecoration(
          color: context.theme.primary,
        ),
        height: 56,
        alignment: Alignment.center,
        child: Text(
          context.l10n.groupCantSend,
          style: TextStyle(
            color: context.theme.secondaryText,
          ),
        ),
      );
    }

    return BlocProvider<VoiceRecorderCubit>.value(
      value: voiceRecorderCubit,
      child: LayoutBuilder(
        builder: (context, constraints) => VoiceRecorderBarOverlayComposition(
          layoutWidth: constraints.maxWidth,
          child: const _InputContainer(),
        ),
      ),
    );
  }
}

class _InputContainer extends HookWidget {
  const _InputContainer();

  @override
  Widget build(BuildContext context) {
    final mentionCubit = useBloc(
      () => MentionCubit(
        userDao: context.database.userDao,
        multiAuthChangeNotifier: context.multiAuthChangeNotifier,
      ),
    );

    final conversationId =
        useBlocStateConverter<ConversationCubit, ConversationState?, String?>(
      converter: (state) =>
          (state?.isLoaded ?? false) ? state?.conversationId : null,
    );

    final originalDraft = useMemoized(
        () => context.read<ConversationCubit>().state?.conversation?.draft,
        [conversationId]);

    final quoteMessageId =
        useBlocStateConverter<QuoteMessageCubit, MessageItem?, String?>(
      converter: (state) => state?.messageId,
    );

    final textEditingController = useMemoized(
      () {
        final draft =
            context.read<ConversationCubit>().state?.conversation?.draft;
        return HighlightTextEditingController(
            initialText: draft,
            highlightTextStyle: TextStyle(color: context.theme.accent),
            mentionCache: context.read<MentionCache>())
          ..selection = TextSelection.fromPosition(
              TextPosition(offset: draft?.length ?? 0));
      },
      [conversationId],
    );

    final textEditingValueStream =
        useValueNotifierConvertSteam(textEditingController);

    useEffect(() {
      if (conversationId == null) return;
      mentionCubit.setTextEditingValueStream(
        textEditingValueStream,
        context.read<ConversationCubit>().state!,
      );
    }, [textEditingValueStream.hashCode, conversationId]);

    useEffect(() {
      final updateDraft = context.database.conversationDao.updateDraft;
      return () {
        if (conversationId == null) return;
        if (textEditingController.text == originalDraft) return;

        updateDraft(
          conversationId,
          textEditingController.text,
        );
      };
    }, [conversationId]);

    final focusNode = useFocusNode(onKey: (_, __) => KeyEventResult.ignored);

    useEffect(() {
      if (!context.textFieldAutoGainFocus) {
        focusNode.unfocus();
        return null;
      }
      focusNode.requestFocus();
    }, [conversationId, quoteMessageId]);

    useEffect(() {
      void onListen(RawKeyEvent value) {
        if (!isAppActive) return;
        if (!value.firstInputable) return;

        final primaryFocus = FocusManager.instance.primaryFocus;
        final focusContext = primaryFocus?.context;
        if (focusContext == null) return;
        final focusWidget = focusContext.widget;
        final isEditableText = focusWidget is Focus &&
            focusWidget.child is Scrollable &&
            (focusWidget.child as Scrollable).restorationId == 'editable';
        if (isEditableText) return;

        if (ModalRoute.of(focusContext) != ModalRoute.of(context)) return;

        if (primaryFocus == focusNode) return;

        focusNode.requestFocus();
      }

      RawKeyboard.instance.addListener(onListen);
      return () {
        RawKeyboard.instance.removeListener(onListen);
      };
    }, []);

    final chatSidePageSize =
        useBlocStateConverter<ChatSideCubit, ResponsiveNavigatorState, int>(
      bloc: context.read<ChatSideCubit>(),
      converter: (state) => state.pages.length,
    );
    useEffect(() {
      if (!context.textFieldAutoGainFocus) {
        // Make sure on iPad/Android Pad the text field not get focused when the chat side
        // pages all popped.
        focusNode.unfocus();
      }
    }, [chatSidePageSize]);

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
                    color: context.theme.primary,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _FileButton(actionColor: context.theme.icon),
                      const _ImagePickButton(),
                      const SizedBox(width: 6),
                      _StickerButton(
                        textEditingController: textEditingController,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SendTextField(
                          focusNode: focusNode,
                          textEditingController: textEditingController,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _AnimatedSendOrVoiceButton(
                        textEditingController: textEditingController,
                        textEditingValueStream: textEditingValueStream,
                      )
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

class _AnimatedSendOrVoiceButton extends HookWidget {
  const _AnimatedSendOrVoiceButton({
    required this.textEditingValueStream,
    required this.textEditingController,
  });

  final Stream<TextEditingValue> textEditingValueStream;
  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context) {
    final hasInputText = useMemoizedStream(
          () => textEditingValueStream
              .map((event) => event.text.isNotEmpty)
              .distinct(),
          keys: [textEditingValueStream],
          initialData: textEditingController.text.isNotEmpty,
        ).data ??
        false;

    // start -> show voice button
    // end -> show send button
    final animationController = useAnimationController(
      duration: Duration.zero,
      initialValue: hasInputText ? 1.0 : 0.0,
    );

    useEffect(() {
      if (hasInputText) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
    }, [hasInputText]);

    // 0 -> 0.5: scale down voice button from 1 -> 0.6
    // 0.5 -> 1: scale up voice button from 0.6 -> 1
    final animatedValue = useAnimation(animationController);

    final double sendScale;
    final double voiceScale;

    if (animatedValue < 0.5) {
      sendScale = 0;
      voiceScale =
          Tween<double>(begin: 1, end: 0.6).transform(animatedValue * 2.0);
    } else {
      voiceScale = 0;
      sendScale = Tween<double>(begin: 0.6, end: 1)
          .transform((animatedValue - 0.5) * 2);
    }

    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (sendScale >= 0.6)
          Transform.scale(
            scale: sendScale,
            child: ContextMenuPortalEntry(
              buildMenus: () => [
                ContextMenu(
                  icon: Resources.assetsImagesContextMenuMuteSvg,
                  title: context.l10n.sendWithoutSound,
                  onTap: () => _sendMessage(
                    context,
                    textEditingController,
                    silent: true,
                  ),
                ),
              ],
              child: ActionButton(
                name: Resources.assetsImagesIcSendSvg,
                color: context.theme.icon,
                onTap: () => _sendMessage(context, textEditingController),
              ),
            ),
          ),
        if (voiceScale >= 0.6)
          Transform.scale(
            scale: voiceScale,
            child: ActionButton(
              name: Resources.assetsImagesMicrophoneSvg,
              color: context.theme.icon,
              onTap: () => context.read<VoiceRecorderCubit>().startRecording(),
            ),
          ),
      ],
    );
  }
}

void showMaxLengthReachedToast(BuildContext context) =>
    showToastFailed(ToastError(context.l10n.contentTooLong));

void _sendPostMessage(
    BuildContext context, TextEditingController textEditingController) {
  final text = textEditingController.value.text.trim();
  if (text.isEmpty) return;

  final conversationItem = context.read<ConversationCubit>().state;
  if (conversationItem == null) return;
  if (text.length > kMaxTextLength) {
    showMaxLengthReachedToast(context);
    return;
  }

  context.accountServer.sendPostMessage(text, conversationItem.encryptCategory,
      conversationId: conversationItem.conversationId,
      recipientId: conversationItem.userId);

  textEditingController.text = '';
  context.read<QuoteMessageCubit>().emit(null);
}

void _sendMessage(
  BuildContext context,
  TextEditingController textEditingController, {
  bool silent = false,
}) {
  final text = textEditingController.value.text.trim();
  if (text.isEmpty) return;

  final conversationItem = context.read<ConversationCubit>().state;
  if (conversationItem == null) return;
  if (text.length > kMaxTextLength) {
    showMaxLengthReachedToast(context);
    return;
  }

  context.accountServer.sendTextMessage(
    text,
    conversationItem.encryptCategory,
    conversationId: conversationItem.conversationId,
    recipientId: conversationItem.userId,
    quoteMessageId: context.read<QuoteMessageCubit>().state?.messageId,
    silent: silent,
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

    final sendable = useMemoizedStream(
          () => Rx.combineLatest2<TextEditingValue, MentionState, bool>(
              textEditingValueStream,
              mentionStream.startWith(mentionCubit.state),
              (textEditingValue, mentionState) =>
                  (textEditingValue.text.trim().isNotEmpty) &&
                  (textEditingValue.composing.composed) &&
                  mentionState.users.isEmpty).distinct(),
          keys: [
            textEditingValueStream,
            mentionStream,
          ],
        ).data ??
        true;

    useEffect(() {
      final subscription = context
          .read<RecallMessageReeditCubit>()
          .onReeditStream
          .listen((event) {
        textEditingController.text = textEditingController.text + event;
      });
      return subscription.cancel;
    }, [textEditingController]);

    final isEncryptConversation =
        useBlocStateConverter<ConversationCubit, ConversationState?, bool>(
      bloc: context.read<ConversationCubit>(),
      converter: (state) => state?.encryptCategory.isEncrypt == true,
    );

    final hasInputText = useMemoizedStream(
          () => textEditingValueStream
              .map((event) => event.text.isNotEmpty)
              .distinct(),
          keys: [textEditingValueStream],
          initialData: textEditingController.text.isNotEmpty,
        ).data ??
        false;

    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        color: context.dynamicColor(
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
                const _SendMessageIntent(),
          SingleActivator(
            LogicalKeyboardKey.enter,
            meta: kPlatformIsDarwin,
            shift: true,
            alt: !kPlatformIsDarwin,
          ): const _SendPostMessageIntent(),
          const SingleActivator(LogicalKeyboardKey.escape):
              const EscapeIntent(),
        },
        actions: {
          _SendMessageIntent: CallbackAction<Intent>(
            onInvoke: (Intent intent) =>
                _sendMessage(context, textEditingController),
          ),
          PasteTextIntent: _PasteContextAction(context),
          _SendPostMessageIntent: CallbackAction<Intent>(
            onInvoke: (_) => _sendPostMessage(context, textEditingController),
          ),
          EscapeIntent: CallbackAction<Intent>(
            onInvoke: (_) => context.read<QuoteMessageCubit>().emit(null),
          ),
        },
        child: Stack(
          children: [
            TextField(
              maxLines: 7,
              minLines: 1,
              focusNode: focusNode,
              controller: textEditingController,
              style: TextStyle(
                color: context.theme.text,
                fontSize: 14,
              ),
              inputFormatters: [
                LengthLimitingTextInputFormatter(kMaxTextLength),
              ],
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                isDense: true,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.only(
                  left: 8,
                  top: 8,
                  bottom: 8,
                ),
              ),
              selectionHeightStyle: ui.BoxHeightStyle.includeLineSpacingMiddle,
            ),
            if (!hasInputText)
              Positioned.fill(
                left: 8,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IgnorePointer(
                    child: Text(
                      isEncryptConversation
                          ? context.l10n.chatHintE2e
                          : context.l10n.typeMessage,
                      style: TextStyle(
                        color: context.theme.secondaryText,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
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
                  color: context.theme.popUp,
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

class _ImagePickButton extends StatelessWidget {
  const _ImagePickButton();

  @override
  Widget build(BuildContext context) {
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ContextMenuPortalEntry(
        interactiveForTap: true,
        buildMenus: () => [
          ContextMenu(
            icon: Resources.assetsImagesImageSvg,
            title: context.l10n.image,
            onTap: () async {
              final file =
                  await ImagePicker().pickImage(source: ImageSource.gallery);
              if (file != null) {
                // recreate the XFile to generate mimeType.
                final xFile = File(file.path).xFile;
                await showFilesPreviewDialog(context, [xFile]);
              }
            },
          ),
          ContextMenu(
            icon: Resources.assetsImagesVideoSvg,
            title: context.l10n.video,
            onTap: () async {
              final file =
                  await ImagePicker().pickVideo(source: ImageSource.gallery);
              if (file != null) {
                // recreate the XFile to generate mimeType.
                final xFile = File(file.path).xFile;
                await showFilesPreviewDialog(context, [xFile]);
              }
            },
          ),
        ],
        child: ActionButton(
          name: Resources.assetsImagesFilePreviewImagesSvg,
          color: context.theme.icon,
          interactive: false,
        ),
      ),
    );
  }
}

class _FileButton extends StatelessWidget {
  const _FileButton({
    required this.actionColor,
  });

  final Color actionColor;

  @override
  Widget build(BuildContext context) => ActionButton(
        name: Resources.assetsImagesIcFileSvg,
        color: actionColor,
        onTap: () async {
          final files = await selectFiles();
          if (files.isEmpty) return;
          await showFilesPreviewDialog(context, files);
        },
      );
}

class _StickerButton extends HookWidget {
  const _StickerButton({
    required this.textEditingController,
  });

  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context) {
    final key = useMemoized(GlobalKey.new);

    final stickerAlbumsCubit = useBloc(
      () => StickerAlbumsCubit(
          context.database.stickerAlbumDao.systemAddedAlbums().watchWithStream(
        eventStreams: [DataBaseEventBus.instance.updateStickerStream],
        duration: kVerySlowThrottleDuration,
      )),
    );

    final presetStickerGroups = useMemoized(
      () => [
        PresetStickerGroup.store,
        if (!Platform.isLinux) PresetStickerGroup.emoji,
        PresetStickerGroup.recent,
        PresetStickerGroup.favorite,
        if (giphyApiKey.isNotEmpty) PresetStickerGroup.gif,
      ],
    );

    final tabLength =
        useBlocStateConverter<StickerAlbumsCubit, List<StickerAlbum>, int>(
      bloc: stickerAlbumsCubit,
      converter: (state) => state.length + presetStickerGroups.length,
      keys: [presetStickerGroups],
    );

    return MultiProvider(
      providers: [
        BlocProvider.value(value: stickerAlbumsCubit),
        BlocProvider(create: (context) => EmojiScrollOffsetCubit()),
        ChangeNotifierProvider.value(value: textEditingController),
      ],
      child: DefaultTabController(
        length: tabLength,
        initialIndex: 1,
        child: HoverOverlay(
          key: key,
          delayDuration: const Duration(milliseconds: 50),
          duration: const Duration(milliseconds: 200),
          closeDuration: const Duration(milliseconds: 200),
          closeWaitDuration: const Duration(milliseconds: 300),
          inCurve: Curves.easeOut,
          outCurve: Curves.easeOut,
          portalBuilder: (context, progress, _, child) {
            context.accountServer.refreshSticker();

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
            child: Builder(
              builder: (context) => StickerPage(
                tabController: DefaultTabController.of(context),
                tabLength: tabLength,
                presetStickerGroups: presetStickerGroups,
              ),
            ),
          ),
          child: ActionButton(
            name: Resources.assetsImagesIcStickerSvg,
            color: context.theme.icon,
            interactive: false,
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

class HighlightTextEditingController extends TextEditingController {
  HighlightTextEditingController({
    required this.highlightTextStyle,
    String? initialText,
    required this.mentionCache,
  }) : super(text: initialText) {
    mentionsStreamController.stream
        .map((event) => mentionNumberRegExp
            .allMatches(event)
            .map((e) => e[1])
            .whereNotNull()
            .where(
                (element) => mentionCache.identityNumberCache(element) == null)
            .toSet())
        .where((event) => event.isNotEmpty)
        .distinct(setEquals)
        .asyncMap(mentionCache.checkIdentityNumbers)
        .listen((event) => notifyListeners());
  }

  final TextStyle highlightTextStyle;
  final MentionCache mentionCache;
  final mentionsStreamController = StreamController<String>();

  @override
  Future<void> dispose() async {
    await mentionsStreamController.close();
    return super.dispose();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    mentionsStreamController.add(text);
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
        final identityNumber = match[1];

        final bool valid;
        if (identityNumber != null) {
          final user = mentionCache.identityNumberCache(identityNumber);
          valid = user != null;
        } else {
          valid = false;
        }

        children.add(TextSpan(
            text: text,
            style: valid ? style?.merge(highlightTextStyle) : style));
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

class _SendMessageIntent extends Intent {
  const _SendMessageIntent();
}

class _SendPostMessageIntent extends Intent {
  const _SendPostMessageIntent();
}

class _PasteContextAction extends Action<PasteTextIntent> {
  _PasteContextAction(this.context);

  final BuildContext context;

  @override
  Object? invoke(PasteTextIntent intent) {
    final callingAction = this.callingAction;
    assert(callingAction != null,
        '_PasteContextAction: calling action can not be null.');
    scheduleMicrotask(() async {
      final files = await getClipboardFiles();
      if (files.isNotEmpty) {
        await showFilesPreviewDialog(
          context,
          files.map((e) => e.xFile).toList(),
        );
      } else {
        // Use default paste action to paste text.
        callingAction?.invoke(intent);
      }
    });
  }
}
