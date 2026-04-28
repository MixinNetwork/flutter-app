import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../ai/ai_chat_controller.dart';
import '../../../ai/model/ai_provider_config.dart';
import '../../../constants/constants.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/ai/ai_message_card.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/empty.dart';
import '../../../widgets/menu.dart';
import '../../../widgets/message/message_day_time.dart';
import '../../../widgets/toast.dart';
import '../../provider/ai_input_mode_provider.dart';
import '../../provider/conversation_provider.dart';

const _aiAssistantTitle = 'AI Assistant';
const _aiAssistantEmpty = 'Ask AI about this conversation';
const _aiAssistantInputHint = 'Ask about this conversation';
const _aiAssistantUnavailable = 'Add a usable AI model in Settings first';

class AiAssistantPage extends HookConsumerWidget {
  const AiAssistantPage(this.conversationState, {super.key});

  final ConversationState conversationState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useListenable(context.database.settingProperties);

    final conversationId = conversationState.conversationId;
    final aiModeState = ref.watch(aiInputModeProvider(conversationId));
    final aiModeNotifier = ref.read(
      aiInputModeProvider(conversationId).notifier,
    );
    final enabledAiProviders = context.database.settingProperties.aiProviders
        .whereType<AiProviderConfig>()
        .where((item) => item.enabled && item.model.trim().isNotEmpty)
        .toList(growable: false);
    final aiProvider = _resolveAiAssistantProvider(
      selectedAiProvider: context.database.settingProperties.selectedAiProvider,
      enabledAiProviders: enabledAiProviders,
      providerId: aiModeState.providerId,
      selectedModel: aiModeState.model,
    );
    final messages =
        useMemoizedStream(
          () => context.database.aiChatMessageDao.watchConversationMessages(
            conversationId,
          ),
          keys: [conversationId],
          initialData: const <AiChatMessage>[],
        ).data ??
        const <AiChatMessage>[];
    final requestInFlight = messages.any(isActivePendingAiMessage);
    final textEditingController = useMemoized(
      TextEditingController.new,
      [conversationId],
    );
    final scrollController = useScrollController();
    final focusNode = useFocusNode();
    final lastMessage = messages.lastOrNull;

    useEffect(() {
      if (!context.textFieldAutoGainFocus) {
        focusNode.unfocus();
        return null;
      }
      focusNode.requestFocus();
      return null;
    }, [conversationId]);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) return;
        final position = scrollController.position;
        final shouldStickToBottom =
            messages.length <= 2 ||
            !position.hasContentDimensions ||
            position.maxScrollExtent - position.pixels < 96 ||
            lastMessage?.role == 'user';
        if (!shouldStickToBottom) return;
        unawaited(
          scrollController.animateTo(
            position.maxScrollExtent,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
          ),
        );
      });
      return null;
    }, [messages.length, lastMessage?.updatedAt, lastMessage?.content]);

    Future<void> send() async {
      final text = textEditingController.text.trim();
      if (text.isEmpty) return;
      if (text.length > kMaxTextLength) {
        showToastFailed(ToastError(context.l10n.contentTooLong));
        return;
      }
      if (aiProvider == null) {
        showToastFailed(ToastError(_aiAssistantUnavailable));
        return;
      }

      try {
        await AiChatController(context.database).send(
          conversationId: conversationId,
          input: text,
          language: _currentLanguageTag(context),
          provider: aiProvider,
          onInputAccepted: textEditingController.clear,
        );
      } catch (error, _) {
        showToastFailed(error);
      }
    }

    return Scaffold(
      backgroundColor: context.theme.primary,
      appBar: const MixinAppBar(title: Text(_aiAssistantTitle)),
      body: Column(
        children: [
          if (aiProvider != null)
            _AiAssistantModeBar(
              provider: aiProvider,
              enabledAiProviders: enabledAiProviders,
              onProviderSelected: (value) => aiModeNotifier.updateProvider(
                providerId: value.id,
                model: value.model,
              ),
              onModelSelected: aiModeNotifier.updateModel,
            ),
          Expanded(
            child: messages.isEmpty
                ? const Empty(text: _aiAssistantEmpty)
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return MessageDayTimeItem(
                        key: ValueKey('assistant-${message.id}'),
                        dateTime: message.createdAt,
                        prevDateTime: index > 0
                            ? messages[index - 1].createdAt
                            : null,
                        child: AiMessageCard(
                          message: message,
                          prev: index > 0 ? messages[index - 1] : null,
                          next: index < messages.length - 1
                              ? messages[index + 1]
                              : null,
                        ),
                      );
                    },
                  ),
          ),
          _AiAssistantComposer(
            focusNode: focusNode,
            textEditingController: textEditingController,
            enabled: aiProvider != null,
            requestInFlight: requestInFlight,
            onSend: send,
            onStop: () =>
                AiChatController(context.database).stop(conversationId),
          ),
        ],
      ),
    );
  }
}

