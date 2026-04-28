import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../ai/ai_chat_controller.dart';
import '../../../ai/model/ai_provider_config.dart';
import '../../../constants/constants.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/toast.dart';
import '../../provider/ai_input_mode_provider.dart';
import '../../provider/conversation_provider.dart';
import 'ai_assistant/composer.dart';
import 'ai_assistant/constants.dart';
import 'ai_assistant/helpers.dart';
import 'ai_assistant/message_list.dart';

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
    final aiProvider = resolveAiAssistantProvider(
      selectedAiProvider: context.database.settingProperties.selectedAiProvider,
      enabledAiProviders: enabledAiProviders,
      providerId: aiModeState.providerId,
      selectedModel: aiModeState.model,
    );
    final latestMessages =
        useMemoizedStream(
          () =>
              context.database.aiChatMessageDao.watchLatestConversationMessages(
                conversationId,
                aiAssistantMessagePageLimit,
              ),
          keys: [conversationId],
          initialData: const <AiChatMessage>[],
        ).data ??
        const <AiChatMessage>[];
    final requestInFlight = latestMessages.any(isActivePendingAiMessage);
    final textEditingController = useMemoized(
      TextEditingController.new,
      [conversationId],
    );
    final focusNode = useFocusNode();

    useEffect(() {
      if (!context.textFieldAutoGainFocus) {
        focusNode.unfocus();
        return null;
      }
      focusNode.requestFocus();
      return null;
    }, [conversationId]);

    Future<void> send() async {
      final text = textEditingController.text.trim();
      if (text.isEmpty) return;
      if (text.length > kMaxTextLength) {
        showToastFailed(ToastError(context.l10n.contentTooLong));
        return;
      }
      if (aiProvider == null) {
        showToastFailed(ToastError(aiAssistantUnavailable));
        return;
      }

      try {
        await AiChatController(context.database).send(
          conversationId: conversationId,
          input: text,
          language: currentLanguageTag(context),
          provider: aiProvider,
          onInputAccepted: textEditingController.clear,
        );
      } catch (error, _) {
        showToastFailed(error);
      }
    }

    return Scaffold(
      backgroundColor: context.theme.primary,
      appBar: const MixinAppBar(title: Text(aiAssistantTitle)),
      body: Column(
        children: [
          Expanded(
            child: AiAssistantMessageList(
              conversationId: conversationId,
              latestMessages: latestMessages,
            ),
          ),
          AiAssistantComposer(
            focusNode: focusNode,
            textEditingController: textEditingController,
            enabled: aiProvider != null,
            provider: aiProvider,
            enabledAiProviders: enabledAiProviders,
            requestInFlight: requestInFlight,
            onSend: send,
            onStop: () =>
                AiChatController(context.database).stop(conversationId),
            onProviderSelected: (value) => aiModeNotifier.updateProvider(
              providerId: value.id,
              model: value.model,
            ),
            onModelSelected: aiModeNotifier.updateModel,
          ),
        ],
      ),
    );
  }
}
