import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/extension/extension.dart';
import '../../../utils/platform.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/conversation_unseen_filter_enabled.dart';
import '../../provider/slide_category_provider.dart';

import '../../provider/unseen_conversations_provider.dart';
import '../bloc/conversation_list_bloc.dart';

class ConversationHotKey extends StatelessWidget {
  const ConversationHotKey({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    shortcuts: {
      SingleActivator(
        LogicalKeyboardKey.arrowDown,
        meta: kPlatformIsDarwin,
        control: !kPlatformIsDarwin,
      ): const NextConversationIntent(),
      SingleActivator(
        LogicalKeyboardKey.arrowUp,
        meta: kPlatformIsDarwin,
        control: !kPlatformIsDarwin,
      ): const PreviousConversationIntent(),
    },
    actions: {
      NextConversationIntent: CallbackAction<NextConversationIntent>(
        onInvoke: (_) => _navigationConversation(context, forward: true),
      ),
      PreviousConversationIntent: CallbackAction<PreviousConversationIntent>(
        onInvoke: (_) => _navigationConversation(context, forward: false),
      ),
    },
    child: child,
  );
}

class NextConversationIntent extends Intent {
  const NextConversationIntent();
}

class PreviousConversationIntent extends Intent {
  const PreviousConversationIntent();
}

void _navigationConversation(BuildContext context, {required bool forward}) {
  final category = context.providerContainer.read(slideCategoryStateProvider);
  final conversationListBloc = context.read<ConversationListBloc>();

  if (category.type == SlideCategoryType.setting) return;

  final currentConversationId = context.providerContainer.read(
    currentConversationIdProvider,
  );
  if (currentConversationId == null) return;

  final conversationUnseenFilterEnabled = context.providerContainer.read(
    conversationUnseenFilterEnabledProvider,
  );

  String nextConversationId;
  int? nextConversationIndex;
  if (conversationUnseenFilterEnabled) {
    final unseenConversations = context.providerContainer.read(
      unseenConversationsProvider,
    );
    final index = unseenConversations?.indexWhere(
      (element) => element.conversationId == currentConversationId,
    );

    if (index == null || index == -1) return;

    final nextIndex = forward ? index + 1 : index - 1;

    if (nextIndex < 0 || nextIndex >= unseenConversations!.length) return;

    nextConversationId = unseenConversations[nextIndex].conversationId;
  } else {
    var currentConversationIndex = -1;
    conversationListBloc.state.map.forEach((key, value) {
      if (value.conversationId == currentConversationId) {
        currentConversationIndex = key;
      }
    });

    if (currentConversationIndex == -1) return;

    nextConversationIndex = forward
        ? currentConversationIndex + 1
        : currentConversationIndex - 1;

    final nextConversation =
        conversationListBloc.state.map[nextConversationIndex];
    if (nextConversation == null) return;
    nextConversationId = nextConversation.conversationId;
  }

  ConversationStateNotifier.selectConversation(context, nextConversationId);

  if (nextConversationIndex == null) return;

  final itemPositions = conversationListBloc
      .itemPositionsListener(category)
      ?.itemPositions
      .value;

  if (itemPositions == null) return;

  // use 0.9 instead 1 to ensure that the next conversation is visible if we forward.
  // in forward navigation, if alignment is 1, ScrollablePositionedList will only
  // show current conversation at the end, not the next one.
  const trailingEdge = 0.9;

  for (final position in itemPositions) {
    if (position.index == nextConversationIndex) {
      if (position.itemLeadingEdge > 0 &&
          position.itemTrailingEdge < trailingEdge) {
        // in viewport, do not need scroll.
        // https://github.com/google/flutter.widgets/issues/276
        return;
      }
      break;
    }
  }
  final itemScrollController = conversationListBloc.itemScrollController(
    category,
  );
  if (itemScrollController == null) return;
  if (itemScrollController.isAttached) {
    itemScrollController.jumpTo(
      index: nextConversationIndex,
      alignment: forward ? trailingEdge : 0,
    );
  }
}
