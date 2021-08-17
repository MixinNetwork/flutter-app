import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:provider/provider.dart';

import '../db/mixin_database.dart' hide Offset;
import '../ui/home/bloc/conversation_cubit.dart';
import '../ui/home/bloc/mention_cubit.dart';
import '../utils/extension/extension.dart';
import '../utils/hook.dart';
import '../utils/platform.dart';
import '../utils/reg_exp_utils.dart';
import 'avatar_view/avatar_view.dart';

import 'high_light_text.dart';
import 'interacter_decorated_box.dart';

const kMentionItemHeight = 48.0;

class MentionPanelPortalEntry extends HookWidget {
  const MentionPanelPortalEntry({
    Key? key,
    required this.constraints,
    required this.textEditingController,
    required this.child,
  }) : super(key: key);

  final BoxConstraints constraints;
  final TextEditingController textEditingController;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final visible = useBlocStateConverter<MentionCubit, MentionState, bool>(
      converter: (state) => state.users.isNotEmpty,
    );

    final selectable =
        useValueListenable(textEditingController).composing.composed && visible;

    final isGroup =
        useBlocStateConverter<ConversationCubit, ConversationState?, bool>(
      converter: (state) => state?.isGroup ?? false,
    );

    final mentionState = useBlocState<MentionCubit, MentionState>(
      when: (state) => state.users.isNotEmpty,
    );

    return FocusableActionDetector(
      enabled: selectable,
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            const _ListSelectionNextIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            const _ListSelectionPrevIntent(),
        const SingleActivator(LogicalKeyboardKey.tab):
            const _ListSelectionNextIntent(),
        const SingleActivator(LogicalKeyboardKey.enter):
            const _ListSelectionSelectedIntent(),
        if (kPlatformIsDarwin) ...{
          const SingleActivator(
            LogicalKeyboardKey.keyN,
            control: true,
          ): const _ListSelectionNextIntent(),
          const SingleActivator(
            LogicalKeyboardKey.keyP,
            control: true,
          ): const _ListSelectionPrevIntent(),
        }
      },
      actions: {
        _ListSelectionNextIntent: CallbackAction<Intent>(
          onInvoke: (Intent intent) => context.read<MentionCubit>().next(),
        ),
        _ListSelectionPrevIntent: CallbackAction<Intent>(
          onInvoke: (Intent intent) => context.read<MentionCubit>().prev(),
        ),
        _ListSelectionSelectedIntent: CallbackAction<Intent>(
          onInvoke: (Intent intent) {
            final state = context.read<MentionCubit>().state;
            _select(context, state.users[state.index]);
          },
        ),
      },
      child: PortalEntry(
        visible: visible && isGroup,
        childAnchor: Alignment.topCenter,
        portalAnchor: Alignment.bottomCenter,
        closeDuration: const Duration(milliseconds: 150),
        portal: ConstrainedBox(
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
                onSelect: (User user) => _select(context, user),
              ),
            ),
          ),
        ),
        child: child,
      ),
    );
  }

  void _select(BuildContext context, User user) {
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
        TextPosition(
          offset: beforeSelectionOffset.length,
        ),
      );
  }
}

class _MentionPanel extends StatelessWidget {
  const _MentionPanel({
    Key? key,
    required this.mentionState,
    required this.onSelect,
  }) : super(key: key);

  final MentionState mentionState;
  final Function(User user) onSelect;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: context.theme.popUp,
        ),
        child: ListView.builder(
          controller: context.read<MentionCubit>().scrollController,
          itemCount: mentionState.users.length,
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) => _MentionItem(
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
    Key? key,
    required this.user,
    this.keyword,
    this.selected = false,
    this.onSelect,
  }) : super(key: key);

  final User user;
  final String? keyword;
  final bool selected;
  final Function(User user)? onSelect;

  @override
  Widget build(BuildContext context) => InteractableDecoratedBox.color(
        decoration:
            selected ? BoxDecoration(color: context.theme.listSelected) : null,
        onTap: () => onSelect?.call(user),
        child: Container(
          height: kMentionItemHeight,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              AvatarWidget(
                userId: user.userId,
                name: user.fullName!,
                avatarUrl: user.avatarUrl,
                size: 32,
              ),
              const SizedBox(width: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HighlightText(
                    user.fullName ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.theme.text,
                      height: 1,
                    ),
                    highlightTextSpans: [
                      HighlightTextSpan(
                        keyword ?? '',
                        style: TextStyle(
                          color: context.theme.accent,
                        ),
                      ),
                    ],
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  HighlightText(
                    user.identityNumber,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.theme.secondaryText,
                    ),
                    highlightTextSpans: [
                      HighlightTextSpan(
                        keyword ?? '',
                        style: TextStyle(
                          color: context.theme.accent,
                        ),
                      )
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

class _ListSelectionNextIntent extends Intent {
  const _ListSelectionNextIntent();
}

class _ListSelectionPrevIntent extends Intent {
  const _ListSelectionPrevIntent();
}

class _ListSelectionSelectedIntent extends Intent {
  const _ListSelectionSelectedIntent();
}
