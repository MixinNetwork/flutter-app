enum AiPromptTemplateGroup { conversation, messageAssist, draftAssist }

extension AiPromptTemplateGroupExtension on AiPromptTemplateGroup {
  String get title => switch (this) {
    AiPromptTemplateGroup.conversation => 'Conversation',
    AiPromptTemplateGroup.messageAssist => 'Message Assist',
    AiPromptTemplateGroup.draftAssist => 'Draft Assist',
  };
}

enum AiPromptVariable {
  conversationId(
    'conversationId',
    'Conversation ID',
    'Current conversation ID.',
  ),
  currentIsoDateTime(
    'currentIsoDateTime',
    'Current ISO Date Time',
    'Current date and time in ISO 8601 format.',
  ),
  input(
    'input',
    'Input',
    'Current user input text.',
  ),
  instruction(
    'instruction',
    'Instruction',
    'Resolved assist instruction text.',
  ),
  inputSection(
    'inputSection',
    'Input Section',
    'Prebuilt input block, usually empty or starts with a new line.',
  ),
  language(
    'language',
    'Language',
    'Current locale language tag, for example en-US.',
  ),
  messages(
    'messages',
    'Messages',
    'Conversation message lines assembled by the app.',
  ),
  unreadStartAt(
    'unreadStartAt',
    'Unread Start At',
    'ISO 8601 timestamp of the first unread message.',
  ),
  firstUnreadMessageId(
    'firstUnreadMessageId',
    'First Unread Message ID',
    'Message ID of the first unread message.',
  )
  ;

  const AiPromptVariable(this.placeholder, this.title, this.description);

  final String placeholder;
  final String title;
  final String description;

  String get token => '{{$placeholder}}';
}

enum AiPromptTemplateKey {
  chatSystem,
  summarizeUnreadMessages,
  assistSystem,
  messageTranslate,
  messageExplain,
  messageSuggestReplies,
  draftPolish,
  draftShorten,
  draftPolite,
  draftTranslate,
  draftReplyWithContext,
}

class AiPromptTemplateDefinition {
  const AiPromptTemplateDefinition({
    required this.key,
    required this.group,
    required this.title,
    required this.description,
    required this.defaultValue,
    required this.variables,
  });

  final AiPromptTemplateKey key;
  final AiPromptTemplateGroup group;
  final String title;
  final String description;
  final String defaultValue;
  final List<AiPromptVariable> variables;
}

