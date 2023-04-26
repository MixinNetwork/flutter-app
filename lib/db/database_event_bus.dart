import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../utils/event_bus.dart';
import '../utils/logger.dart';
import 'dao/participant_dao.dart';
import 'event.dart';
import 'mixin_database.dart';

enum _DatabaseEvent {
  notification,
  insertOrReplaceMessage,
  deleteMessage,
  updateExpiredMessage,
  updateConversation,
  updateFavoriteApp,
  updateUser,
  updateParticipant,
  updateSticker,
  updateSnapshot,
  updateMessageMention,
  updateCircle,
  updateCircleConversation,
  updatePinMessage,
  updateTranscriptMessage,
  updateAsset
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
      .doOnData((e) {
        if (kDebugMode) {
          if (e.data is! T) {
            // ignore: avoid_dynamic_calls
            w('DatabaseEvent: event type is not match: ${e.data.runtimeType} != $T');
          }
        }
      })
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

  // user
  late Stream<Iterable<String>> updateUserIdsStream =
      _watch<List<String>>(_DatabaseEvent.updateUser);

  Stream<Iterable<String>> watchUpdateUserStream(List<String> userIds) =>
      updateUserIdsStream.where((event) => event.any(userIds.contains));

  void updateUsers(Iterable<String> userIds) {
    final newUserIds = userIds.where((id) {
      if (id.trim().isNotEmpty) return true;
      i('DatabaseEvent: insertOrReplaceUsers userId is empty: $id');
      return false;
    });

    if (newUserIds.isEmpty) {
      w('DatabaseEvent: insertOrReplaceUsers userIds is empty');
      return;
    }

    _send(_DatabaseEvent.updateUser, newUserIds);
  }

  // circle
  late Stream<void> updateCircleStream =
      _watch<void>(_DatabaseEvent.updateCircle);

  void updateCircle() => _sendEvent(_DatabaseEvent.updateCircle);

  // circleConversation
  late Stream<void> updateCircleConversationStream =
      _watch<void>(_DatabaseEvent.updateCircleConversation);

  void updateCircleConversation() =>
      _sendEvent(_DatabaseEvent.updateCircleConversation);

  // conversation
  late final Stream<Iterable<String>> updateConversationIdStream =
      _watch<List<String>>(_DatabaseEvent.updateConversation);

  Stream<Iterable<String>> watchUpdateConversationStream(
          List<String> conversationIds) =>
      updateConversationIdStream
          .where((event) => event.any(conversationIds.contains));

  void updateConversation(String conversationId) {
    if (conversationId.trim().isEmpty) {
      w('DatabaseEvent: insertOrReplaceConversation conversationId is empty');
      return;
    }
    _send(_DatabaseEvent.updateConversation, [conversationId]);
  }

  // participant
  late Stream<Iterable<MiniParticipantItem>> updateParticipantIdStream =
      _watch<List<MiniParticipantItem>>(_DatabaseEvent.updateParticipant);

  Stream<Iterable<MiniParticipantItem>> watchUpdateParticipantStream({
    List<String> conversationIds = const [],
    List<String> userIds = const [],
    bool and = false,
  }) =>
      updateParticipantIdStream.where((event) => event.any((element) {
            bool isContainConversationId() =>
                conversationIds.contains(element.conversationId);
            bool isContainUserId() => userIds.contains(element.userId);
            if (and) {
              return isContainConversationId() && isContainUserId();
            } else {
              return isContainConversationId() || isContainUserId();
            }
          }));

  void updateParticipant(Iterable<MiniParticipantItem> participants) {
    final newParticipants = participants.where((participant) {
      if (participant.conversationId.trim().isNotEmpty &&
          participant.userId.trim().isNotEmpty) return true;
      i('DatabaseEvent: updateParticipant participantId is empty');
      return false;
    });

    if (newParticipants.isEmpty) {
      w('DatabaseEvent: updateParticipant participantIds is empty');
      return;
    }
    _send(_DatabaseEvent.updateParticipant, newParticipants);
  }

  // message
  late Stream<Iterable<MiniMessageItem>> insertOrReplaceMessageIdsStream =
      _watch<List<MiniMessageItem>>(_DatabaseEvent.insertOrReplaceMessage);