class _AiAssistantModeBar extends StatelessWidget {
  const _AiAssistantModeBar({
    required this.provider,
    required this.enabledAiProviders,
    required this.onProviderSelected,
    required this.onModelSelected,
  });

  final AiProviderConfig provider;
  final List<AiProviderConfig> enabledAiProviders;
  final ValueChanged<AiProviderConfig> onProviderSelected;
  final ValueChanged<String?> onModelSelected;

  @override
  Widget build(BuildContext context) {
    final providerOptions = enabledAiProviders
        .map(
          (item) => CustomPopupMenuItem<AiProviderConfig>(
            title: item.name,
            value: item,
          ),
        )
        .toList(growable: false);
    final modelOptions = provider.models
        .where((item) => item.trim().isNotEmpty)
        .map(
          (item) => CustomPopupMenuItem<String>(
            title: item.trim(),
            value: item.trim(),
          ),
        )
        .toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.dynamicColor(
            const Color.fromRGBO(245, 247, 250, 1),
            darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(
            color: context.dynamicColor(
              const Color.fromRGBO(0, 0, 0, 0.05),
              darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: context.theme.ai.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: _AiModeChip<AiProviderConfig>(
                        icon: Icons.hub_rounded,
                        label: provider.name,
                        items: providerOptions,
                        enabled: providerOptions.length > 1,
                        onSelected: onProviderSelected,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _AiModeChip<String>(
                        icon: Icons.tune_rounded,
                        label: provider.model,
                        items: modelOptions,
                        enabled: modelOptions.length > 1,
                        onSelected: onModelSelected,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiModeChip<T> extends StatelessWidget {
  const _AiModeChip({
    required this.icon,
    required this.label,
    required this.items,
    required this.onSelected,
    required this.enabled,
  });

  final IconData icon;
  final String label;
  final List<CustomPopupMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final child = Row(
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

class _AiAssistantComposer extends StatelessWidget {
  const _AiAssistantComposer({
    required this.focusNode,
    required this.textEditingController,
    required this.enabled,
    required this.requestInFlight,
    required this.onSend,
    required this.onStop,
  });

  final FocusNode focusNode;
  final TextEditingController textEditingController;
  final bool enabled;
  final bool requestInFlight;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final buttonColor = !enabled
        ? context.theme.secondaryText
        : requestInFlight
        ? context.theme.red
        : context.theme.accent;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: context.theme.primary,
        border: Border(top: BorderSide(color: context.theme.divider)),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          color: context.dynamicColor(
            const Color.fromRGBO(245, 247, 250, 1),
            darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  focusNode: focusNode,
                  controller: textEditingController,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 6,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(kMaxTextLength),
                  ],
                  style: TextStyle(
                    color: context.theme.text,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: enabled
                        ? _aiAssistantInputHint
                        : _aiAssistantUnavailable,
                    hintStyle: TextStyle(
                      color: context.theme.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ActionButton(
                padding: const EdgeInsets.all(6),
                size: 20,
                interactive: enabled,
                onTap: requestInFlight ? onStop : onSend,
                child: Icon(
                  requestInFlight
                      ? Icons.stop_rounded
                      : Icons.arrow_upward_rounded,
                  size: 18,
                  color: buttonColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

AiProviderConfig? _resolveAiAssistantProvider({
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
  if (provider == null || provider.model.trim().isEmpty) {
    provider = enabledAiProviders.firstOrNull;
  }
  if (provider == null) return null;

  final trimmedModel = selectedModel?.trim();
  if (trimmedModel == null || trimmedModel.isEmpty) return provider;
  if (!provider.models.contains(trimmedModel)) return provider;
  if (provider.model == trimmedModel) return provider;
  return provider.copyWith(defaultModel: trimmedModel, model: trimmedModel);
}

String _currentLanguageTag(BuildContext context) {
  final locale = Localizations.localeOf(context);
  final countryCode = locale.countryCode;
  if (countryCode == null || countryCode.isEmpty) return locale.languageCode;
  return '${locale.languageCode}-$countryCode';
}
