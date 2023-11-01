import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../utils/event_bus.dart';
import '../utils/logger.dart';
import 'dao/job_dao.dart';
import 'dao/message_dao.dart';
import 'dao/participant_dao.dart';
import 'event.dart';

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
  updateAsset,
  updateToken,
  addJob,
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
      .map((e) {
        if (kDebugMode && e.data is! T) {
          // ignore: avoid_dynamic_calls
          w('DatabaseEvent: event type is not match: ${e.data.runtimeType} != $T');
        }
        return e;
      })
      .where((e) => e.data is T)
      .map((e) => e.data)
      .cast<T>();

  void _send<T>(_DatabaseEvent event, T value) {
    if (kDebugMode && T.toString().startsWith('Iterable')) {
      w('DatabaseEvent: send iterable is not safe: $T');
    }
    EventBus.instance.fire(_DatabaseEventWrapper(event, value));
  }

  Stream<_DatabaseEvent> _watchEvent(_DatabaseEvent event) =>
      EventBus.instance.on
          .whereType<_DatabaseEventWrapper>()
          .map((e) => e.type)
          .where((e) => e == event);

  void _sendEvent(_DatabaseEvent event) =>
      EventBus.instance.fire(_DatabaseEventWrapper(event, null));

  // user
  late Stream<List<String>> updateUserIdsStream =
      _watch<List<String>>(_DatabaseEvent.updateUser);

  Stream<List<String>> watchUpdateUserStream(Iterable<String> userIds) =>
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

    _send(_DatabaseEvent.updateUser, newUserIds.toList());
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
  late final Stream<List<String>> updateConversationIdStream =
      _watch<List<String>>(_DatabaseEvent.updateConversation);

  Stream<List<String>> watchUpdateConversationStream(
          Iterable<String> conversationIds) =>
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
  late Stream<List<MiniParticipantItem>> updateParticipantIdStream =
      _watch<List<MiniParticipantItem>>(_DatabaseEvent.updateParticipant);

  Stream<List<MiniParticipantItem>> watchUpdateParticipantStream({
    Iterable<String> conversationIds = const [],
    Iterable<String> userIds = const [],
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
    _send(_DatabaseEvent.updateParticipant, newParticipants.toList());
  }

  // message
  late Stream<List<MiniMessageItem>> insertOrReplaceMessageIdsStream =
      _watch<List<MiniMessageItem>>(_DatabaseEvent.insertOrReplaceMessage);

  Stream<List<MiniMessageItem>> watchInsertOrReplaceMessageIdsStream({
    Iterable<String> conversationIds = const [],
    Iterable<String> messageIds = const [],
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
    _send(_DatabaseEvent.insertOrReplaceMessage, newMessageEvents.toList());
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

  late Stream<List<MiniMessageItem>> updateMessageMentionStream =
      _watch<List<MiniMessageItem>>(_DatabaseEvent.updateMessageMention);

  Stream<List<MiniMessageItem>> watchUpdateMessageMention({
    Iterable<String> conversationIds = const [],
    Iterable<String> messageIds = const [],
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

  void updateMessageMention(Iterable<MiniMessageItem> messageEvents) {
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
    _send(_DatabaseEvent.updateMessageMention, newMessageEvents.toList());
  }

  // pinMessage
  late Stream<List<MiniMessageItem>> updatePinMessageStream =
      _watch<List<MiniMessageItem>>(_DatabaseEvent.updatePinMessage);

  Stream<List<MiniMessageItem>> watchPinMessageStream({
    Iterable<String> conversationIds = const [],
    Iterable<String> messageIds = const [],
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
    _send(_DatabaseEvent.updatePinMessage, newMessageEvents.toList());
  }

  // transcriptMessage
  late Stream<List<MiniTranscriptMessage>> updateTranscriptMessageStream =
      _watch<List<MiniTranscriptMessage>>(
          _DatabaseEvent.updateTranscriptMessage);

  Stream<List<MiniTranscriptMessage>> watchUpdateTranscriptMessageStream({
    Iterable<String> transcriptIds = const [],
    Iterable<String> messageIds = const [],
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
    _send(_DatabaseEvent.updateTranscriptMessage, newMessageEvents.toList());
  }

  // expiredMessage
  late Stream<void> updateExpiredMessageTableStream =
      _watchEvent(_DatabaseEvent.updateExpiredMessage);

  void updateExpiredMessageTable() =>
      _sendEvent(_DatabaseEvent.updateExpiredMessage);

  // sticker

  late Stream<List<MiniSticker>> updateStickerStream =
      _watch<List<MiniSticker>>(_DatabaseEvent.updateSticker);

  Stream<List<MiniSticker>> watchUpdateStickerStream({
    Iterable<String> stickerIds = const [],
    Iterable<String> albumIds = const [],
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
  late Stream<List<String>> updateAppIdStream =
      _watch<List<String>>(_DatabaseEvent.updateFavoriteApp);

  void updateFavoriteApp(Iterable<String> appIds) {
    final newAppIds = appIds.where((element) => element.trim().isNotEmpty);
    if (newAppIds.isEmpty) {
      w('DatabaseEvent: insertOrReplaceFavoriteApp appIds is empty');
      return;
    }
    _send(_DatabaseEvent.updateFavoriteApp, newAppIds.toList());
  }

  // Snapshot
  late Stream<List<String>> updateSnapshotStream =
      _watch<List<String>>(_DatabaseEvent.updateSnapshot);

  void updateSnapshot(Iterable<String> snapshotIds) {
    final newSnapshotIds =
        snapshotIds.where((element) => element.trim().isNotEmpty);
    if (newSnapshotIds.isEmpty) {
      w('DatabaseEvent: updateSnapshot snapshotIds is empty');
      return;
    }
    _send(_DatabaseEvent.updateSnapshot, newSnapshotIds.toList());
  }

  // Asset
  late Stream<List<String>> updateAssetStream =
      _watch<List<String>>(_DatabaseEvent.updateAsset);

  void updateAsset(Iterable<String> assetIds) {
    final newAssetIds = assetIds.where((element) => element.trim().isNotEmpty);
    if (newAssetIds.isEmpty) {
      w('DatabaseEvent: updateAsset assetIds is empty');
      return;
    }
    _send(_DatabaseEvent.updateAsset, newAssetIds.toList());
  }

  // Token
  late Stream<List<String>> updateTokenStream =
      _watch<List<String>>(_DatabaseEvent.updateToken);

  void updateToken(Iterable<String> tokenIds) {
    final newTokenIds = tokenIds.where((element) => element.trim().isNotEmpty);
    if (newTokenIds.isEmpty) {
      w('DatabaseEvent: updateToken tokenIds is empty');
      return;
    }
    _send(_DatabaseEvent.updateToken, newTokenIds.toList());
  }

  // Job
  late Stream<MiniJobItem> addJobStream =
      _watch<MiniJobItem>(_DatabaseEvent.addJob);

  void addJob(MiniJobItem job) {
    _send(_DatabaseEvent.addJob, job);
  }
}
