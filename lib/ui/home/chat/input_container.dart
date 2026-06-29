import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui show BoxHeightStyle;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' hide ChangeNotifierProvider;
import 'package:image_picker/image_picker.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:provider/provider.dart' hide Consumer;
import 'package:rxdart/rxdart.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../../ai/ai_chat_controller.dart';
import '../../../ai/model/ai_prompt_template.dart';
import '../../../ai/model/ai_provider_config.dart';
import '../../../constants/constants.dart';
import '../../../constants/icon_fonts.dart';
import '../../../constants/resources.dart';
import '../../../core/read_model/sticker_read_model.dart';
import '../../../db/mixin_database.dart' hide Offset;
import '../../../enum/encrypt_category.dart';
import '../../../utils/app_lifecycle.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/file.dart';
import '../../../utils/hook.dart';
import '../../../utils/mcp/mixin_mcp_bridge.dart';
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
import '../../../widgets/sticker_page/sticker_page.dart';
import '../../../widgets/toast.dart';
import '../../../widgets/user_selector/conversation_selector.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/mention_cache_provider.dart';
import '../../provider/mention_provider.dart';
import '../../provider/quote_message_provider.dart';
import '../../provider/recall_message_reedit_provider.dart';
import '../notifier/chat_side_notifier.dart';
import 'ai_draft_assist_panel.dart';
import 'chat_send_outcome.dart';
import 'files_preview.dart';
import 'voice_recorder_bottom_bar.dart';

part 'input_highlight_controller.dart';

class InputContainer extends HookConsumerWidget {
  const InputContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationId = ref.watch(currentConversationIdProvider);

    final hasParticipant = ref.watch(currentConversationHasParticipantProvider);

    final voiceRecorderNotifier = useMemoized(
      () => VoiceRecorderNotifier(context.audioMessageService),
      [conversationId],
    );
    useEffect(() => voiceRecorderNotifier.dispose, [voiceRecorderNotifier]);

    if (!hasParticipant) {
      return Container(
        decoration: BoxDecoration(color: context.theme.primary),
        height: 56,
        alignment: Alignment.center,
        child: Text(
          context.l10n.groupCantSend,
          style: TextStyle(color: context.theme.secondaryText),
        ),
      );
    }

