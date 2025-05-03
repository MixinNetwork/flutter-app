import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../db/extension/message.dart';
import '../../db/mixin_database.dart';
import 'conversation_provider.dart';

class MessageSelectionNotifier extends ChangeNotifier {
  MessageSelectionNotifier();

  final Set<String> _selectedMessageIds = {};
  final Set<String> _messageCannotForward = {};
  final Set<String> _messageCannotRecall = {};

  bool get hasSelectedMessage => _selectedMessageIds.isNotEmpty;

  Set<String> get selectedMessageIds => _selectedMessageIds.toSet();

  bool get canForward =>
      _messageCannotForward.isEmpty && _selectedMessageIds.length < 100;

  bool get canRecall =>
      _messageCannotRecall.isEmpty && _selectedMessageIds.length < 100;

  void selectMessage(MessageItem message) {
    _selectedMessageIds.add(message.messageId);
    if (!message.canForward) {
      _messageCannotForward.add(message.messageId);
    }
    if (!message.canRecall) {
      _messageCannotRecall.add(message.messageId);
    }

    notifyListeners();
  }

  void toggleSelection(MessageItem message) {
    final messageId = message.messageId;

    if (_selectedMessageIds.remove(messageId)) {
      _messageCannotForward.remove(messageId);
      _messageCannotRecall.remove(messageId);
    } else {
      _selectedMessageIds.add(messageId);
      if (!message.canForward) {
        _messageCannotForward.add(message.messageId);
      }
      if (!message.canRecall) {
        _messageCannotRecall.add(message.messageId);
      }
    }

    notifyListeners();
  }

  void clearSelection() {
    _selectedMessageIds.clear();
    _messageCannotForward.clear();
    _messageCannotRecall.clear();

    notifyListeners();
  }
}

final messageSelectionProvider = ChangeNotifierProvider.autoDispose((ref) {
  ref.watch(currentConversationIdProvider);
  return MessageSelectionNotifier();
});

final hasSelectedMessageProvider = messageSelectionProvider.select(
  (value) => value.hasSelectedMessage,
);
