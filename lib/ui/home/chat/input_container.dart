import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui show BoxHeightStyle;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' hide ChangeNotifierProvider;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart' hide Consumer;
import 'package:rxdart/rxdart.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../../constants/constants.dart';
import '../../../constants/icon_fonts.dart';
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
import '../../../widgets/high_light_text.dart';
import '../../../widgets/hover_overlay.dart';
import '../../../widgets/mention_panel.dart';
import '../../../widgets/menu.dart';
import '../../../widgets/message/item/quote_message.dart';
import '../../../widgets/sticker_page/bloc/cubit/sticker_albums_cubit.dart';
import '../../../widgets/sticker_page/sticker_page.dart';
import '../../../widgets/toast.dart';
import '../../../widgets/user_selector/conversation_selector.dart';
import '../../provider/abstract_responsive_navigator.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/mention_cache_provider.dart';
import '../../provider/mention_provider.dart';
import '../../provider/quote_message_provider.dart';
import '../../provider/recall_message_reedit_provider.dart';
import 'chat_page.dart';
import 'files_preview.dart';
import 'voice_recorder_bottom_bar.dart';

class InputContainer extends HookConsumerWidget {
  const InputContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationId = ref.watch(currentConversationIdProvider);

    final hasParticipant = ref.watch(currentConversationHasParticipantProvider);

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

class _InputContainer extends HookConsumerWidget {
  const _InputContainer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (conversationId, originalDraft) = ref.watch(
      conversationProvider.select(
          (value) => (value?.conversationId, value?.conversation?.draft)),
    );

    final quoteMessageId = ref.watch(quoteMessageIdProvider);

    final textEditingController = useMemoized(
      () {
        final draft = ref.read(
            conversationProvider.select((value) => value?.conversation?.draft));
        return _HighlightTextEditingController(
          initialText: draft,
          highlightTextStyle: TextStyle(color: context.theme.accent),
          mentionCache: ref.read(mentionCacheProvider),
        )..selection = TextSelection.fromPosition(
            TextPosition(offset: draft?.length ?? 0));
      },
      [conversationId],
    );

    final textEditingValueStream =
        useValueNotifierConvertSteam(textEditingController);

    final mentionProviderInstance = mentionProvider(textEditingValueStream);

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
    }, [conversationId, originalDraft]);

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

    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) => MentionPanelPortalEntry(
        textEditingController: textEditingController,
        mentionProviderInstance: mentionProviderInstance,
        constraints: constraints,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
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
                    const _SendActionTypeButton(),
                    const SizedBox(width: 6),
                    _StickerButton(
                      textEditingController: textEditingController,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SendTextField(
                        focusNode: focusNode,
                        textEditingController: textEditingController,
                        mentionProviderInstance: mentionProviderInstance,
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
    );
  }
}

class _AnimatedSendOrVoiceButton extends HookConsumerWidget {
  const _AnimatedSendOrVoiceButton({
    required this.textEditingValueStream,
    required this.textEditingController,
  });

  final Stream<TextEditingValue> textEditingValueStream;
  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            child: ContextMenuWidget(
              menuProvider: (_) => Menu(children: [
                MenuAction(
                  image: MenuImage.icon(IconFonts.mute),
                  title: context.l10n.sendWithoutSound,
                  callback: () => _sendMessage(
                    context,
                    textEditingController,
                    silent: true,
                  ),
                ),
              ]),
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

  final conversationItem = context.providerContainer.read(conversationProvider);
  if (conversationItem == null) return;
  if (text.length > kMaxTextLength) {
    showMaxLengthReachedToast(context);
    return;
  }

  context.accountServer.sendPostMessage(text, conversationItem.encryptCategory,
      conversationId: conversationItem.conversationId,
      recipientId: conversationItem.userId);

  textEditingController.text = '';
  context.providerContainer.read(quoteMessageProvider.notifier).state = null;
}

void _sendMessage(
  BuildContext context,
  TextEditingController textEditingController, {
  bool silent = false,
}) {
  final text = textEditingController.value.text.trim();
  if (text.isEmpty) return;

  final conversationItem = context.providerContainer.read(conversationProvider);
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
    quoteMessageId: context.providerContainer.read(quoteMessageIdProvider),
    silent: silent,
  );