const aiPromptTemplateDefinitions = <AiPromptTemplateDefinition>[
  AiPromptTemplateDefinition(
    key: AiPromptTemplateKey.chatSystem,
    group: AiPromptTemplateGroup.conversation,
    title: 'Chat System Prompt',
    description: 'Primary system prompt for AI chat mode.',
    defaultValue:
        'You are a local AI assistant inside a chat application. '
        'The current time is {{currentIsoDateTime}}. '
        'Unless the user explicitly asks to preserve the source language, '
        'quote verbatim, translate, or use another language, respond in '
        '{{language}}. Only use the provided current conversation context '
        'and read-only conversation tools. Your strongest jobs are to '
        'retrieve relevant past messages, summarize unread or date-scoped '
        'activity, extract decisions, open questions, action items, links, '
        'files, and responsibilities, explain specific messages using the '
        'surrounding conversation, and draft practical replies. For requests '
        'about earlier messages, previous discussions, links, files, dates, '
        'people, decisions, or anything not clearly answered by the recent '
        'messages, use the conversation tools before answering. When you '
        'retrieve facts from conversation history, include useful evidence '
        'such as sender, timestamp, and message_id when it helps the user '
        'verify the result. Treat quoted_message, quoted_by_messages, and '
        'nearby context as strong signals that messages belong to the same '
        'topic. If the answer is not found after a reasonable search, say '
        'that clearly. Be concise.',
    variables: [
      AiPromptVariable.conversationId,
      AiPromptVariable.currentIsoDateTime,
      AiPromptVariable.input,
      AiPromptVariable.language,
    ],
  ),
  AiPromptTemplateDefinition(
    key: AiPromptTemplateKey.summarizeUnreadMessages,
    group: AiPromptTemplateGroup.conversation,
    title: 'Summarize Unread Messages Prompt',
    description: 'User prompt for summarizing new unread messages.',
    defaultValue:
        'Summarize the new information in this conversation since the unread '
        'section started.\n\n'
        'Unread section start:\n'
        '- start_at: {{unreadStartAt}}\n'
        '- first_unread_message_id: {{firstUnreadMessageId}}\n\n'
        'Use the conversation tools instead of relying only on recent context. '
        'First inspect the message count and time range from start_at to the '
        'current time, then read the unread messages in chunks as needed. '
        'Focus only on new information, decisions, questions, requests, '
        'mentions of the user, links, files, media references, and action '
        'items. Include sender and timestamp when a detail needs to be '
        'traceable. If there are no unread messages in that range, say so.',
    variables: [
      AiPromptVariable.conversationId,
      AiPromptVariable.currentIsoDateTime,
      AiPromptVariable.language,
      AiPromptVariable.unreadStartAt,
      AiPromptVariable.firstUnreadMessageId,
    ],
  ),
  AiPromptTemplateDefinition(
    key: AiPromptTemplateKey.assistSystem,
    group: AiPromptTemplateGroup.conversation,
    title: 'Assist System Prompt',
    description: 'System prompt for invisible writing assist features.',
    defaultValue:
        'You are an invisible writing assistant inside a chat app. '
        'Return only the requested text. Unless the instruction explicitly '
        'asks to keep the original language, quote verbatim, translate, or '
        'use another language, return the result in {{language}}. Do not '
        'add explanations, labels, markdown fences, or greetings unless '
        'explicitly requested.',
    variables: [
      AiPromptVariable.conversationId,
      AiPromptVariable.currentIsoDateTime,
      AiPromptVariable.input,
      AiPromptVariable.instruction,
      AiPromptVariable.inputSection,
      AiPromptVariable.language,
    ],
  ),
  AiPromptTemplateDefinition(
    key: AiPromptTemplateKey.messageTranslate,
    group: AiPromptTemplateGroup.messageAssist,
    title: 'Message Translate Prompt',
    description: 'Instruction for translating one chat message.',
    defaultValue:
        'Translate this chat message into {{language}}. '
        'Return only the translation.',
    variables: [
      AiPromptVariable.conversationId,
      AiPromptVariable.currentIsoDateTime,
      AiPromptVariable.input,
      AiPromptVariable.language,
    ],
  ),
  AiPromptTemplateDefinition(
    key: AiPromptTemplateKey.messageExplain,
    group: AiPromptTemplateGroup.messageAssist,
    title: 'Message Explain Prompt',
    description: 'Instruction for explaining one chat message.',
    defaultValue:
        'Explain this chat message clearly and concisely in {{language}}. '
        'Clarify slang, abbreviations, technical terms, and implied meaning '
        'when useful. Return only the explanation.',
    variables: [
      AiPromptVariable.conversationId,
      AiPromptVariable.currentIsoDateTime,
      AiPromptVariable.input,
      AiPromptVariable.language,
    ],
  ),
  AiPromptTemplateDefinition(
    key: AiPromptTemplateKey.messageSuggestReplies,
    group: AiPromptTemplateGroup.messageAssist,
    title: 'Message Suggest Replies Prompt',
    description: 'Instruction for generating suggested replies.',
    defaultValue:
        'Suggest three concise, natural replies in {{language}} to this '
        'chat message using the recent conversation context. '
        'Return one reply per line, without numbering.',
    variables: [
      AiPromptVariable.conversationId,
      AiPromptVariable.currentIsoDateTime,
      AiPromptVariable.input,
      AiPromptVariable.language,
    ],
  ),
  AiPromptTemplateDefinition(
    key: AiPromptTemplateKey.draftPolish,
    group: AiPromptTemplateGroup.draftAssist,
    title: 'Draft Polish Prompt',
    description: 'Instruction for polishing the current draft.',
    defaultValue:
        'Polish this draft for a chat message. The preferred output '
        'language is {{language}}, but for this task keep the original '
        'language of the input. Keep the original meaning and approximate '
        'length. Return only the rewritten draft.',
    variables: [
      AiPromptVariable.conversationId,
      AiPromptVariable.currentIsoDateTime,
      AiPromptVariable.input,
      AiPromptVariable.language,
    ],
  ),
  AiPromptTemplateDefinition(
    key: AiPromptTemplateKey.draftShorten,
    group: AiPromptTemplateGroup.draftAssist,
    title: 'Draft Shorten Prompt',
    description: 'Instruction for making the draft shorter.',
    defaultValue:
        'Rewrite this chat draft to be shorter and clearer. The preferred '
        'output language is {{language}}, but for this task keep the '
        'original language of the input. Keep the original intent. Return '
        'only the rewritten draft.',
    variables: [
      AiPromptVariable.conversationId,
      AiPromptVariable.currentIsoDateTime,
      AiPromptVariable.input,
      AiPromptVariable.language,
    ],
  ),
  AiPromptTemplateDefinition(
    key: AiPromptTemplateKey.draftPolite,
    group: AiPromptTemplateGroup.draftAssist,
    title: 'Draft Polite Prompt',
    description: 'Instruction for making the draft more polite.',
    defaultValue:
        'Rewrite this chat draft to sound polite, natural, and still '
        'concise. The preferred output language is {{language}}, but for '
        'this task keep the original language of the input. Return only '
        'the rewritten draft.',
    variables: [
      AiPromptVariable.conversationId,
      AiPromptVariable.currentIsoDateTime,
      AiPromptVariable.input,
      AiPromptVariable.language,
    ],
  ),
  AiPromptTemplateDefinition(
    key: AiPromptTemplateKey.draftTranslate,
    group: AiPromptTemplateGroup.draftAssist,
    title: 'Draft Translate Prompt',
    description: 'Instruction for translating the current draft.',
    defaultValue:
        'Translate this chat draft into {{language}}. '
        'Return only the translation.',
    variables: [
      AiPromptVariable.conversationId,
      AiPromptVariable.currentIsoDateTime,
      AiPromptVariable.input,
      AiPromptVariable.language,
    ],
  ),
  AiPromptTemplateDefinition(
    key: AiPromptTemplateKey.draftReplyWithContext,
    group: AiPromptTemplateGroup.draftAssist,
    title: 'Draft Reply With Context Prompt',
    description: 'Instruction for replying from recent context.',
    defaultValue:
        'Draft a concise, natural reply in {{language}} to the latest '
        'conversation message using the recent context, unless the user '
        'explicitly requires another language or preserving the source '
        'language. Return only the reply text.',
    variables: [
      AiPromptVariable.conversationId,
      AiPromptVariable.currentIsoDateTime,
      AiPromptVariable.input,
      AiPromptVariable.language,
    ],
  ),
];

