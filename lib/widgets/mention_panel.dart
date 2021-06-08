import 'dart:io';

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
import '../utils/hook.dart';
import '../utils/reg_exp_utils.dart';
import '../utils/text_utils.dart';
import 'avatar_view/avatar_view.dart';
import 'brightness_observer.dart';
import 'high_light_text.dart';
import 'interacter_decorated_box.dart';

const kMentionItemHeight = 48.0;

class MentionPanelPortalEntry extends HookWidget {
  const MentionPanelPortalEntry({
    Key? key,
    required this.constraints,
    required this.child,
  }) : super(key: key);

  final BoxConstraints constraints;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final visible = useBlocStateConverter<MentionCubit, MentionState, bool>(
      converter: (state) => state.users.isNotEmpty,
    );

    final selectable = useValueListenable(context.read<TextEditingController>())
            .composing
            .composed &&
        visible;

    final isGroup =
        useBlocStateConverter<ConversationCubit, ConversationState?, bool>(
      converter: (state) => state?.isGroup ?? false,
    );

    return FocusableActionDetector(
      shortcuts: selectable
          ? {
              LogicalKeySet(LogicalKeyboardKey.arrowDown):
                  const _ListSelectionNextIntent(),
              LogicalKeySet(LogicalKeyboardKey.arrowUp):
                  const _ListSelectionPrevIntent(),
              LogicalKeySet(LogicalKeyboardKey.tab):
                  const _ListSelectionNextIntent(),
              LogicalKeySet(LogicalKeyboardKey.enter):
                  const _ListSelectionSelectedIntent(),
              if (Platform.isMacOS) ...{
                LogicalKeySet(
                        LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
                    const _ListSelectionNextIntent(),
                LogicalKeySet(
                        LogicalKeyboardKey.control, LogicalKeyboardKey.keyP):
                    const _ListSelectionPrevIntent(),
              }
            }
          : const {},
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
                mentionCubit: BlocProvider.of<MentionCubit>(context),
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
    final textEditingController = context.read<TextEditingController>();
    textEditingController
      ..text = textEditingController.text
          .replaceFirst(mentionRegExp, '@${user.identityNumber} ')
      ..selection = TextSelection.fromPosition(
        TextPosition(
          offset: textEditingController.text.length,
        ),
      );
  }
}

class _MentionPanel extends StatelessWidget {
  const _MentionPanel({
    Key? key,
    required this.mentionCubit,
    required this.onSelect,
  }) : super(key: key);

  final MentionCubit mentionCubit;
  final Function(User user) onSelect;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: BrightnessData.themeOf(context).popUp,
        ),
        child: BlocBuilder<MentionCubit, MentionState>(
          buildWhen: (a, b) => b.users.isNotEmpty == true,
          bloc: mentionCubit,
          builder: (context, MentionState state) => ListView.builder(
            controller: context.read<MentionCubit>().scrollController,
            itemCount: state.users.length,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, int index) => _MentionItem(
              user: state.users[index],
              keyword: state.text,
              selected: state.index == index,
              onSelect: onSelect,
            ),
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
        decoration: BoxDecoration(
          color: selected
              ? BrightnessData.themeOf(context).listSelected
              : Colors.transparent,
        ),
        onTap: () => onSelect?.call(user),
        child: Container(
          height: kMentionItemHeight,
          padding: const EdgeInsets.all(8.0),
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
                      color: BrightnessData.themeOf(context).text,
                      height: 1,
                    ),
                    highlightTextSpans: [
                      HighlightTextSpan(
                        keyword ?? '',
                        style: TextStyle(
                          color: BrightnessData.themeOf(context).accent,
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
                      color: BrightnessData.themeOf(context).secondaryText,
                    ),
                    highlightTextSpans: [
                      HighlightTextSpan(
                        keyword ?? '',
                        style: TextStyle(
                          color: BrightnessData.themeOf(context).accent,
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
