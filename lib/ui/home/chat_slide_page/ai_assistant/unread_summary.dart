import 'package:flutter/widgets.dart';

import '../../../../ai/ai_chat_controller.dart';
import '../../../../ai/ai_thread_target.dart';
import '../../../../ai/model/ai_prompt_template.dart';
import '../../../../db/dao/conversation_dao.dart';
import '../../../../db/database.dart';
import '../../../../db/mixin_database.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../widgets/toast.dart';
import '../../../provider/ai_assistant_thread_provider.dart';
import '../../../provider/conversation_provider.dart';
import '../../chat/chat_page.dart';
import 'helpers.dart';

bool hasAvailableAiModel(BuildContext context) =>
    context.database.settingProperties.selectedAiProvider?.model
        .trim()
        .isNotEmpty ==
    true;

Future<void> summarizeUnreadMessagesWithAi({
  required BuildContext context,
  required String conversationId,
  required String? lastReadMessageId,
  ConversationItem? conversation,
  bool selectConversation = false,
}) async {
  final database = context.database;
  final providerContainer = context.providerContainer;
  final language = currentLanguageTag(context);
  final provider = database.settingProperties.selectedAiProvider;
  if (provider == null || provider.model.trim().isEmpty) {
    showToastFailed(ToastError('Please add an AI provider first'));
    return;
  }

  try {
    final firstUnreadMessage = await _firstUnreadMessage(
      database,
      conversationId: conversationId,
      lastReadMessageId: lastReadMessageId,
    );
    if (firstUnreadMessage == null) return;
    if (!context.mounted) return;

    if (selectConversation) {
      await ConversationStateNotifier.selectConversation(
        context,
        conversationId,
        conversation: conversation,
        initialChatSidePage: ChatSideCubit.aiAssistantPage,
      );
    } else {
      await context.read<ChatSideCubit>().replace(
        ChatSideCubit.aiAssistantPage,
      );
    }

    final thread = await database.aiChatMessageDao.createThread(
      conversationId,
    );
    providerContainer
        .read(aiAssistantThreadSelectionProvider(conversationId).notifier)
        .state = AiAssistantThreadSelection.existing(
      thread.id,
    );

    await AiChatController(database).send(
      conversationId: conversationId,
      target: AiThreadTarget.existing(thread.id),
      input: _unreadSummaryPrompt(
        database: database,
        conversationId: conversationId,
        firstUnreadMessage: firstUnreadMessage,
        language: language,
      ),
      language: language,
      provider: provider,
    );
  } catch (error, _) {
    showToastFailed(error);
  }
}

Future<MessageItem?> _firstUnreadMessage(
  Database database, {
  required String conversationId,
  required String? lastReadMessageId,
}) async {
  final messageDao = database.messageDao;
  if (lastReadMessageId == null || lastReadMessageId.isEmpty) {
    return messageDao
        .messagesByConversationIdAndCreatedAtRange(conversationId, limit: 1)
        .getSingleOrNull();
  }

  final orderInfo = await messageDao.messageOrderInfo(lastReadMessageId);
  if (orderInfo == null) {
    return messageDao
        .messagesByConversationIdAndCreatedAtRange(conversationId, limit: 1)
        .getSingleOrNull();
  }
  return messageDao
      .afterMessagesByConversationId(orderInfo, conversationId, 1)
      .getSingleOrNull();
}

String _unreadSummaryPrompt({
  required Database database,
  required String conversationId,
  required MessageItem firstUnreadMessage,
  required String language,
}) {
  final startAt = firstUnreadMessage.createdAt.toIso8601String();
  return renderAiPromptTemplate(
    database.settingProperties.aiPromptTemplate(
      AiPromptTemplateKey.summarizeUnreadMessages,
    ),
    {
      ...buildAiPromptTemplateVariables(
        conversationId: conversationId,
        language: language,
      ),
      AiPromptVariable.unreadStartAt.placeholder: startAt,
      AiPromptVariable.firstUnreadMessageId.placeholder:
          firstUnreadMessage.messageId,
    },
  );
}
