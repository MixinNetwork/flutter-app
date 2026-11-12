import 'dart:async';

import 'package:flutter/gestures.dart'
    show PointerDeviceKind, kLongPressTimeout, kTouchSlop;
import 'package:flutter/material.dart'
    hide SelectableRegion, SelectableRegionState;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../ui/home/notifier/chat_side_notifier.dart';
import '../../../../ui/provider/conversation_provider.dart';
import '../../../../ui/provider/keyword_provider.dart';
import '../../../../ui/provider/mention_cache_provider.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/hook.dart';
import '../../../../utils/platform.dart';
import '../../../../utils/reg_exp_utils.dart';
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
    final content = useMessageConverter(
      converter: (state) => state.content ?? '',
    );
    return MessageBubble(
      child: MessageTextWidget(
        fontSize: context.messageStyle.primaryFontSize,
        color: context.theme.text,
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
    final userId = useMessageConverter(converter: (state) => state.userId);

    final mentionCache = ref.read(mentionCacheProvider);

    final mentionMap = useMemoizedFuture(
      () => mentionCache.checkMentionCache({content}),
      mentionCache.mentionCache(content),
      keys: [content],
    ).requireData;

    // A search keyword changes on every key press, and only the rows whose
    // shown text contains it need to build again.
    final mentionText = useMemoized(
      () => content.replaceAllMapped(mentionNumberRegExp, (match) {
        final user = mentionMap[match[1]];
        if (user == null) return match[0]!;
        return '@${user.fullName ?? user.identityNumber}';
      }),
      [content, mentionMap],
    );
    bool shows(String keyword) =>
        keyword.isNotEmpty &&
        (content.contains(keyword) || mentionText.contains(keyword));

    final keywordNotifier = context.read<SearchConversationKeywordNotifier>();
    final localKeyword =
        useListenableConverter<ValueNotifier<(String?, String)>, String>(
          keywordNotifier,
          converter: (notifier) {
            final state = notifier.value;
            if (state.$1 != null && state.$1 != userId) return '';
            return shows(state.$2) ? state.$2 : '';
          },
          keys: [userId, mentionText],
        ).data ??
        '';
    final conversationKeyword =
        ref.watch(conversationProvider.select((value) => value?.keyword)) ?? '';
    // The keyword this row shows when there is no global keyword.
    final rowKeyword = conversationKeyword.isNotEmpty
        ? (shows(conversationKeyword) ? conversationKeyword : '')
        : localKeyword;
    // A global keyword hides the other keywords even where it does not match,
    // so it changes a row only where it shows or hides a match.
    final globalKeyword = ref.watch(
      trimmedKeywordProvider.select((keyword) {
        if (shows(keyword)) return keyword;
        if (keyword.isNotEmpty && rowKeyword.isNotEmpty) return '';
        return null;
      }),
    );
    final keyword = globalKeyword ?? rowKeyword;

    Widget child = MessageLayout(
      spacing: 6,
      content: CustomText(
        content,
        style: TextStyle(fontSize: fontSize, color: color),
        textMatchers: [
          UrlTextMatcher(context),
          MailTextMatcher(context),
          MentionTextMatcher(context, mentionMap),
          BotNumberTextMatcher(context),
          EmojiTextMatcher(),
          KeyWordTextMatcher(
            keyword,
            style: TextStyle(
              backgroundColor: context.theme.highlight,
              color: context.theme.text,
            ),
          ),
        ],
      ),
      dateAndStatus: const MessageDatetimeAndStatus(),
    );

    if (enableSelection) {
      child = MessageSelectionArea(child: child);
    }
    return child;
  }
}

/// Text selection for a message on desktop.
///
/// A selection region costs every chat row gesture recognizers, a selection
/// registrar, and actions, so a row builds it only when the mouse first enters
/// the row's content, a pointer goes down on it, or the keyboard moves focus
/// to the row. A touch long press on a row without the region selects the
/// word when the press is long enough, as the region would.
class MessageSelectionArea extends StatefulWidget {
  const MessageSelectionArea({required this.child, super.key});

  final Widget child;

  @override
  State<MessageSelectionArea> createState() => _MessageSelectionAreaState();
}

class _MessageSelectionAreaState extends State<MessageSelectionArea> {
  final _focusNode = FocusNode(debugLabel: 'message_selection_focus');
  final _regionKey = GlobalKey<SelectableRegionState>();
  var _active = false;
  Timer? _longPress;
  int? _pressPointer;
  Offset? _pressPosition;

  void _activate() {
    if (_active) return;
    setState(() => _active = true);
  }

  void _handlePointerDown(PointerDownEvent event) {
    final startsLongPress = !_active && event.kind != PointerDeviceKind.mouse;
    _activate();
    if (!startsLongPress) return;
    // The region is built after this pointer went down, so its long press
    // recognizer does not see this press.
    _cancelLongPress();
    _pressPointer = event.pointer;
    _pressPosition = event.position;
    _longPress = Timer(kLongPressTimeout, () {
      final position = _pressPosition;
      _cancelLongPress();
      if (!mounted || position == null) return;
      _regionKey.currentState?.selectWordAtLongPress(position);
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final start = _pressPosition;
    if (event.pointer != _pressPointer || start == null) return;
    if ((event.position - start).distance > kTouchSlop) _cancelLongPress();
  }

  void _handlePointerEnd(PointerEvent event) {
    if (event.pointer == _pressPointer) _cancelLongPress();
  }

  void _cancelLongPress() {
    _longPress?.cancel();
    _longPress = null;
    _pressPointer = null;
    _pressPosition = null;
  }

  @override
  void dispose() {
    _cancelLongPress();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kPlatformIsDesktop) return widget.child;
    final Widget region;
    if (!_active) {
      region = Focus(
        focusNode: _focusNode,
        includeSemantics: false,
        // The selection region takes this node and keeps its focus.
        onFocusChange: (focused) {
          if (focused) _activate();
        },
        child: MouseRegion(
          opaque: false,
          onEnter: (_) => _activate(),
          child: widget.child,
        ),
      );
    } else {
      region = SelectableRegion(
        key: _regionKey,
        focusNode: _focusNode,
        contextMenuBuilder: (context, state) => const SizedBox(),
        selectionControls: desktopTextSelectionHandleControls,
        child: widget.child,
      );
    }
    return Listener(
      // A MouseRegion that is not opaque reports no hit, so this listener
      // takes the pointers in its bounds itself.
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerEnd,
      onPointerCancel: _handlePointerEnd,
      child: region,
    );
  }
}
