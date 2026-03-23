import 'package:equatable/equatable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../db/extension/message.dart';
import '../../db/extension/message_category.dart';
import '../../db/mixin_database.dart';
import 'conversation_provider.dart';

class MessageSelectionState extends Equatable {
  const MessageSelectionState({
    this.selectedMessageIds = const <String>{},
    this.messageCannotForward = const <String>{},
    this.messageCannotRecall = const <String>{},
    this.messageCannotCombineForward = const <String>{},
  });

  final Set<String> selectedMessageIds;
  final Set<String> messageCannotForward;
  final Set<String> messageCannotRecall;
  final Set<String> messageCannotCombineForward;

  bool get hasSelectedMessage => selectedMessageIds.isNotEmpty;

  bool get canForward =>
      messageCannotForward.isEmpty && selectedMessageIds.length < 100;

  bool get canCombineForward =>
      messageCannotCombineForward.isEmpty &&
      selectedMessageIds.length >= 2 &&
      selectedMessageIds.length < 100;

  bool get canRecall =>
      messageCannotRecall.isEmpty && selectedMessageIds.length < 100;

  MessageSelectionState copyWith({
    Set<String>? selectedMessageIds,
    Set<String>? messageCannotForward,
    Set<String>? messageCannotRecall,
    Set<String>? messageCannotCombineForward,
  }) => MessageSelectionState(
    selectedMessageIds: selectedMessageIds ?? this.selectedMessageIds,
    messageCannotForward: messageCannotForward ?? this.messageCannotForward,
    messageCannotRecall: messageCannotRecall ?? this.messageCannotRecall,
    messageCannotCombineForward:
        messageCannotCombineForward ?? this.messageCannotCombineForward,
  );

  @override
  List<Object?> get props => [
    selectedMessageIds,
    messageCannotForward,
    messageCannotRecall,
    messageCannotCombineForward,
  ];
}

class MessageSelectionNotifier extends Notifier<MessageSelectionState> {
  @override
  MessageSelectionState build() {
    ref.watch(currentConversationIdProvider);
    return const MessageSelectionState();
  }

  void selectMessage(MessageItem message) {
    state = _addMessage(message);
  }

  void toggleSelection(MessageItem message) {
    final messageId = message.messageId;
    if (state.selectedMessageIds.contains(messageId)) {
      state = state.copyWith(
        selectedMessageIds: {...state.selectedMessageIds}..remove(messageId),
        messageCannotForward: {...state.messageCannotForward}
          ..remove(messageId),
        messageCannotRecall: {...state.messageCannotRecall}..remove(messageId),
        messageCannotCombineForward: {...state.messageCannotCombineForward}
          ..remove(messageId),
      );
      return;
    }
    state = _addMessage(message);
  }

  void clearSelection() {
    state = const MessageSelectionState();
  }

  MessageSelectionState _addMessage(MessageItem message) {
    final selectedMessageIds = {...state.selectedMessageIds}
      ..add(message.messageId);
    final messageCannotForward = {...state.messageCannotForward};
    final messageCannotRecall = {...state.messageCannotRecall};
    final messageCannotCombineForward = {...state.messageCannotCombineForward};

    if (!message.canForward) {
      messageCannotForward.add(message.messageId);
      messageCannotCombineForward.add(message.messageId);
    }
    if (!message.canRecall) {
      messageCannotRecall.add(message.messageId);
    }
    if (message.type.isTranscript) {
      messageCannotCombineForward.add(message.messageId);
    }

    return state.copyWith(
      selectedMessageIds: selectedMessageIds,
      messageCannotForward: messageCannotForward,
      messageCannotRecall: messageCannotRecall,
      messageCannotCombineForward: messageCannotCombineForward,
    );
  }
}

final messageSelectionProvider =
    NotifierProvider.autoDispose<
      MessageSelectionNotifier,
      MessageSelectionState
    >(
      MessageSelectionNotifier.new,
    );

final hasSelectedMessageProvider = messageSelectionProvider.select(
  (value) => value.hasSelectedMessage,
);