  textEditingController.text = '';
  context.providerContainer.read(quoteMessageProvider.notifier).state = null;
}

class _SendTextField extends HookConsumerWidget {
  const _SendTextField({
    required this.focusNode,
    required this.textEditingController,
    required this.mentionProviderInstance,
  });

  final FocusNode focusNode;
  final TextEditingController textEditingController;
  final AutoDisposeStateNotifierProvider<MentionStateNotifier, MentionState>
      mentionProviderInstance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textEditingValueStream =
        useValueNotifierConvertSteam(textEditingController);
    final mentionStream = ref.watch(mentionProviderInstance.notifier).stream;

    final sendable = useMemoizedStream(
          () => Rx.combineLatest2<TextEditingValue, MentionState, bool>(
              textEditingValueStream,
              mentionStream.startWith(ref.read(mentionProviderInstance)),
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

    useEffect(
        () => ref
            .read(onReEditStreamProvider)
            .listen((event) =>
                textEditingController.text = textEditingController.text + event)
            .cancel,
        [textEditingController]);

    final isEncryptConversation = ref.watch(conversationProvider
        .select((value) => value?.encryptCategory.isEncrypt == true));

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
            onInvoke: (_) =>
                ref.read(quoteMessageProvider.notifier).state = null,
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
              contextMenuBuilder: (context, state) =>
                  MixinAdaptiveSelectionToolbar(editableTextState: state),
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

class _QuoteMessage extends HookConsumerWidget {
  const _QuoteMessage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoting =
        ref.watch(quoteMessageProvider.select((value) => value != null));

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: quoting ? 1 : 0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (BuildContext context, double progress, Widget? child) =>
          ClipRect(
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          heightFactor: progress,
          child: child,
        ),
      ),
      child: Consumer(builder: (context, ref, child) {
        final message = ref.watch(lastQuoteMessageProvider);

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
                onTap: () =>
                    ref.read(quoteMessageProvider.notifier).state = null,
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
      }),
    );
  }
}

class _SendActionTypeButton extends HookWidget {
  const _SendActionTypeButton();

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        Platform.isMacOS || Platform.isLinux || Platform.isWindows;

    final menuDisplayed = useState(false);

    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ContextMenuPortalEntry(
        interactive: false,
        showedMenu: (value) => Future(() {
          menuDisplayed.value = value;
        }),
        buildMenus: () => [
          ContextMenu(
            icon: Resources.assetsImagesContactSvg,
            title: context.l10n.contact,
            onTap: () async {
              final conversationState =
                  context.providerContainer.read(conversationProvider);

              if (conversationState == null) return;

              final result = await showConversationSelector(
                context: context,
                singleSelect: true,
                onlyContact: true,
                title: context.l10n.select,
                filteredIds: [conversationState.userId].whereNotNull(),
              );

              if (result == null || result.isEmpty) return;
              final userId = result.first.userId;
              if (userId == null || userId.isEmpty) return;

              await runWithToast(() async {
                final user = await context.database.userDao
                    .userById(userId)
                    .getSingleOrNull();
                if (user == null) throw Exception('User not found');

                await context.accountServer.sendContactMessage(
                  userId,
                  user.fullName,
                  conversationState.encryptCategory,
                  conversationId: conversationState.conversationId,
                  recipientId: conversationState.userId,
                );
              });
            },
          ),
          ContextMenu(
            icon: Resources.assetsImagesFileSvg,
            title: context.l10n.files,
            onTap: () async {
              final files = await selectFiles();
              if (files.isNotEmpty) {
                await showFilesPreviewDialog(context, files);
              }
            },
          ),
          if (isDesktop)
            ContextMenu(
              icon: Resources.assetsImagesFilePreviewImagesSvg,
              title: '${context.l10n.image} & ${context.l10n.video}',
              onTap: () async {
                final files = await selectFiles();
                if (files.isNotEmpty) {
                  await showFilesPreviewDialog(context, files);
                }
              },
            ),
          if (!isDesktop)
            ContextMenu(
              icon: Resources.assetsImagesImageSvg,
              title: context.l10n.image,
              onTap: () async {
                final image =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                if (image == null) return;
                await showFilesPreviewDialog(context, [image.withMineType()]);
              },
            ),
          if (!isDesktop)
            ContextMenu(
              icon: Resources.assetsImagesVideoSvg,
              title: context.l10n.video,
              onTap: () async {
                final video =
                    await ImagePicker().pickVideo(source: ImageSource.gallery);
                if (video == null) return;
                await showFilesPreviewDialog(context, [video.withMineType()]);
              },
            ),
        ],
        child: _AnimatedSendTypeButton(menuDisplayed: menuDisplayed.value),
      ),
    );
  }
}

