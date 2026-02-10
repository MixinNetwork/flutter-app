import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../db/mixin_database.dart' hide Offset;
import '../ui/home/intent.dart';
import '../ui/provider/conversation_provider.dart';
import '../ui/provider/mention_provider.dart';
import '../utils/extension/extension.dart';
import '../utils/platform.dart';
import '../utils/reg_exp_utils.dart';
import 'avatar_view/avatar_view.dart';
import 'high_light_text.dart';
import 'interactive_decorated_box.dart';

const kMentionItemHeight = 50.0;

class MentionPanelPortalEntry extends HookConsumerWidget {
  const MentionPanelPortalEntry({
    required this.constraints,
    required this.textEditingController,
    required this.child,
    required this.mentionProviderInstance,
    super.key,
  });

  final BoxConstraints constraints;
  final TextEditingController textEditingController;
  final Widget child;
  final AutoDisposeStateNotifierProvider<MentionStateNotifier, MentionState>
  mentionProviderInstance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = ref.watch(
      mentionProviderInstance.notifier.select(
        (value) => value.scrollController,
      ),
    );
    final mentionState = ref.watch(mentionProviderInstance);
    final visible = mentionState.users.isNotEmpty;

    final selectable =
        useValueListenable(textEditingController).composing.composed && visible;

    final isGroupOrBot = ref.watch(
      conversationProvider.select(
        (value) => (value?.isGroup == true) || (value?.isBot == true),
      ),
    );

    return FocusableActionDetector(
      enabled: selectable,
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            const ListSelectionNextIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            const ListSelectionPrevIntent(),
        const SingleActivator(LogicalKeyboardKey.tab):
            const ListSelectionNextIntent(),
        const SingleActivator(LogicalKeyboardKey.enter):
            const ListSelectionSelectedIntent(),
        if (kPlatformIsDarwin) ...{
          const SingleActivator(LogicalKeyboardKey.keyN, control: true):
              const ListSelectionNextIntent(),
          const SingleActivator(LogicalKeyboardKey.keyP, control: true):
              const ListSelectionPrevIntent(),
        },
      },
      actions: {
        ListSelectionNextIntent: CallbackAction<Intent>(
          onInvoke: (intent) =>
              ref.read(mentionProviderInstance.notifier).next(),
        ),
        ListSelectionPrevIntent: CallbackAction<Intent>(
          onInvoke: (intent) =>
              ref.read(mentionProviderInstance.notifier).prev(),
        ),
        ListSelectionSelectedIntent: CallbackAction<Intent>(
          onInvoke: (intent) {
            final state = ref.read(mentionProviderInstance);
            _select(state.users[state.index]);
          },
        ),
      },
      child: PortalTarget(
        visible: visible && isGroupOrBot,
        anchor: const Aligned(
          follower: Alignment.bottomCenter,
          target: Alignment.topCenter,
        ),
        closeDuration: const Duration(milliseconds: 150),
        portalFollower: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: kMentionItemHeight * 4,
            minWidth: constraints.maxWidth,
            maxWidth: constraints.maxWidth,
          ),
          child: ClipRRect(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              tween: Tween(begin: 0, end: visible ? 1 : 0),
              builder: (context, progress, child) => FractionalTranslation(
                translation: Offset(0, 1 - progress),
                child: child,
              ),
              child: _MentionPanel(
                mentionState: mentionState,
                scrollController: scrollController,
                onSelect: _select,
              ),
            ),
          ),
        ),
        child: child,
      ),
    );
  }

  void _select(User user) {
    final selectionOffset = max(textEditingController.selection.baseOffset, 0);
    final text = textEditingController.text;

    final beforeSelectionOffset = text
        .substring(0, selectionOffset)
        .replaceFirst(mentionRegExp, '@${user.identityNumber} ');
    final afterSelectionOffset = text.substring(selectionOffset, text.length);

    final newText = beforeSelectionOffset + afterSelectionOffset;

    textEditingController
      ..text = newText
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: beforeSelectionOffset.length),
      );
  }
}

class _MentionPanel extends StatelessWidget {
  const _MentionPanel({
    required this.mentionState,
    required this.onSelect,
    required this.scrollController,
  });

  final MentionState mentionState;
  final Function(User user) onSelect;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: context.theme.popUp),
    child: ListView.builder(
      controller: scrollController,
      itemCount: mentionState.users.length,
      shrinkWrap: true,
      itemBuilder: (context, index) => _MentionItem(
        user: mentionState.users[index],
        keyword: mentionState.text,
        selected: mentionState.index == index,
        onSelect: onSelect,
      ),
    ),
  );
}

class _MentionItem extends StatelessWidget {
  const _MentionItem({
    required this.user,
    this.keyword,
    this.selected = false,
    this.onSelect,
  });

  final User user;
  final String? keyword;
  final bool selected;
  final Function(User user)? onSelect;

  @override
  Widget build(BuildContext context) => InteractiveDecoratedBox.color(
    decoration: selected
        ? BoxDecoration(color: context.theme.listSelected)
        : null,
    onTap: () => onSelect?.call(user),
    child: Container(
      height: kMentionItemHeight,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          AvatarWidget(
            userId: user.userId,
            name: user.fullName,
            avatarUrl: user.avatarUrl,
            size: 32,
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                user.fullName ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: context.theme.text,
                  height: 1,
                ),
                textMatchers: [
                  EmojiTextMatcher(),
                  if (keyword != null && keyword!.trim().isNotEmpty)
                    MultiKeyWordTextMatcher.createKeywordMatcher(
                      keyword: keyword!,
                      style: TextStyle(color: context.theme.accent),
                      caseSensitive: false,
                    ),
                ],
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              CustomText(
                user.identityNumber,
                style: TextStyle(
                  fontSize: 12,
                  color: context.theme.secondaryText,
                ),
                textMatchers: [
                  EmojiTextMatcher(),
                  if (keyword != null && keyword!.trim().isNotEmpty)
                    MultiKeyWordTextMatcher.createKeywordMatcher(
                      keyword: keyword!,
                      style: TextStyle(color: context.theme.accent),
                      caseSensitive: false,
                    ),
                ],
                maxLines: 1,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