    return ChangeNotifierProvider<VoiceRecorderNotifier>.value(
      value: voiceRecorderNotifier,
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
        (value) => (value?.conversationId, value?.conversation?.draft),
      ),
    );

    final quoteMessageId = ref.watch(quoteMessageIdProvider);

    final textEditingController = useMemoized(() {
      final draft = ref.read(
        conversationProvider.select((value) => value?.conversation?.draft),
      );
      return _HighlightTextEditingController(
          initialText: draft,
          highlightTextStyle: TextStyle(color: context.theme.accent),
          mentionCache: ref.read(mentionCacheProvider),
        )
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: draft?.length ?? 0),
        );
    }, [conversationId]);

    useEffect(() {
      final currentConversationId = conversationId;
      if (currentConversationId == null) return null;
      MixinMcpBridge.instance.bindInputController(
        currentConversationId,
        textEditingController,
      );
      return () => MixinMcpBridge.instance.unbindInputController(
        currentConversationId,
        textEditingController,
      );
    }, [conversationId, textEditingController]);

    final textEditingValueStream = useValueNotifierConvertSteam(
      textEditingController,
    );

    final mentionProviderInstance = mentionProvider(textEditingValueStream);
    final aiDraftAssistState = useState(AiDraftAssistViewState.idle);
    final aiDraftAssistRequestVersion = useState(0);

    Future<String> handleAiDraftRequest(
      AiDraftAction action,
      String original,
    ) async {
      final currentConversationId = conversationId;
      if (currentConversationId == null) {
        throw ToastError('Conversation unavailable');
      }

      final requestId = aiDraftAssistRequestVersion.value + 1;
      aiDraftAssistRequestVersion.value = requestId;
      aiDraftAssistState.value = AiDraftAssistViewState(
        phase: AiDraftAssistPhase.loading,
        action: action,
        original: original,
      );

      try {
        final result = await _requestAiDraftAction(
          context,
          action: action,
          conversationId: currentConversationId,
          original: original,
        );
        if (aiDraftAssistRequestVersion.value == requestId) {
          aiDraftAssistState.value = AiDraftAssistViewState(
            phase: AiDraftAssistPhase.result,
            action: action,
            original: original,
            result: result,
          );
        }
        return result;
      } catch (error) {
        if (aiDraftAssistRequestVersion.value == requestId) {
          aiDraftAssistState.value = AiDraftAssistViewState(
            phase: AiDraftAssistPhase.error,
            action: action,
            original: original,
            error: '$error',
          );
        }
        rethrow;
      }
    }

    void dismissAiDraftAssist() {
      aiDraftAssistRequestVersion.value += 1;
      aiDraftAssistState.value = AiDraftAssistViewState.idle;
    }

    useEffect(() {
      dismissAiDraftAssist();
      return null;
    }, [conversationId]);

    useEffect(() {
      final updateDraft = context.database.conversationDao.updateDraft;
      return () {
        if (conversationId == null) return;
        if (textEditingController.text == originalDraft) return;

        updateDraft(conversationId, textEditingController.text);
      };
    }, [conversationId, originalDraft]);

    final focusNode = useFocusNode(
      onKeyEvent: (_, _) => KeyEventResult.ignored,
    );

    useEffect(() {
      if (!context.textFieldAutoGainFocus) {
        focusNode.unfocus();
        return null;
      }
      focusNode.requestFocus();
    }, [conversationId, quoteMessageId]);

    useEffect(() {
      bool onListen(KeyEvent value) {
        if (!isAppActive) return false;
        if (!value.firstInputable) return false;

        final primaryFocus = FocusManager.instance.primaryFocus;
        final focusContext = primaryFocus?.context;
        if (focusContext == null) return false;
        final focusWidget = focusContext.widget;
        final isEditableText =
            focusWidget is Focus &&
            focusWidget.child is Scrollable &&
            (focusWidget.child as Scrollable).restorationId == 'editable';
        if (isEditableText) return false;

        if (ModalRoute.of(focusContext) != ModalRoute.of(context)) return false;

        if (primaryFocus == focusNode) return false;

        focusNode.requestFocus();
        return true;
      }

      HardwareKeyboard.instance.addHandler(onListen);
      return () {
        HardwareKeyboard.instance.removeHandler(onListen);
      };
    }, []);

    final chatSidePageSize = useValueListenable(
      context.read<ChatSideNotifier>(),
    ).destinations.length;
    useEffect(() {
      if (!context.textFieldAutoGainFocus) {
        // Make sure on iPad/Android Pad the text field not get focused when the chat side
        // pages all popped.
        focusNode.unfocus();
      }
    }, [chatSidePageSize]);

    return LayoutBuilder(
      builder: (context, constraints) => MentionPanelPortalEntry(
        textEditingController: textEditingController,
        mentionProviderInstance: mentionProviderInstance,
        constraints: constraints,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const _QuoteMessage(),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Container(
                decoration: BoxDecoration(color: context.theme.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!aiDraftAssistState.value.isIdle)
                      AiDraftAssistInlineCandidate(
                        viewState: aiDraftAssistState.value,
                        onDismiss: dismissAiDraftAssist,
                        onCopy: () {
                          final result = aiDraftAssistState.value.result;
                          if (result == null) return;
                          Clipboard.setData(ClipboardData(text: result));
                          showToastSuccessful(context: context);
                        },
                        onInsert: () {
                          final result = aiDraftAssistState.value.result;
                          if (result == null) return;
                          applyAiDraftAssistResult(
                            textEditingController,
                            result,
                            replace: false,
                          );
                          dismissAiDraftAssist();
                        },
                        onUseAndSend: () {
                          final result = aiDraftAssistState.value.result;
                          if (result == null) return;
                          textEditingController.value = TextEditingValue(
                            text: result,
                            selection: TextSelection.collapsed(
                              offset: result.length,
                            ),
                          );
                          dismissAiDraftAssist();
                          _sendMessage(context, textEditingController);
                        },
                        onReplace: () {
                          final result = aiDraftAssistState.value.result;
                          if (result == null) return;
                          applyAiDraftAssistResult(
                            textEditingController,
                            result,
                            replace: true,
                          );
                          dismissAiDraftAssist();
                        },
                      ),
                    Row(
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
                        if (context.database.settingProperties.aiProviders
                            .whereType<AiProviderConfig>()
                            .any((provider) => provider.enabled)) ...[
                          const SizedBox(width: 8),
                          AiDraftAssistButton(
                            enabled:
                                context
                                    .database
                                    .settingProperties
                                    .selectedAiProvider !=
                                null,
                            textEditingController: textEditingController,
                            viewState: aiDraftAssistState.value,
                            onSelected: (action) => unawaited(
                              handleAiDraftRequest(
                                action,
                                textEditingController.text.trim(),
                              ),
                            ),
                            onStop: () {
                              final currentConversationId = conversationId;
                              if (currentConversationId != null) {
                                AiChatController(
                                  context.database,
                                ).stop(currentConversationId);
                              }
                              dismissAiDraftAssist();
                            },
                          ),
                        ],
                        const SizedBox(width: 16),
                        _AnimatedSendOrVoiceButton(
                          textEditingController: textEditingController,
                          textEditingValueStream: textEditingValueStream,
                        ),
                      ],
                    ),
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

Future<String> _requestAiDraftAction(
  BuildContext context, {
  required AiDraftAction action,
  required String conversationId,
  required String original,
}) async {
  if (action != AiDraftAction.replyWithContext && original.isEmpty) {
    throw ToastError('Please type a message first');
  }

  final language = _currentLanguageTag(context);
  final templateKey = switch (action) {
    AiDraftAction.polish => AiPromptTemplateKey.draftPolish,
    AiDraftAction.shorten => AiPromptTemplateKey.draftShorten,
    AiDraftAction.polite => AiPromptTemplateKey.draftPolite,
    AiDraftAction.translate => AiPromptTemplateKey.draftTranslate,
    AiDraftAction.replyWithContext => AiPromptTemplateKey.draftReplyWithContext,
  };
  final instruction = renderAiPromptTemplate(
    context.database.settingProperties.aiPromptTemplate(templateKey),
    buildAiPromptTemplateVariables(
      conversationId: conversationId,
      input: original,
      language: language,
    ),
  );
  final title = aiDraftActionTitle(action);

  try {
    final provider = action == AiDraftAction.translate
        ? context.database.settingProperties.selectedAiTranslatorProvider
        : context.database.settingProperties.selectedAiProvider;
    final result = await AiChatController(context.database).assistText(
      instruction: instruction,
      language: language,
      input: action == AiDraftAction.replyWithContext ? null : original,
      conversationId: conversationId,
      provider: provider,
    );
    return result.trim();
  } catch (error, stackTrace) {
    e('AI draft assist failed: $title: $error, $stackTrace');
    rethrow;
  }
}

String _currentLanguageTag(BuildContext context) {
  final locale = Localizations.localeOf(context);
  final countryCode = locale.countryCode;
  if (countryCode == null || countryCode.isEmpty) return locale.languageCode;
  return '${locale.languageCode}-$countryCode';
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
    final hasInputText =
        useMemoizedStream(
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
      voiceScale = Tween<double>(
        begin: 1,
        end: 0.6,
      ).transform(animatedValue * 2.0);
    } else {
      voiceScale = 0;
      sendScale = Tween<double>(
        begin: 0.6,
        end: 1,
      ).transform((animatedValue - 0.5) * 2);
    }

    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (sendScale >= 0.6)
          Transform.scale(
            scale: sendScale,
            child: CustomContextMenuWidget(
              desktopMenuWidgetBuilder: CustomDesktopMenuWidgetBuilder(),
              menuProvider: (_) => Menu(
                children: [
                  MenuAction(
                    image: MenuImage.icon(IconFonts.mute),
                    title: context.l10n.sendWithoutSound,
                    callback: () => _sendMessage(
                      context,
                      textEditingController,
                      silent: true,
                    ),
                  ),
                ],
              ),
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
              onTap: () =>
                  context.read<VoiceRecorderNotifier>().startRecording(),
            ),
          ),
      ],
    );
  }
}

