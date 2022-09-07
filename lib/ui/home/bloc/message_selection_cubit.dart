import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../bloc/subscribe_mixin.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/extension/extension.dart';

class MessageSelectionState with EquatableMixin {
  const MessageSelectionState({
    required this.selectedMessageIds,
    required this.canForward,
  });

  final Set<String> selectedMessageIds;

  bool get hasSelectedMessage => selectedMessageIds.isNotEmpty;

  final bool canForward;

  @override
  List<Object?> get props => [selectedMessageIds, canForward];
}

class MessageSelectionCubit extends Cubit<MessageSelectionState>
    with SubscribeMixin {
  MessageSelectionCubit()
      : super(const MessageSelectionState(
          selectedMessageIds: {},
          canForward: true,
        ));

  final Set<String> _selectedMessageIds = {};
  final Set<String> _messageCannotForward = {};

  void selectMessage(MessageItem message) {
    _selectedMessageIds.add(message.messageId);
    if (!message.canForward) {
      _messageCannotForward.add(message.messageId);
    }
    _notify();
  }

  void toggleSelection(MessageItem message) {
    final messageId = message.messageId;
    if (_selectedMessageIds.contains(messageId)) {
      _selectedMessageIds.remove(messageId);
      _messageCannotForward.remove(messageId);
    } else {
      _selectedMessageIds.add(messageId);
      if (!message.canForward) {
        _messageCannotForward.add(message.messageId);
      }
    }
    _notify();
  }

  void clearSelection() {
    _selectedMessageIds.clear();
    _messageCannotForward.clear();
    _notify();
  }

  void _notify() {
    emit(MessageSelectionState(
      selectedMessageIds: _selectedMessageIds.toSet(),
      canForward:
          _messageCannotForward.isEmpty && _selectedMessageIds.length < 100,
    ));
  }
}
