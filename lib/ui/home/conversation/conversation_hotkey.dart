import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/extension/extension.dart';
import '../../../utils/platform.dart';
import '../bloc/conversation_cubit.dart';
import '../bloc/conversation_list_bloc.dart';
import '../bloc/slide_category_cubit.dart';

class ConversationHotKey extends StatelessWidget {
  const ConversationHotKey({
    super.key,
    required this.child,
  });

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
          PreviousConversationIntent:
              CallbackAction<PreviousConversationIntent>(
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

void _navigationConversation(
  BuildContext context, {
  required bool forward,
}) {
  final category = context.read<SlideCategoryCubit>().state;
  if (category.type == SlideCategoryType.setting) {
    return;
  }
  final conversationCubit = context.read<ConversationCubit>();
  final currentConversation = conversationCubit.state?.conversationId;
  if (currentConversation == null) {
    return;
  }
  final conversationListBloc = context.read<ConversationListBloc>();
  var currentConversationIndex = -1;
  conversationListBloc.state.map.forEach((key, value) {
    if (value.conversationId == currentConversation) {
      currentConversationIndex = key;
    }
  });
  if (currentConversationIndex == -1) {
    return;
  }

  final nextConversationIndex =
      forward ? currentConversationIndex + 1 : currentConversationIndex - 1;

  final nextConversation =
      conversationListBloc.state.map[nextConversationIndex];
  if (nextConversation == null) {
    return;
  }
  ConversationCubit.selectConversation(
    context,
    nextConversation.conversationId,
  );
  final itemPositions =
      conversationListBloc.itemPositionsListener(category).itemPositions.value;

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
  conversationListBloc.itemScrollController(category).jumpTo(
        index: nextConversationIndex,
        alignment: forward ? trailingEdge : 0,
      );
}
