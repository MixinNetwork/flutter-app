import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../ai/ai_chat_controller.dart';
import '../../db/mixin_database.dart';
import '../../ui/provider/recall_message_reedit_provider.dart';
import '../../utils/extension/extension.dart';
import '../../utils/logger.dart';
import '../action_button.dart';
import '../markdown.dart';

enum MessageAiAction { translate, explain, suggestReplies }

const kInlineMessageAiLeadingPadding = 9.0;

final _inlineMessageAiStateCache = <String, InlineMessageAiState>{};

class InlineMessageAiState with EquatableMixin {
  const InlineMessageAiState({this.entries = const {}});

  final Map<MessageAiAction, InlineMessageAiEntry> entries;

  InlineMessageAiState put(
    MessageAiAction action,
    InlineMessageAiEntry entry,
  ) => InlineMessageAiState(
    entries: Map<MessageAiAction, InlineMessageAiEntry>.from(entries)
      ..[action] = entry,
  );

  InlineMessageAiState remove(MessageAiAction action) {
    if (!entries.containsKey(action)) return this;
    final nextEntries = Map<MessageAiAction, InlineMessageAiEntry>.from(entries)
      ..remove(action);
    return InlineMessageAiState(entries: nextEntries);
  }

  InlineMessageAiEntry? operator [](MessageAiAction action) => entries[action];

  bool get hasVisibleEntry =>
      entries.values.any((entry) => entry.loading || entry.hasContent);

  @override
  List<Object?> get props => [entries];
}

InlineMessageAiState readInlineMessageAiState(String messageId) =>
    _inlineMessageAiStateCache[messageId] ?? const InlineMessageAiState();

void writeInlineMessageAiState(
  String messageId,
  InlineMessageAiState state,
) {
  if (!state.hasVisibleEntry) {
    _inlineMessageAiStateCache.remove(messageId);
    return;
  }
  _inlineMessageAiStateCache[messageId] = state;
}

class InlineMessageAiEntry with EquatableMixin {
  const InlineMessageAiEntry({
    this.loading = false,
    this.result,
    this.error,
    this.model,
  });

  final bool loading;
  final String? result;
  final String? error;
  final String? model;

  bool get hasContent =>
      (result != null && result!.trim().isNotEmpty) ||
      (error != null && error!.trim().isNotEmpty);

  @override
  List<Object?> get props => [loading, result, error, model];
}

String? messageAiText(MessageItem message) {
  final content = message.content?.trim();
  if ((message.type.isText || message.type.isPost) &&
      content != null &&
      content.isNotEmpty) {
    return content;
  }

  final caption = message.caption?.trim();
  if (caption != null && caption.isNotEmpty) {
    return caption;
  }
  return null;
}

Future<void> runMessageAiAction(
  BuildContext context, {
  required MessageItem message,
  required String input,
  required MessageAiAction action,
  required void Function(MessageAiAction, InlineMessageAiEntry) onStateChanged,
}) async {
  final language = _currentLanguageTag(context);
  final provider = context.database.settingProperties.selectedAiProvider;
  final model = provider?.model;
  final instruction = switch (action) {
    MessageAiAction.translate =>
      'Translate this chat message into $language. Return only the translation.',
    MessageAiAction.explain =>
      'Explain this chat message clearly and concisely in $language. '
          'Clarify slang, abbreviations, technical terms, and implied meaning when useful. '
          'Return only the explanation.',
    MessageAiAction.suggestReplies =>
      'Suggest three concise, natural replies in $language to this chat message '
          'using the recent conversation context. Return one reply per line, without numbering.',
  };
  final title = switch (action) {
    MessageAiAction.translate => 'Translate',
    MessageAiAction.explain => 'Explain',
    MessageAiAction.suggestReplies => 'Suggest replies',
  };

  onStateChanged(
    action,
    InlineMessageAiEntry(loading: true, model: model),
  );
  try {
    final result = await AiChatController(context.database).assistText(
      instruction: instruction,
      input: input,
      conversationId: message.conversationId,
      provider: provider,
    );
    if (!context.mounted) return;
    onStateChanged(
      action,
      InlineMessageAiEntry(result: result.trim(), model: model),
    );
  } catch (error, stackTrace) {
    e('AI message assist failed: $error, $stackTrace');
    if (!context.mounted) return;
    onStateChanged(
      action,
      InlineMessageAiEntry(error: '$title failed: $error', model: model),
    );
  }
}