void showMaxLengthReachedToast(BuildContext context) =>
    showToastFailed(ToastError(context.l10n.contentTooLong));

void _sendPostMessage(
  BuildContext context,
  TextEditingController textEditingController,
) => _sendTextMessage(
  context,
  textEditingController,
  post: true,
);

void _sendMessage(
  BuildContext context,
  TextEditingController textEditingController, {
  bool silent = false,
}) => _sendTextMessage(
  context,
  textEditingController,
  post: false,
  silent: silent,
);

void _sendTextMessage(
  BuildContext context,
  TextEditingController textEditingController, {
  required bool post,
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

  if (post) {
    context.accountServer.sendPostMessage(
      text,
      conversationItem.encryptCategory,
      conversationId: conversationItem.conversationId,
      recipientId: conversationItem.userId,
    );
  } else {
    context.accountServer.sendTextMessage(
      text,
      conversationItem.encryptCategory,
      conversationId: conversationItem.conversationId,
      recipientId: conversationItem.userId,
      quoteMessageId: context.providerContainer.read(quoteMessageIdProvider),
      silent: silent,
    );
  }

  textEditingController.clear();
  context.completeOutgoingChatSend();
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
    final textEditingValueStream = useValueNotifierConvertSteam(
      textEditingController,
    );
    final mentionStream = ref.watch(mentionProviderInstance.notifier).stream;

    final sendable =
        useMemoizedStream(
          () => Rx.combineLatest2<TextEditingValue, MentionState, bool>(
            textEditingValueStream,
            mentionStream.startWith(ref.read(mentionProviderInstance)),
            (textEditingValue, mentionState) =>
                (textEditingValue.text.trim().isNotEmpty) &&
                (textEditingValue.composing.composed) &&
                mentionState.users.isEmpty,
          ).distinct(),
          keys: [textEditingValueStream, mentionStream],
        ).data ??
        true;

    useEffect(
      () => ref
          .read(onReEditStreamProvider)
          .listen(
            (event) =>
                textEditingController.text = textEditingController.text + event,
          )
          .cancel,
      [textEditingController],
    );

    final isEncryptConversation = ref.watch(
      conversationProvider.select(
        (value) => value?.encryptCategory.isEncrypt == true,
      ),
    );

    final hasInputText =
        useMemoizedStream(
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
            onInvoke: (intent) => _sendMessage(context, textEditingController),
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
              style: TextStyle(color: context.theme.text, fontSize: 14),
              inputFormatters: [
                LengthLimitingTextInputFormatter(kMaxTextLength),
              ],
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                isDense: true,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.only(left: 8, top: 8, bottom: 8),
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
              ),
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
    final quoting = ref.watch(
      quoteMessageProvider.select((value) => value != null),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: quoting ? 1 : 0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, progress, child) => ClipRect(
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          heightFactor: progress,
          child: child,
        ),
      ),
      child: Consumer(
        builder: (context, ref, child) {
          final message = ref.watch(lastQuoteMessageProvider);

          if (message == null) return const SizedBox();
          return DecoratedBox(
            decoration: BoxDecoration(color: context.theme.popUp),
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
        },
      ),
    );
  }
}

