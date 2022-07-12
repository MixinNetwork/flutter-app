import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../bloc/subscribe_mixin.dart';

class MessageSelectionState with EquatableMixin {
  const MessageSelectionState({
    required this.selectedMessageIds,
  });

  final Set<String> selectedMessageIds;

  bool get hasSelectedMessage => selectedMessageIds.isNotEmpty;

  @override
  List<Object?> get props => [selectedMessageIds];
}

class MessageSelectionCubit extends Cubit<MessageSelectionState>
    with SubscribeMixin {
  MessageSelectionCubit()
      : super(const MessageSelectionState(selectedMessageIds: {}));

  final Set<String> _selectedMessageIds = {};

  void selectMessage(String messageId) {
    _selectedMessageIds.add(messageId);
    emit(MessageSelectionState(
      selectedMessageIds: _selectedMessageIds.toSet(),
    ));
  }

  void toggleSelection(String messageId) {
    if (_selectedMessageIds.contains(messageId)) {
      _selectedMessageIds.remove(messageId);
    } else {
      _selectedMessageIds.add(messageId);
    }
    emit(MessageSelectionState(
      selectedMessageIds: _selectedMessageIds.toSet(),
    ));
  }

  void clearSelection() {
    _selectedMessageIds.clear();
    emit(MessageSelectionState(
      selectedMessageIds: _selectedMessageIds.toSet(),
    ));
  }
}