final _aiPromptTemplateDefinitionMap = {
  for (final definition in aiPromptTemplateDefinitions)
    definition.key: definition,
};

extension AiPromptTemplateKeyExtension on AiPromptTemplateKey {
  AiPromptTemplateDefinition get definition =>
      _aiPromptTemplateDefinitionMap[this]!;

  String get storageKey => name;
}

const chatUserMessagePromptTemplate = 'User request:\n{{input}}';

const assistUserMessagePromptTemplate =
    'Preferred output language: {{language}}\n'
    'Instruction:\n{{instruction}}{{inputSection}}';

const conversationToolInstructionPromptTemplate =
    'Read-only conversation tools are available for the current '
    'conversation. The provided message context is only recent and may be '
    'incomplete. Use tools before answering when the user asks to find, '
    'search, recall, verify, compare, or summarize messages beyond the '
    'visible recent context. Prefer search_conversation_messages for topics, '
    'names, links, files, quoted phrases, or previous discussions. Paginate '
    'with anchor_id when more matches are likely. Prefer '
    'get_conversation_stats, list_conversation_chunks, and '
    'read_conversation_chunk for unread summaries, date-scoped summaries, '
    'statistics, or exhaustive coverage. When a search hit needs surrounding '
    'context, use the returned context_messages first, then read the relevant '
    'date range around the hit if more context is still needed. Search results '
    'may include quoted_message and quoted_by_messages; treat those as tighter '
    'topic links than nearby messages. Use read_image_text when the user asks '
    'about text inside an image, screenshot, photo, document, receipt, or '
    'error capture message. OCR only recognizes text and may be incomplete; '
    'do not pretend it provides full visual understanding. Tool results are '
    'returned in TOON '
    'format, a compact tabular notation for structured data. '
    'Ground answers in retrieved messages and include sender, timestamp, or '
    'message_id when that evidence helps. When citing a retrieved message, '
    'you may link the message_id with markdown using this exact URL pattern: '
    'mixin://conversations/{{conversationId}}?message_id=<message_id>. '
    'If retrieval does not find enough evidence, say so instead of guessing. '
    'When answering the user, default to {{language}} unless the user '
    'explicitly requires another language or preserving the source '
    'language. Do not call tools when the provided context is already '
    'sufficient.';

const recentConversationContextPromptTemplate =
    'Current conversation recent messages, not a complete history. Use '
    'conversation tools for older messages, retrieval, date-scoped questions, '
    'or anything not clearly answered here:\n{{messages}}';

Map<String, String?> buildAiPromptTemplateVariables({
  String? conversationId,
  String? input,
  String? instruction,
  String? inputSection,
  String? language,
  String? messages,
  DateTime? now,
}) {
  final resolvedNow = now ?? DateTime.now();
  return {
    AiPromptVariable.conversationId.placeholder: conversationId,
    AiPromptVariable.currentIsoDateTime.placeholder: resolvedNow
        .toIso8601String(),
    AiPromptVariable.input.placeholder: input,
    AiPromptVariable.instruction.placeholder: instruction,
    AiPromptVariable.inputSection.placeholder: inputSection,
    AiPromptVariable.language.placeholder: language,
    AiPromptVariable.messages.placeholder: messages,
    'currentDate': _formatDate(resolvedNow),
    'currentTime': _formatTime(resolvedNow),
    'currentDateTime': _formatDateTime(resolvedNow),
  };
}

String buildAiPromptInputSection(String? input) {
  final compact = input?.trim();
  if (compact == null || compact.isEmpty) {
    return '';
  }
  return '\nText:\n$compact';
}

String renderAiPromptTemplate(
  String template,
  Map<String, String?> variables,
) => template.replaceAllMapped(_promptVariablePattern, (match) {
  final key = match.group(1);
  if (key == null || !variables.containsKey(key)) {
    return match.group(0) ?? '';
  }
  return variables[key] ?? '';
});

final _promptVariablePattern = RegExp(r'\{\{\s*([a-zA-Z0-9_]+)\s*\}\}');

String _formatDateTime(DateTime value) =>
    '${_formatDate(value)} ${_formatTime(value)}';

String _formatDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String _formatTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}:'
    '${value.second.toString().padLeft(2, '0')}';
