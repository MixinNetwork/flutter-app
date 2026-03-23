import 'package:flutter/material.dart' hide SelectableRegion;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../ui/home/providers/home_scope_providers.dart';
import '../../../../ui/provider/conversation_provider.dart';
import '../../../../ui/provider/keyword_provider.dart';
import '../../../../ui/provider/mention_cache_provider.dart';
import '../../../../ui/provider/ui_context_providers.dart';
import '../../../../utils/hook.dart';
import '../../../../utils/platform.dart';
import '../../../high_light_text.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_datetime_and_status.dart';
import '../../message_layout.dart';
import '../../message_style.dart';
import 'selectable.dart';

class TextMessage extends HookConsumerWidget {
  const TextMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final content = useMessageConverter(
      converter: (state) => state.content ?? '',
    );
    return MessageBubble(
      child: MessageTextWidget(
        fontSize: context.messageStyle.primaryFontSize,
        color: theme.text,
        content: content,
      ),
    );
  }
}

class MessageTextWidget extends HookConsumerWidget {
  const MessageTextWidget({
    required this.fontSize,
    required this.color,
    required this.content,
    this.enableSelection = true,
    super.key,
  });

  final double fontSize;
  final Color color;
  final String content;
  final bool enableSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final userId = useMessageConverter(converter: (state) => state.userId);
    var keyword = ref.watch(searchConversationKeywordForUserProvider(userId));

    final globalKeyword = ref.watch(trimmedKeywordProvider);
    final conversationKeyword = ref.watch(
      conversationProvider.select((value) => value?.keyword),
    );

    if (globalKeyword.isNotEmpty) {
      keyword = globalKeyword;
    } else if (conversationKeyword?.isNotEmpty ?? false) {
      keyword = conversationKeyword!;
    }

    final mentionCache = ref.read(mentionCacheProvider);
    final app = ref.watch(conversationProvider.select((value) => value?.app));

    final mentionMap = useMemoizedFuture(
      () => mentionCache.checkMentionCache({content}),
      mentionCache.mentionCache(content),
      keys: [content],
    ).requireData;

    final focusNode = useFocusNode(debugLabel: 'text selection focus');

    Widget child = MessageLayout(
      spacing: 6,
      content: CustomText(
        content,
        style: TextStyle(fontSize: fontSize, color: color),
        textMatchers: [
          UrlTextMatcher(
            context,
            container: ref.container,
            accent: theme.accent,
            app: app,
          ),
          MailTextMatcher(accent: theme.accent),
          MentionTextMatcher(
            context,
            mentionMap,
            container: ref.container,
            accent: theme.accent,
          ),
          BotNumberTextMatcher(
            context,
            container: ref.container,
            accent: theme.accent,
          ),
          EmojiTextMatcher(),
          KeyWordTextMatcher(
            keyword,
            style: TextStyle(
              backgroundColor: theme.highlight,
              color: theme.text,
            ),
          ),
        ],
      ),
      dateAndStatus: const MessageDatetimeAndStatus(),
    );

    if (enableSelection) {
      child = MessageSelectionArea(focusNode: focusNode, child: child);
    }
    return child;
  }
}

class MessageSelectionArea extends HookWidget {
  const MessageSelectionArea({required this.child, this.focusNode, super.key});

  final Widget child;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final node = useMemoized(
      () => focusNode ?? FocusNode(debugLabel: 'message_selection_focus'),
      [focusNode],
    );
    if (kPlatformIsDesktop) {
      return SelectableRegion(
        focusNode: node,
        contextMenuBuilder: (context, state) => const SizedBox(),
        selectionControls: desktopTextSelectionHandleControls,
        child: child,
      );
    }
    return child;
  }
}