  Stream<Iterable<MiniMessageItem>> watchInsertOrReplaceMessageIdsStream({
    List<String> conversationIds = const [],
    List<String> messageIds = const [],
    bool and = false,
  }) =>
      insertOrReplaceMessageIdsStream.where((event) => event.any((element) {
            bool isContainConversationId() =>
                conversationIds.contains(element.conversationId);
            bool isContainMessageId() => messageIds.contains(element.messageId);
            if (and) {
              return isContainConversationId() && isContainMessageId();
            } else {
              return isContainConversationId() || isContainMessageId();
            }
          }));

  void insertOrReplaceMessages(Iterable<MiniMessageItem> messageEvents) {
    final newMessageEvents = messageEvents.where((event) {
      if (event.messageId.trim().isNotEmpty &&
          event.conversationId.trim().isNotEmpty) return true;
      i('DatabaseEvent: insertOrReplaceMessages messageId or conversationId is empty: $event');
      return false;
    });

    if (newMessageEvents.isEmpty) {
      i('DatabaseEvent: insertOrReplaceMessages messageIds is empty');
      return;
    }
    _send(_DatabaseEvent.insertOrReplaceMessage, newMessageEvents);
  }

  late Stream<Iterable<String>> deleteMessageIdStream =
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

  late Stream<Iterable<MiniMessageItem>> updateMessageMentionStream =
      _watch<List<MiniMessageItem>>(_DatabaseEvent.updateMessageMention);

  Stream<Iterable<MiniMessageItem>> watchUpdateMessageMention({
    List<String> conversationIds = const [],
    List<String> messageIds = const [],
    bool and = false,
  }) =>
      updateMessageMentionStream.where((event) => event.any((element) {
            bool isContainConversationId() =>
                conversationIds.contains(element.conversationId);
            bool isContainMessageId() => messageIds.contains(element.messageId);
            if (and) {
              return isContainConversationId() && isContainMessageId();
            } else {
              return isContainConversationId() || isContainMessageId();
            }
          }));

  void updateMessageMention(List<MiniMessageItem> messageEvents) {
    final newMessageEvents = messageEvents.where((event) {
      if (event.messageId.trim().isNotEmpty &&
          event.conversationId.trim().isNotEmpty) return true;
      i('DatabaseEvent: insertOrReplaceMessages messageId or conversationId is empty: $event');
      return false;
    });

    if (newMessageEvents.isEmpty) {
      i('DatabaseEvent: insertOrReplaceMessages messageIds is empty');
      return;
    }
    _send(_DatabaseEvent.updateMessageMention, newMessageEvents);
  }

  // pinMessage
  late Stream<Iterable<MiniMessageItem>> updatePinMessageStream =
      _watch<List<MiniMessageItem>>(_DatabaseEvent.updatePinMessage);

  Stream<Iterable<MiniMessageItem>> watchPinMessageStream({
    List<String> conversationIds = const [],
    List<String> messageIds = const [],
    bool and = false,
  }) =>
      updatePinMessageStream.where((event) => event.any((element) {
            bool isContainConversationId() =>
                conversationIds.contains(element.conversationId);
            bool isContainMessageId() => messageIds.contains(element.messageId);
            if (and) {
              return isContainConversationId() && isContainMessageId();
            } else {
              return isContainConversationId() || isContainMessageId();
            }
          }));

  void updatePinMessage(Iterable<MiniMessageItem> messageEvent) {
    final newMessageEvents = messageEvent.where((event) {
      if (event.messageId.trim().isNotEmpty &&
          event.conversationId.trim().isNotEmpty) return true;
      i('DatabaseEvent: updatePinMessage messageId or conversationId is empty: $event');
      return false;
    });

    if (newMessageEvents.isEmpty) {
      i('DatabaseEvent: updatePinMessage messageIds is empty');
      return;
    }
    _send(_DatabaseEvent.updatePinMessage, newMessageEvents);
  }

  // transcriptMessage
  late Stream<Iterable<MiniTranscriptMessage>> updateTranscriptMessageStream =
      _watch<List<MiniTranscriptMessage>>(
          _DatabaseEvent.updateTranscriptMessage);

