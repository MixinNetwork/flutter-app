import 'package:mixin_logger/mixin_logger.dart';

import '../db/database.dart';
import '../db/mixin_database.dart';
import 'model/ai_prompt_message.dart';
import 'model/ai_prompt_template.dart';

class AiChatPromptBuilder {
  AiChatPromptBuilder(this.database);

  static const _aiStatusPending = 'pending';
  static const _aiContextMessageLimit = 30;
  static const _aiHistoryLimit = 12;

  final Database database;

  Future<List<AiPromptMessage>> buildPromptMessages(
    String conversationId,
    String input,
    String language,
  ) async {
    final now = DateTime.now();
    final recentMessages = await database.messageDao
        .messagesByConversationId(conversationId, _aiContextMessageLimit)
        .get();
    final aiMessages = await database.aiChatMessageDao.conversationMessages(
      conversationId,
    );

    final promptMessages = <AiPromptMessage>[
      ..._promptMessages(
        role: AiPromptRole.system,
        content: renderAiPromptTemplate(
          database.settingProperties.aiPromptTemplate(
            AiPromptTemplateKey.chatSystem,
          ),
          buildAiPromptTemplateVariables(
            conversationId: conversationId,
            input: input,
            language: language,
            now: now,
          ),
        ),
      ),
    ];

    _appendConversationToolInstruction(
      promptMessages,
      enabled: true,
      conversationId: conversationId,
      language: language,
      now: now,
    );
    _appendConversationContext(
      promptMessages,
      conversationId: conversationId,
      recentMessages: recentMessages,
      language: language,
      now: now,
    );

    final history = aiMessages
        .where((element) => element.status != _aiStatusPending)
        .takeLast(_aiHistoryLimit);
    for (final item in history) {
      promptMessages.add(
        AiPromptMessage(role: AiPromptRole(item.role), content: item.content),
      );
    }

    promptMessages.addAll(
      _promptMessages(
        role: AiPromptRole.user,
        content: renderAiPromptTemplate(
          chatUserMessagePromptTemplate,
          buildAiPromptTemplateVariables(
            conversationId: conversationId,
            input: input,
            language: language,
            now: now,
          ),
        ),
      ),
    );
    d(
      'AI prompt built: conversationId=$conversationId '
      'recent=${recentMessages.length} '
      'history=${history.length} promptMessages=${promptMessages.length}',
    );
    return promptMessages;
  }

  Future<List<AiPromptMessage>> buildAssistPromptMessages({
    required String instruction,
    required String? input,
    required String? conversationId,
    required String language,
  }) async {
    final now = DateTime.now();
    final inputText = input?.trim();
    final trimmedInstruction = instruction.trim();
    final promptMessages = <AiPromptMessage>[
      ..._promptMessages(
        role: AiPromptRole.system,
        content: renderAiPromptTemplate(
          database.settingProperties.aiPromptTemplate(
            AiPromptTemplateKey.assistSystem,
          ),
          buildAiPromptTemplateVariables(
            conversationId: conversationId,
            input: inputText,
            instruction: trimmedInstruction,
            inputSection: buildAiPromptInputSection(inputText),
            language: language,
            now: now,
          ),
        ),
      ),
    ];

    if (conversationId != null) {
      _appendConversationToolInstruction(
        promptMessages,
        enabled: true,
        conversationId: conversationId,
        language: language,
        now: now,
      );
      final recentMessages = await database.messageDao
          .messagesByConversationId(conversationId, _aiContextMessageLimit)
          .get();
      _appendConversationContext(
        promptMessages,
        conversationId: conversationId,
        recentMessages: recentMessages,
        language: language,
        now: now,
      );
    }

    promptMessages.addAll(
      _promptMessages(
        role: AiPromptRole.user,
        content: renderAiPromptTemplate(
          assistUserMessagePromptTemplate,
          buildAiPromptTemplateVariables(
            conversationId: conversationId,
            input: inputText,
            instruction: trimmedInstruction,
            inputSection: buildAiPromptInputSection(inputText),
            language: language,
            now: now,
          ),
        ),
      ),
    );
    d(
      'AI assist prompt built: conversationId=$conversationId '
      'messages=${promptMessages.length}',
    );
    return promptMessages;
  }

  void _appendConversationToolInstruction(
    List<AiPromptMessage> promptMessages, {
    required bool enabled,
    required String? conversationId,
    required String language,
    required DateTime now,
  }) {
    if (!enabled) {
      return;
    }
    promptMessages.addAll(
      _promptMessages(
        role: AiPromptRole.system,
        content: renderAiPromptTemplate(
          conversationToolInstructionPromptTemplate,
          buildAiPromptTemplateVariables(
            conversationId: conversationId,
            language: language,
            now: now,
          ),
        ),
      ),
    );
  }

  void _appendConversationContext(
    List<AiPromptMessage> promptMessages, {
    required String conversationId,
    required List<MessageItem> recentMessages,
    required String language,
    required DateTime now,
  }) {
    if (recentMessages.isNotEmpty) {
      final lines = recentMessages.reversed
          .map(
            (message) => _conversationContextLine(
              createdAt: message.createdAt,
              sender: message.userFullName ?? message.userId,
              content: _messagePlainText(message),
            ),
          )
          .join('\n');
      promptMessages.addAll(
        _promptMessages(
          role: AiPromptRole.system,
          content: renderAiPromptTemplate(
            recentConversationContextPromptTemplate,
            buildAiPromptTemplateVariables(
              conversationId: conversationId,
              messages: lines,
              language: language,
              now: now,
            ),
          ),
        ),
      );
    }
  }

  String _conversationContextLine({
    required DateTime createdAt,
    required String sender,
    required String content,
  }) => '[${createdAt.toIso8601String()}] $sender: $content';

  String _messagePlainText(MessageItem message) => _messagePlainTextFromFields(
    content: message.content,
    mediaName: message.mediaName,
    type: message.type,
  );

  String _messagePlainTextFromFields({
    required String? content,
    required String? mediaName,
    required String type,
  }) {
    if (content?.trim().isNotEmpty == true) {
      return content!.trim();
    }
    if (mediaName?.isNotEmpty == true) {
      return '[$type] $mediaName';
    }
    return '[$type]';
  }

  List<AiPromptMessage> _promptMessages({
    required AiPromptRole role,
    required String content,
  }) {
    if (content.trim().isEmpty) {
      return const [];
    }
    return [AiPromptMessage(role: role, content: content)];
  }
}

extension _IterableTakeLastExtension<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    if (count <= 0) return const [];
    final list = toList();
    if (list.length <= count) {
      return list;
    }
    return list.sublist(list.length - count);
  }
}
