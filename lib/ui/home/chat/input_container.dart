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
import 'package:mixin_logger/mixin_logger.dart';
import 'package:provider/provider.dart' hide Consumer;
import 'package:rxdart/rxdart.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../../ai/ai_chat_controller.dart';
import '../../../ai/ai_thread_target.dart';
import '../../../ai/model/ai_prompt_template.dart';
import '../../../ai/model/ai_provider_config.dart';
import '../../../constants/constants.dart';
import '../../../constants/icon_fonts.dart';
import '../../../constants/resources.dart';
import '../../../db/ai_database.dart';
import '../../../db/database_event_bus.dart';
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
import '../../../widgets/ai/ai_context_attachment_bar.dart';
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
import '../../provider/ai_assistant_thread_provider.dart';
import '../../provider/ai_context_attachment_provider.dart';
import '../../provider/ai_input_mode_provider.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/mention_cache_provider.dart';
import '../../provider/mention_provider.dart';
import '../../provider/quote_message_provider.dart';
import '../../provider/recall_message_reedit_provider.dart';
import '../bloc/blink_cubit.dart';
import '../bloc/message_bloc.dart';
import 'ai_draft_assist_panel.dart';
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
        decoration: BoxDecoration(color: context.theme.primary),
        height: 56,
        alignment: Alignment.center,
        child: Text(
          context.l10n.groupCantSend,
          style: TextStyle(color: context.theme.secondaryText),
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
        (value) => (value?.conversationId, value?.conversation?.draft),
      ),
    );
    final aiModeState = ref.watch(aiInputModeProvider(conversationId ?? ''));
    final selectedAiProvider =
        context.database.settingProperties.selectedAiProvider;
    final enabledAiProviders = context.database.settingProperties.aiProviders
        .whereType<AiProviderConfig>()
        .where((element) => element.enabled)
        .toList();
    final aiProvider = _resolveAiModeProvider(
      selectedAiProvider: selectedAiProvider,
      enabledAiProviders: enabledAiProviders,
      providerId: aiModeState.providerId,
      selectedModel: aiModeState.model,
    );
    final aiModeEnabled = aiModeState.enabled;
    final attachedMessages = conversationId == null
        ? const <MessageItem>[]
        : ref.watch(aiContextAttachmentProvider(conversationId));
    final attachedMessagesNotifier = conversationId == null
        ? null
        : ref.read(aiContextAttachmentProvider(conversationId).notifier);
    final aiThreadSelection = conversationId == null
        ? const AiAssistantThreadSelection.latest()
        : ref.watch(aiAssistantThreadSelectionProvider(conversationId));
    final aiThreads =
        useMemoizedStream(
          () => conversationId == null
              ? Stream.value(const <AiChatThread>[])
              : context.database.aiChatMessageDao.watchThreads(
                  conversationId,
                ),
          keys: [conversationId],
          initialData: const <AiChatThread>[],
        ).data ??
        const <AiChatThread>[];
    final createNewAiThread =
        aiThreadSelection.isNewThread || aiThreads.isEmpty;
    final selectedAiThread = createNewAiThread
        ? null
        : aiThreadSelection.isLatest
        ? aiThreads.firstOrNull
        : aiThreads.firstWhereOrNull(
            (item) => item.id == aiThreadSelection.threadId,
          );
    final currentAiThread = createNewAiThread ? null : selectedAiThread;
    final aiMessages =
        useMemoizedStream(
          () => currentAiThread == null
              ? Stream.value(const <AiChatMessage>[])
              : context.database.aiChatMessageDao.watchThreadMessages(
                  currentAiThread.id,
                ),
          keys: [currentAiThread?.id],
          initialData: const <AiChatMessage>[],
        ).data ??
        const <AiChatMessage>[];
    final aiRequestInFlight = aiMessages.any(isActivePendingAiMessage);

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
      if (conversationId == null) return null;
      unawaited(
        context.database.aiChatMessageDao.resolveStalePendingAssistantMessages(
          updatedBefore: kAiRuntimeStartedAt,
          conversationId: conversationId,
        ),
      );
      return null;
    }, [conversationId]);

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
              constraints: BoxConstraints(minHeight: aiModeEnabled ? 92 : 56),
              child: Container(
                decoration: BoxDecoration(color: context.theme.primary),
                padding: EdgeInsets.fromLTRB(16, aiModeEnabled ? 8 : 8, 16, 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.zero,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (conversationId != null && aiModeEnabled) ...[
                        _AiModeBar(
                          conversationId: conversationId,
                          provider: aiProvider,
                        ),
                        const SizedBox(height: 8),
                        AiContextAttachmentBar(
                          messages: attachedMessages,
                          onTap: (message) =>
                              _jumpToAttachedMessage(context, message),
                          onRemove: (messageId) =>
                              attachedMessagesNotifier?.remove(messageId),
                        ),
                        if (attachedMessages.isNotEmpty)
                          const SizedBox(height: 8),
                      ],
                      if (!aiModeEnabled &&
                          !aiDraftAssistState.value.isIdle) ...[
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
                            if (result == null || conversationId == null) {
                              return;
                            }
                            textEditingController.value = TextEditingValue(
                              text: result,
                              selection: TextSelection.collapsed(
                                offset: result.length,
                              ),
                            );
                            dismissAiDraftAssist();
                            unawaited(
                              _sendMessage(
                                context,
                                textEditingController,
                                conversationId: conversationId,
                                createNewAiThread: createNewAiThread,
                              ),
                            );
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
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (aiModeEnabled) ...[
                            _AiModeBadge(color: context.theme.accent),
                            const SizedBox(width: 16),
                          ] else ...[
                            const _SendActionTypeButton(),
                            const SizedBox(width: 6),
                            _StickerButton(
                              textEditingController: textEditingController,
                            ),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            child: _SendTextField(
                              focusNode: focusNode,
                              textEditingController: textEditingController,
                              mentionProviderInstance: mentionProviderInstance,
                              aiModeEnabled: aiModeEnabled,
                              providerName: aiProvider?.name,
                              modelName: aiProvider?.model,
                              aiThreadId: currentAiThread?.id,
                              createNewAiThread: createNewAiThread,
                              aiRequestInFlight: aiRequestInFlight,
                              aiDraftAssistState: aiDraftAssistState.value,
                            ),
                          ),
                          if (!aiModeEnabled &&
                              enabledAiProviders.isNotEmpty) ...[
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
                          SizedBox(width: aiModeEnabled ? 10 : 8),
                          _AnimatedSendOrVoiceButton(
                            conversationId: conversationId,
                            textEditingController: textEditingController,
                            textEditingValueStream: textEditingValueStream,
                            aiModeEnabled: aiModeEnabled,
                            aiRequestInFlight: aiRequestInFlight,
                            aiThreadId: currentAiThread?.id,
                            createNewAiThread: createNewAiThread,
                          ),
                        ],
                      ),
                    ],
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

class _AnimatedSendOrVoiceButton extends HookConsumerWidget {
  const _AnimatedSendOrVoiceButton({
    required this.conversationId,
    required this.aiThreadId,
    required this.createNewAiThread,
    required this.textEditingValueStream,
    required this.textEditingController,
    required this.aiModeEnabled,
    required this.aiRequestInFlight,
  });

  final String? conversationId;
  final String? aiThreadId;
  final bool createNewAiThread;
  final Stream<TextEditingValue> textEditingValueStream;
  final TextEditingController textEditingController;
  final bool aiModeEnabled;
  final bool aiRequestInFlight;

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

    if (aiModeEnabled && aiRequestInFlight) {
      return ActionButton(
        name: Resources.assetsImagesRecordStopSvg,
        color: context.theme.accent,
        onTap: () {
          final currentConversationId = conversationId;
          if (currentConversationId == null) return;
          AiChatController(
            context.database,
          ).stop(currentConversationId, threadId: aiThreadId);
        },
      );
    }

    if (aiModeEnabled) {
      final canSend = hasInputText;

      return AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: canSend ? 1 : 0.45,
        child: IgnorePointer(
          ignoring: !canSend,
          child: ActionButton(
            name: Resources.assetsImagesIcSendSvg,
            color: context.theme.accent,
            onTap: () => unawaited(
              _sendMessage(
                context,
                textEditingController,
                conversationId: conversationId,
                aiThreadId: aiThreadId,
                createNewAiThread: createNewAiThread,
              ),
            ),
          ),
        ),
      );
    }

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
                    callback: () => unawaited(
                      _sendMessage(
                        context,
                        textEditingController,
                        conversationId: conversationId,
                        silent: true,
                      ),
                    ),
                  ),
                ],
              ),
              child: ActionButton(
                name: Resources.assetsImagesIcSendSvg,
                color: context.theme.icon,
                onTap: () => unawaited(
                  _sendMessage(
                    context,
                    textEditingController,
                    conversationId: conversationId,
                  ),
                ),
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
  final title = switch (action) {
    AiDraftAction.polish => 'Polish',
    AiDraftAction.shorten => 'Make shorter',
    AiDraftAction.polite => 'Make polite',
    AiDraftAction.translate => 'Translate draft',
    AiDraftAction.replyWithContext => 'Reply with context',
  };

  try {
    final controller = AiChatController(context.database);
    final provider = action == AiDraftAction.translate
        ? context.database.settingProperties.selectedAiTranslatorProvider
        : context.database.settingProperties.selectedAiProvider;
    final result = await controller.assistText(
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

void _jumpToAttachedMessage(BuildContext context, MessageItem message) {
  context.read<MessageBloc>().scrollTo(message.messageId);
  context.read<BlinkCubit>().blinkByMessageId(message.messageId);
}

void showMaxLengthReachedToast(BuildContext context) =>
    showToastFailed(ToastError(context.l10n.contentTooLong));

void _sendPostMessage(
  BuildContext context,
  TextEditingController textEditingController,
) {
  final text = textEditingController.value.text.trim();
  if (text.isEmpty) return;

  final conversationItem = context.providerContainer.read(conversationProvider);
  if (conversationItem == null) return;
  if (text.length > kMaxTextLength) {
    showMaxLengthReachedToast(context);
    return;
  }

  context.accountServer.sendPostMessage(
    text,
    conversationItem.encryptCategory,
    conversationId: conversationItem.conversationId,
    recipientId: conversationItem.userId,
  );

  textEditingController.text = '';
  context.providerContainer.read(quoteMessageProvider.notifier).state = null;
}

Future<void> _sendMessage(
  BuildContext context,
  TextEditingController textEditingController, {
  required String? conversationId,
  String? aiThreadId,
  bool createNewAiThread = false,
  bool silent = false,
}) async {
  final text = textEditingController.value.text.trim();
  if (text.isEmpty) return;
  if (conversationId == null) return;

  final conversationItem = context.providerContainer.read(conversationProvider);
  if (conversationItem == null) return;
  if (text.length > kMaxTextLength) {
    showMaxLengthReachedToast(context);
    return;
  }

  if (text == '/ai') {
    final provider = context.database.settingProperties.selectedAiProvider;
    if (provider == null || provider.model.trim().isEmpty) {
      showToastFailed(ToastError('Please add an AI provider first'));
      return;
    }
    unawaited(
      context.read<ChatSideCubit>().replace(ChatSideCubit.aiAssistantPage),
    );
    textEditingController.text = '';
    return;
  }

  final inlineAiInput = text.startsWith('/ai ')
      ? text.substring(4).trim()
      : null;
  final attachedMessages = context.providerContainer.read(
    aiContextAttachmentProvider(conversationId),
  );
  final attachedMessagesNotifier = context.providerContainer.read(
    aiContextAttachmentProvider(conversationId).notifier,
  );

  final aiModeState = context.providerContainer.read(
    aiInputModeProvider(conversationId),
  );
  if (aiModeState.enabled) {
    final provider = _resolveAiModeProvider(
      selectedAiProvider: context.database.settingProperties.selectedAiProvider,
      enabledAiProviders: context.database.settingProperties.aiProviders
          .whereType<AiProviderConfig>()
          .where((element) => element.enabled)
          .toList(),
      providerId: aiModeState.providerId,
      selectedModel: aiModeState.model,
    );
    if (provider == null || provider.model.trim().isEmpty) {
      showToastFailed(ToastError('Please add an AI provider first'));
      return;
    }
    final target = _aiThreadTarget(
      aiThreadId: aiThreadId,
      createNewAiThread: createNewAiThread,
    );
    if (target == null) {
      showToastFailed(ToastError('AI thread unavailable'));
      return;
    }
    try {
      await AiChatController(context.database).send(
        conversationId: conversationId,
        target: target,
        input: text,
        language: _currentLanguageTag(context),
        provider: provider,
        attachedMessages: attachedMessages,
        onThreadReady: (threadId) {
          context.providerContainer
              .read(
                aiAssistantThreadSelectionProvider(
                  conversationId,
                ).notifier,
              )
              .state = AiAssistantThreadSelection.existing(
            threadId,
          );
        },
        onInputAccepted: () {
          textEditingController.text = '';
          attachedMessagesNotifier.clear();
        },
      );
    } catch (error, _) {
      showToastFailed(error);
    }
    return;
  }

  if (inlineAiInput != null && inlineAiInput.isNotEmpty) {
    final provider = context.database.settingProperties.selectedAiProvider;
    if (provider == null || provider.model.trim().isEmpty) {
      showToastFailed(ToastError('Please add an AI provider first'));
      return;
    }
    unawaited(
      context.read<ChatSideCubit>().replace(ChatSideCubit.aiAssistantPage),
    );
    final target = _aiThreadTarget(
      aiThreadId: aiThreadId,
      createNewAiThread: createNewAiThread,
    );
    if (target == null) {
      showToastFailed(ToastError('AI thread unavailable'));
      return;
    }
    try {
      await AiChatController(context.database).send(
        conversationId: conversationId,
        target: target,
        input: inlineAiInput,
        language: _currentLanguageTag(context),
        provider: provider,
        attachedMessages: attachedMessages,
        onThreadReady: (threadId) {
          context.providerContainer
              .read(
                aiAssistantThreadSelectionProvider(
                  conversationId,
                ).notifier,
              )
              .state = AiAssistantThreadSelection.existing(
            threadId,
          );
        },
        onInputAccepted: () {
          textEditingController.text = '';
          attachedMessagesNotifier.clear();
        },
      );
    } catch (error, _) {
      showToastFailed(error);
    }
    return;
  }

  await context.accountServer.sendTextMessage(
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

AiThreadTarget? _aiThreadTarget({
  required String? aiThreadId,
  required bool createNewAiThread,
}) {
  if (createNewAiThread) {
    return const AiThreadTarget.createNew();
  }
  if (aiThreadId == null) {
    return null;
  }
  return AiThreadTarget.existing(aiThreadId);
}

AiProviderConfig? _resolveAiModeProvider({
  required AiProviderConfig? selectedAiProvider,
  required List<AiProviderConfig> enabledAiProviders,
  required String? providerId,
  required String? selectedModel,
}) {
  var provider = selectedAiProvider;
  if (providerId != null) {
    for (final item in enabledAiProviders) {
      if (item.id == providerId) {
        provider = item;
        break;
      }
    }
  }
  if (provider == null) return null;

  final trimmedModel = selectedModel?.trim();
  if (trimmedModel == null || trimmedModel.isEmpty) return provider;
  if (provider.models.isNotEmpty && !provider.models.contains(trimmedModel)) {
    return provider;
  }
  if (provider.model == trimmedModel) return provider;
  return provider.copyWith(defaultModel: trimmedModel, model: trimmedModel);
}

class _SendTextField extends HookConsumerWidget {
  const _SendTextField({
    required this.focusNode,
    required this.textEditingController,
    required this.mentionProviderInstance,
    required this.aiModeEnabled,
    required this.providerName,
    required this.modelName,
    required this.aiThreadId,
    required this.createNewAiThread,
    required this.aiRequestInFlight,
    required this.aiDraftAssistState,
  });

  final FocusNode focusNode;
  final TextEditingController textEditingController;
  final AutoDisposeStateNotifierProvider<MentionStateNotifier, MentionState>
  mentionProviderInstance;
  final bool aiModeEnabled;
  final String? providerName;
  final String? modelName;
  final String? aiThreadId;
  final bool createNewAiThread;
  final bool aiRequestInFlight;
  final AiDraftAssistViewState aiDraftAssistState;

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

    final placeholder = isEncryptConversation
        ? context.l10n.chatHintE2e
        : context.l10n.typeMessage;
    final canSubmit = sendable && (!aiModeEnabled || !aiRequestInFlight);
    final aiDraftAssistActive = !aiDraftAssistState.isIdle;
    final aiDraftAssistHasResult =
        aiDraftAssistState.phase == AiDraftAssistPhase.result;
    final fieldColor = context.dynamicColor(
      const Color.fromRGBO(245, 247, 250, 1),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
    );
    final borderColor = aiDraftAssistActive
        ? context.theme.accent.withValues(
            alpha: aiDraftAssistHasResult ? 0.26 : 0.16,
          )
        : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(minHeight: 40),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        color: fieldColor,
        border: Border.all(color: borderColor),
      ),
      alignment: Alignment.center,
      child: FocusableActionDetector(
        autofocus: true,
        shortcuts: {
          if (canSubmit)
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
            onInvoke: (intent) => unawaited(
              _sendMessage(
                context,
                textEditingController,
                conversationId: ref.read(currentConversationIdProvider),
                aiThreadId: aiThreadId,
                createNewAiThread: createNewAiThread,
              ),
            ),
          ),
          PasteTextIntent: _PasteContextAction(context),
          _SendPostMessageIntent: CallbackAction<Intent>(
            onInvoke: (_) => _sendPostMessage(context, textEditingController),
          ),
          EscapeIntent: CallbackAction<Intent>(
            onInvoke: (_) {
              if (aiModeEnabled) {
                final conversationId = ref.read(currentConversationIdProvider);
                if (conversationId != null) {
                  ref.read(aiInputModeProvider(conversationId).notifier).exit();
                  return null;
                }
              }
              ref.read(quoteMessageProvider.notifier).state = null;
              return null;
            },
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
                contentPadding: EdgeInsets.only(
                  left: 10,
                  right: 10,
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
                      placeholder,
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

class _AiModeBar extends HookConsumerWidget {
  const _AiModeBar({required this.conversationId, required this.provider});

  final String conversationId;
  final AiProviderConfig? provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerName = provider?.name.trim().isNotEmpty == true
        ? provider!.name.trim()
        : 'No Provider';
    final model = provider?.model.trim();
    final hasProvider = provider != null;
    final notifier = ref.read(aiInputModeProvider(conversationId).notifier);
    final enabledAiProviders = context.database.settingProperties.aiProviders
        .whereType<AiProviderConfig>()
        .where((element) => element.enabled)
        .toList();
    final providerOptions = enabledAiProviders
        .map(
          (item) => CustomPopupMenuItem<AiProviderConfig>(
            title: item.name,
            value: item,
          ),
        )
        .toList(growable: false);
    final modelOptions =
        provider?.models
            .where((item) => item.trim().isNotEmpty)
            .map(
              (item) => CustomPopupMenuItem<String>(
                title: item.trim(),
                value: item.trim(),
              ),
            )
            .toList(growable: false) ??
        <CustomPopupMenuItem<String>>[];

    return SizedBox(
      width: double.infinity,
      height: 30,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: _AiModeMenuChip<AiProviderConfig>(
                    icon: Icons.hub_rounded,
                    label: providerName,
                    items: providerOptions,
                    enabled: providerOptions.length > 1,
                    onSelected: (value) => notifier.updateProvider(
                      providerId: value.id,
                      model: value.model,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _AiModeDivider(),
                const SizedBox(width: 10),
                Flexible(
                  child: _AiModeMenuChip<String>(
                    icon: Icons.tune_rounded,
                    label: model?.isNotEmpty == true
                        ? model!
                        : (hasProvider ? 'Select Model' : 'No Model'),
                    items: modelOptions,
                    enabled: modelOptions.length > 1,
                    onSelected: notifier.updateModel,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ActionButton(
            name: Resources.assetsImagesIcCloseSvg,
            color: context.theme.icon,
            size: 20,
            onTap: () =>
                ref.read(aiInputModeProvider(conversationId).notifier).exit(),
          ),
        ],
      ),
    );
  }
}

class _AiModeDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 14,
    color: context.dynamicColor(
      const Color.fromRGBO(0, 0, 0, 0.08),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.1),
    ),
  );
}

class _AiModeBadge extends StatelessWidget {
  const _AiModeBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(Icons.auto_awesome_rounded, size: 14, color: color)],
    ),
  );
}

class _AiModeMenuChip<T> extends StatelessWidget {
  const _AiModeMenuChip({
    required this.icon,
    required this.label,
    required this.items,
    required this.onSelected,
    this.maxWidth = 200,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final List<CustomPopupMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final double maxWidth;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final child = IntrinsicWidth(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Row(
          children: [
            Icon(icon, size: 13, color: context.theme.secondaryText),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.theme.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (enabled) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: context.theme.secondaryText,
              ),
            ],
          ],
        ),
      ),
    );

    if (!enabled || items.isEmpty) return child;

    return CustomPopupMenuButton<T>(
      itemBuilder: (_) => items,
      onSelected: onSelected,
      color: Colors.transparent,
      useActionButton: false,
      child: child,
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

                final quoteMessage = ref.read(quoteMessageProvider.notifier);

                await context.accountServer.sendContactMessage(
                  userId,
                  user.fullName,
                  conversationState.encryptCategory,
                  conversationId: conversationState.conversationId,
                  recipientId: conversationState.userId,
                  quoteMessageId: quoteMessage.state?.messageId,
                );
                quoteMessage.state = null;
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
                await showFilesPreviewDialog(context, [image.withMineType()]);
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
            context.sendMenuPosition(position);
          } else {
            context.sendMenuPosition(details.globalPosition);
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

    final stickerAlbumsCubit = useBloc(
      () => StickerAlbumsCubit(
        context.database.stickerAlbumDao.systemAddedAlbums().watchWithStream(
          eventStreams: [DataBaseEventBus.instance.updateStickerStream],
          duration: kVerySlowThrottleDuration,
        ),
      ),
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

class MentionTextMatcher extends TextMatcher implements EquatableMixin {
  MentionTextMatcher(this.mentionCache, this.highlightTextStyle)
    : super.regExp(
        regExp: mentionNumberRegExp,
        matchBuilder: (span, displayString, linkString) {
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
    required this.mentionCache,
    String? initialText,
  }) : super(text: initialText) {
    mentionsStreamController.stream
        .distinct()
        .asyncBufferMap(
          (event) => mentionCache.checkMentionCache(event.toSet()),
        )
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
    required bool withComposing,
    TextStyle? style,
  }) {
    mentionsStreamController.add(text);
    if (!value.isComposingRangeValid || !withComposing) {
      return _buildTextSpan(text, style);
    }

    return TextSpan(
      style: style,
      children: <TextSpan>[
        _buildTextSpan(value.composing.textBefore(value.text), style),
        _buildTextSpan(
          value.composing.textInside(value.text),
          style?.merge(const TextStyle(decoration: TextDecoration.underline)),
        ),
        _buildTextSpan(value.composing.textAfter(value.text), style),
      ],
    );
  }

  TextSpan _buildTextSpan(String text, TextStyle? style) => TextSpan(
    style: style,
    children: TextMatcher.applyTextMatchers(
      [TextSpan(text: text, style: style)],
      [
        MentionTextMatcher(mentionCache, highlightTextStyle),
        EmojiTextMatcher(),
      ],
    ).toList(),
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
