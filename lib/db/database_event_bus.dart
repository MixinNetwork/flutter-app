import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../utils/event_bus.dart';
import '../utils/logger.dart';
import 'mixin_database.dart';

enum DatabaseEvent {
  notification,
  insertOrReplaceMessage,
  deleteMessage,
  updateExpiredMessageTable,
  insertOrReplaceConversation,
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

  final DatabaseEvent type;
  final dynamic data;

  @override
  String toString() => 'DatabaseEvent{type: $type, data: $data}';
}

class DataBaseEventBus {
  DataBaseEventBus._();

  static DataBaseEventBus instance = DataBaseEventBus._();

  Stream<T> watch<T>(DatabaseEvent event) => EventBus.instance.on
      .whereType<_DatabaseEventWrapper>()
      .where((e) => event == e.type)
      .where((e) => e.data is T)
      .map((e) => e.data)
      .cast<T>();

  void send<T>(DatabaseEvent event, T value) =>
      EventBus.instance.fire(_DatabaseEventWrapper(event, value));

  Stream<DatabaseEvent> watchEvent(DatabaseEvent event) => EventBus.instance.on
      .whereType<_DatabaseEventWrapper>()
      .map((e) => e.type)
      .where((e) => e == event);

  void sendEvent(DatabaseEvent event) =>
      EventBus.instance.fire(_DatabaseEventWrapper(event, null));

  // conversation
  late Stream<List<String>> insertOrReplaceConversationIdStream =
      watch<List<String>>(DatabaseEvent.insertOrReplaceConversation);

  void insertOrReplaceConversation(String conversationId) {
    if (conversationId.trim().isEmpty) {
      w('DatabaseEvent: insertOrReplaceConversation conversationId is empty');
      return;
    }
    send(DatabaseEvent.insertOrReplaceConversation, [conversationId]);
  }

  // message

  late Stream<List<MiniMessageItem>> insertOrReplaceMessageIdsStream =
      watch<List<MiniMessageItem>>(DatabaseEvent.insertOrReplaceMessage);

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
    send(DatabaseEvent.insertOrReplaceMessage, newMessageEvents);
  }

  late Stream<List<String>> deleteMessageIdStream =
      watch<List<String>>(DatabaseEvent.deleteMessage);

  void deleteMessage(String messageId) {
    if (messageId.trim().isEmpty) {
      w('DatabaseEvent: deleteMessage messageId is empty');
      return;
    }
    send(DatabaseEvent.deleteMessage, [messageId]);
  }

  late Stream<MiniNotificationMessage> notificationMessageStream =
      watch<MiniNotificationMessage>(DatabaseEvent.notification);

  void notificationMessage(MiniNotificationMessage miniNotificationMessage) {
    if (miniNotificationMessage.messageId.trim().isEmpty ||
        miniNotificationMessage.conversationId.trim().isEmpty) {
      w('DatabaseEvent: notificationMessage messageId is empty');
      return;
    }
    send(DatabaseEvent.notification, miniNotificationMessage);
  }
}
