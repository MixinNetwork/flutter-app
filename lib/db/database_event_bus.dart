import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../utils/event_bus.dart';
import '../utils/logger.dart';
import 'mixin_database.dart';

enum _DatabaseEvent {
  notification,
  insertOrReplaceMessage,
  deleteMessage,
  updateExpiredMessageTable,
  insertOrReplaceConversation,
  insertOrReplaceFavoriteApp,
}

class MiniNotificationMessage with EquatableMixin {
  MiniNotificationMessage({
    required this.conversationId,
    required this.messageId,
    this.senderId,
    this.createdAt,
    required this.type,
  });

  final String conversationId;
  final String messageId;
  final String? senderId;
  final DateTime? createdAt;
  final String type;

  @override
  List<Object?> get props => [
        conversationId,
        messageId,
        senderId,
        createdAt,
        type,
      ];
}

@immutable
class _DatabaseEventWrapper {
  const _DatabaseEventWrapper(this.type, this.data);

  final _DatabaseEvent type;
  final dynamic data;

  @override
  String toString() => 'DatabaseEvent{type: $type, data: $data}';
}

class DataBaseEventBus {
  DataBaseEventBus._();

  static DataBaseEventBus instance = DataBaseEventBus._();

  Stream<T> _watch<T>(_DatabaseEvent event) => EventBus.instance.on
      .whereType<_DatabaseEventWrapper>()
      .where((e) => event == e.type)
      .where((e) => e.data is T)
      .map((e) => e.data)
      .cast<T>();

  void _send<T>(_DatabaseEvent event, T value) =>
      EventBus.instance.fire(_DatabaseEventWrapper(event, value));

  Stream<_DatabaseEvent> _watchEvent(_DatabaseEvent event) =>
      EventBus.instance.on
          .whereType<_DatabaseEventWrapper>()
          .map((e) => e.type)
          .where((e) => e == event);

  void _sendEvent(_DatabaseEvent event) =>
      EventBus.instance.fire(_DatabaseEventWrapper(event, null));

  // conversation
  late Stream<List<String>> insertOrReplaceConversationIdStream =
      _watch<List<String>>(_DatabaseEvent.insertOrReplaceConversation);

  void insertOrReplaceConversation(String conversationId) {
    if (conversationId.trim().isEmpty) {
      w('DatabaseEvent: insertOrReplaceConversation conversationId is empty');
      return;
    }
    _send(_DatabaseEvent.insertOrReplaceConversation, [conversationId]);
  }

  // message

  late Stream<List<MiniMessageItem>> insertOrReplaceMessageIdsStream =
      _watch<List<MiniMessageItem>>(_DatabaseEvent.insertOrReplaceMessage);

  void insertOrReplaceMessages(Iterable<MiniMessageItem> messageEvents) {
    final newMessageEvents = messageEvents.where((event) {
      if (event.messageId.trim().isNotEmpty &&
          event.conversationId.trim().isNotEmpty) return true;
      i('DatabaseEvent: insertOrReplaceMessages messageId or conversationId is empty: $event');
      return false;
    }).toList();

    if (newMessageEvents.isEmpty) {
      i('DatabaseEvent: insertOrReplaceMessages messageIds is empty');
      return;
    }
    _send(_DatabaseEvent.insertOrReplaceMessage, newMessageEvents);
  }

  late Stream<List<String>> deleteMessageIdStream =
      _watch<List<String>>(_DatabaseEvent.deleteMessage);

  void deleteMessage(String messageId) {
    if (messageId.trim().isEmpty) {
      w('DatabaseEvent: deleteMessage messageId is empty');
      return;
    }
    _send(_DatabaseEvent.deleteMessage, [messageId]);
  }

  late Stream<MiniNotificationMessage> notificationMessageStream =
      _watch<MiniNotificationMessage>(_DatabaseEvent.notification);

  void notificationMessage(MiniNotificationMessage miniNotificationMessage) {
    if (miniNotificationMessage.messageId.trim().isEmpty ||
        miniNotificationMessage.conversationId.trim().isEmpty) {
      w('DatabaseEvent: notificationMessage messageId is empty');
      return;
    }
    _send(_DatabaseEvent.notification, miniNotificationMessage);
  }

  // expiredMessage
  late Stream<void> updateExpiredMessageTableStream =
      _watchEvent(_DatabaseEvent.updateExpiredMessageTable);

  void updateExpiredMessageTable() =>
      _sendEvent(_DatabaseEvent.updateExpiredMessageTable);

  // app
  late Stream<List<String>> insertOrReplaceFavoriteAppIdStream =
      _watch<List<String>>(_DatabaseEvent.insertOrReplaceFavoriteApp);

  void insertOrReplaceFavoriteApp(Iterable<String> appIds) {
    final newAppIds = appIds.where((element) => element.trim().isNotEmpty);
    if (newAppIds.isEmpty) {
      w('DatabaseEvent: insertOrReplaceFavoriteApp appIds is empty');
      return;
    }
    _send(_DatabaseEvent.insertOrReplaceFavoriteApp, newAppIds);
  }
}