class _SendActionTypeButton extends HookConsumerWidget {
  const _SendActionTypeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              final conversationState = context.providerContainer.read(
                conversationProvider,
              );

              if (conversationState == null) return;

              final result = await showConversationSelector(
                context: context,
                singleSelect: true,
                onlyContact: true,
                title: context.l10n.select,
                filteredIds: [conversationState.userId].nonNulls,
              );

              if (result == null || result.isEmpty) return;
              final userId = result.first.userId;
              if (userId == null || userId.isEmpty) return;

              await runWithToast(() async {
                final user = await context.database.userDao
                    .userById(userId)
                    .getSingleOrNull();
                if (user == null) throw Exception('User not found');

                final quoteMessage = ref.read(
                  quoteMessageProvider.notifier,
                );

                await context.accountServer.sendContactMessage(
                  userId,
                  user.fullName,
                  conversationState.encryptCategory,
                  conversationId: conversationState.conversationId,
                  recipientId: conversationState.userId,
                  quoteMessageId: quoteMessage.state?.messageId,
                );
                context.completeOutgoingChatSend();
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
              title: context.l10n.picturesAndVideos,
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
                final image = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );
                if (image == null) return;
                await showFilesPreviewDialog(context, [
                  image.withMineType(),
                ]);
              },
            ),
          if (!isDesktop)
            ContextMenu(
              icon: Resources.assetsImagesVideoSvg,
              title: context.l10n.video,
              onTap: () async {
                final video = await ImagePicker().pickVideo(
                  source: ImageSource.gallery,
                );
                if (video == null) return;
                await showFilesPreviewDialog(context, [
                  video.withMineType(),
                ]);
              },
            ),
        ],
        child: _AnimatedSendTypeButton(menuDisplayed: menuDisplayed.value),
      ),
    );
  }
}