String _currentLanguageTag(BuildContext context) {
  final locale = Localizations.localeOf(context);
  final countryCode = locale.countryCode;
  if (countryCode == null || countryCode.isEmpty) return locale.languageCode;
  return '${locale.languageCode}-$countryCode';
}

List<String> _parseAiReplySuggestions(String result) => result
    .split('\n')
    .map((line) => line.trim().replaceFirst(RegExp(r'^[-*\d.)\s]+'), ''))
    .where((line) => line.isNotEmpty)
    .take(3)
    .toList(growable: false);

class MessageInlineAiSection extends StatelessWidget {
  const MessageInlineAiSection({
    required this.state,
    required this.onClose,
    this.leadingPadding = 0,
    super.key,
  });

  final InlineMessageAiState state;
  final void Function(MessageAiAction action) onClose;
  final double leadingPadding;

  @override
  Widget build(BuildContext context) {
    if (!state.hasVisibleEntry) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[
      for (final action in MessageAiAction.values)
        if (state[action]?.loading == true || state[action]?.hasContent == true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _InlineMessageAiCard(
              action: action,
              entry: state[action]!,
              onClose: () => onClose(action),
            ),
          ),
    ];

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(left: leadingPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _InlineMessageAiCard extends StatelessWidget {
  const _InlineMessageAiCard({
    required this.action,
    required this.entry,
    required this.onClose,
  });

  final MessageAiAction action;
  final InlineMessageAiEntry entry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final title = switch (action) {
      MessageAiAction.translate => 'Translation',
      MessageAiAction.explain => 'Explanation',
      MessageAiAction.suggestReplies => 'Suggested replies',
    };
    final loadingText = switch (action) {
      MessageAiAction.translate => 'Translating...',
      MessageAiAction.explain => 'Explaining...',
      MessageAiAction.suggestReplies => 'Generating replies...',
    };

    Widget content;
    if (entry.loading) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: context.theme.secondaryText,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            loadingText,
            style: TextStyle(
              color: context.theme.secondaryText,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      );
    } else if (entry.error?.isNotEmpty == true) {
      content = Text(
        entry.error!,
        style: TextStyle(
          color: context.theme.red,
          fontSize: 13,
          height: 1.45,
        ),
      );
    } else if (action == MessageAiAction.suggestReplies) {
      content = _InlineReplySuggestions(result: entry.result ?? '');
    } else if (action == MessageAiAction.explain) {
      final data = entry.result ?? '';
      content = MarkdownColumn(
        data: data,
        selectable: true,
        cacheKey: buildMarkdownCacheKey(
          namespace: 'inline-message-ai-explain',
          id: '${entry.model ?? 'unknown'}:${data.hashCode}',
        ),
      );
    } else {
      content = SelectableText(
        entry.result ?? '',
        style: TextStyle(
          color: context.theme.text,
          fontSize: 13,
          height: 1.45,
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.dynamicColor(
          const Color.fromRGBO(245, 247, 250, 1),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
        ),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.theme.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (entry.model?.isNotEmpty == true)
                Text(
                  entry.model!,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: context.theme.secondaryText,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              const SizedBox(width: 4),
              ActionButton(
                size: 14,
                padding: const EdgeInsets.all(2),
                onTap: onClose,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: context.theme.secondaryText,
                ),
              ),
            ],
          ),
          if (entry.model?.isNotEmpty == true) const SizedBox(height: 2),
          const SizedBox(height: 6),
          DefaultTextStyle.merge(
            style: const TextStyle(height: 1.45),
            child: content,
          ),
        ],
      ),
    );
  }
}

class _InlineReplySuggestions extends StatelessWidget {
  const _InlineReplySuggestions({required this.result});

  final String result;

  @override
  Widget build(BuildContext context) {
    final replies = _parseAiReplySuggestions(result);
    if (replies.isEmpty) {
      return SelectableText(
        result,
        style: TextStyle(
          color: context.theme.text,
          fontSize: 13,
          height: 1.45,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < replies.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == replies.length - 1 ? 0 : 6),
            child: _InlineReplyButton(reply: replies[i]),
          ),
      ],
    );
  }
}

class _InlineReplyButton extends StatelessWidget {
  const _InlineReplyButton({required this.reply});

  final String reply;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(6));
    return Material(
      color: context.dynamicColor(
        const Color.fromRGBO(255, 255, 255, 0.92),
        darkColor: const Color.fromRGBO(255, 255, 255, 0.04),
      ),
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () => context.providerContainer
            .read(recallMessageNotifierProvider)
            .onReedit(reply),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            reply,
            style: TextStyle(
              color: context.theme.text,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}