class _AnimatedSendTypeButton extends StatelessWidget {
  const _AnimatedSendTypeButton({
    required this.menuDisplayed,
  });

  final bool menuDisplayed;

  @override
  Widget build(BuildContext context) {
    final tween = MovieTween()
      ..scene(
        duration: 200.milliseconds,
        curve: Curves.easeInOut,
      ).tween('rotate', Tween<double>(begin: 0, end: math.pi / 4))
      ..scene(
        duration: 100.milliseconds,
        curve: Curves.easeIn,
        end: 100.milliseconds,
      ).tween('scale', Tween<double>(begin: 1, end: 0.8))
      ..scene(
        duration: 100.milliseconds,
        curve: Curves.easeOut,
        begin: 100.milliseconds,
      ).tween('scale', Tween<double>(begin: 0.8, end: 1));
    return CustomAnimationBuilder(
      duration: 200.milliseconds,
      tween: tween,
      control: menuDisplayed ? Control.play : Control.playReverse,
      curve: Curves.easeInOut,
      child: ActionButton(
        name: Resources.assetsImagesIcAddSvg,
        size: 32,
        padding: const EdgeInsets.all(4),
        onTapUp: (details) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final position =
                renderBox.localToGlobal(renderBox.paintBounds.topCenter);
            context.sendMenuPosition(position);
          } else {
            context.sendMenuPosition(details.globalPosition);
          }
        },
        color: context.theme.icon,
      ),
      builder: (context, value, child) => Transform.scale(
        scale: value.get('scale'),
        child: Transform.rotate(
          angle: value.get('rotate'),
          child: child,
        ),
      ),
    );
  }
}

class _StickerButton extends HookConsumerWidget {
  const _StickerButton({
    required this.textEditingController,
  });

  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        PresetStickerGroup.emoji,
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

class MentionTextMatcher extends TextMatcher implements EquatableMixin {
  MentionTextMatcher(this.mentionCache, this.highlightTextStyle)
      : super.regExp(
          regExp: mentionNumberRegExp,
          matchBuilder: (
            span,
            displayString,
            linkString,
          ) {
            if (displayString != linkString) return TextSpan(text: linkString);

            final identityNumber = linkString.substring(1);
            final user = mentionCache.identityNumberCache(identityNumber);
            final valid = user != null;

            if (displayString != linkString) return TextSpan(text: linkString);

            return TextSpan(
              text: displayString,
              style: valid
                  ? (span.style ?? const TextStyle()).merge(highlightTextStyle)
                  : span.style,
            );
          },
        );

  final MentionCache mentionCache;
  final TextStyle highlightTextStyle;

  @override
  List<Object?> get props => [mentionCache, highlightTextStyle];

  @override
  bool? get stringify => true;
}

class _HighlightTextEditingController extends TextEditingController {
  _HighlightTextEditingController({
    required this.highlightTextStyle,
    String? initialText,
    required this.mentionCache,
  }) : super(text: initialText) {
    mentionsStreamController.stream
        .distinct()
        .asyncBufferMap(
            (event) => mentionCache.checkMentionCache(event.toSet()))
        .distinct(mapEquals)
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

  TextSpan _buildTextSpan(String text, TextStyle? style) => TextSpan(
        style: style,
        children: TextMatcher.applyTextMatchers([
          TextSpan(text: text, style: style)
        ], [
          MentionTextMatcher(mentionCache, highlightTextStyle),
          EmojiTextMatcher(),
        ]).toList(),
      );
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