class _AnimatedSendTypeButton extends StatelessWidget {
  const _AnimatedSendTypeButton({required this.menuDisplayed});

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
            final position = renderBox.localToGlobal(
              renderBox.paintBounds.topCenter,
            );
            context.menuPosition = position;
          } else {
            context.menuPosition = details.globalPosition;
          }
        },
        color: context.theme.icon,
      ),
      builder: (context, value, child) => Transform.scale(
        scale: value.get('scale'),
        child: Transform.rotate(angle: value.get('rotate'), child: child),
      ),
    );
  }
}

class _StickerButton extends HookConsumerWidget {
  const _StickerButton({required this.textEditingController});

  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = useMemoized(GlobalKey.new);
    final stickerReadModel = useMemoized(
      () => StickerReadModel(
        stickerDao: context.database.stickerDao,
        stickerAlbumDao: context.database.stickerAlbumDao,
      ),
      [context.database],
    );

    final stickerAlbums =
        useMemoizedStream(
          stickerReadModel.systemAddedAlbums,
          initialData: const <StickerAlbum>[],
        ).data ??
        const <StickerAlbum>[];

    final presetStickerGroups = useMemoized(
      () => [
        PresetStickerGroup.store,
        PresetStickerGroup.emoji,
        PresetStickerGroup.recent,
        PresetStickerGroup.favorite,
        if (giphyApiKey.isNotEmpty) PresetStickerGroup.gif,
      ],
    );

    final tabLength = stickerAlbums.length + presetStickerGroups.length;

    return ChangeNotifierProvider.value(
      value: textEditingController,
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
                stickerAlbums: stickerAlbums,
                readModel: stickerReadModel,
                onStickerSent: context.completeOutgoingChatSend,
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
  _StickerPagePositionedLayoutDelegate({required this.position});

  final Offset position;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest);

  @override
  Offset getPositionForChild(Size size, Size childSize) => Offset(
    (position.dx - childSize.width / 2).clamp(0, size.width),
    position.dy - childSize.height,
  );

  @override
  bool shouldRelayout(
    covariant _StickerPagePositionedLayoutDelegate oldDelegate,
  ) => position != oldDelegate.position;
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
    assert(
      callingAction != null,
      '_PasteContextAction: calling action can not be null.',
    );
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