  Stream<Iterable<MiniTranscriptMessage>> watchUpdateTranscriptMessageStream({
    List<String> transcriptIds = const [],
    List<String> messageIds = const [],
    bool and = false,
  }) =>
      updateTranscriptMessageStream.where((event) => event.any((element) {
            bool isContainTranscriptId() =>
                transcriptIds.contains(element.transcriptId);
            bool isContainMessageId() => messageIds.contains(element.messageId);
            if (and) {
              return isContainTranscriptId() && isContainMessageId();
            } else {
              return isContainTranscriptId() || isContainMessageId();
            }
          }));

  void updateTranscriptMessage(Iterable<MiniTranscriptMessage> messageEvent) {
    final newMessageEvents = messageEvent.where((event) {
      if (event.transcriptId.trim().isNotEmpty) return true;
      i('DatabaseEvent: updateTranscriptMessage transcriptId is empty: $event');
      return false;
    });

    if (newMessageEvents.isEmpty) {
      i('DatabaseEvent: updateTranscriptMessage is empty');
      return;
    }
    _send(_DatabaseEvent.updateTranscriptMessage, newMessageEvents);
  }

  // expiredMessage
  late Stream<void> updateExpiredMessageTableStream =
      _watchEvent(_DatabaseEvent.updateExpiredMessage);

  void updateExpiredMessageTable() =>
      _sendEvent(_DatabaseEvent.updateExpiredMessage);

  // sticker

  late Stream<Iterable<MiniSticker>> updateStickerStream =
      _watch<List<MiniSticker>>(_DatabaseEvent.updateSticker);

  Stream<Iterable<MiniSticker>> watchUpdateStickerStream({
    List<String> stickerIds = const [],
    List<String> albumIds = const [],
    bool and = false,
  }) =>
      updateStickerStream.where((event) => event.any((element) {
            bool isContainStickerId() => stickerIds.contains(element.stickerId);
            bool isContainAlbumId() => albumIds.contains(element.albumId);
            if (and) {
              return isContainStickerId() && isContainAlbumId();
            } else {
              return isContainStickerId() || isContainAlbumId();
            }
          }));

  void updateSticker(Iterable<MiniSticker> miniStickers) {
    final newMiniStickers = miniStickers.where((element) =>
        (element.stickerId?.trim().isNotEmpty ?? false) ||
        (element.albumId?.trim().isNotEmpty ?? false));
    if (newMiniStickers.isEmpty) {
      w('DatabaseEvent: updateSticker miniStickers is empty');
      return;
    }
    _send(_DatabaseEvent.updateSticker, newMiniStickers.toList());
  }

  // app
  late Stream<Iterable<String>> updateAppIdStream =
      _watch<List<String>>(_DatabaseEvent.updateFavoriteApp);

  void updateFavoriteApp(Iterable<String> appIds) {
    final newAppIds = appIds.where((element) => element.trim().isNotEmpty);
    if (newAppIds.isEmpty) {
      w('DatabaseEvent: insertOrReplaceFavoriteApp appIds is empty');
      return;
    }
    _send(_DatabaseEvent.updateFavoriteApp, newAppIds);
  }

  // Snapshot
  late Stream<Iterable<String>> updateSnapshotStream =
      _watch<Iterable<String>>(_DatabaseEvent.updateSnapshot);

  void updateSnapshot(Iterable<String> snapshotIds) {
    final newSnapshotIds =
        snapshotIds.where((element) => element.trim().isNotEmpty);
    if (newSnapshotIds.isEmpty) {
      w('DatabaseEvent: updateSnapshot snapshotIds is empty');
      return;
    }
    _send(_DatabaseEvent.updateSnapshot, newSnapshotIds);
  }

  // Asset
  late Stream<Iterable<String>> updateAssetStream =
      _watch<Iterable<String>>(_DatabaseEvent.updateAsset);

  void updateAsset(Iterable<String> assetIds) {
    final newAssetIds = assetIds.where((element) => element.trim().isNotEmpty);
    if (newAssetIds.isEmpty) {
      w('DatabaseEvent: updateAsset assetIds is empty');
      return;
    }
    _send(_DatabaseEvent.updateAsset, newAssetIds);
  }
}
