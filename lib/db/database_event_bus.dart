import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../runtime/sync/patch.dart';
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

  final StreamController<SyncPatch> _patchController =
      StreamController<SyncPatch>.broadcast();
  bool _legacyEventDispatchEnabled = true;
  bool _suppressPatchEmission = false;

  Stream<SyncPatch> get patchStream => _patchController.stream;

  set legacyEventBridgeEnabled(bool enabled) =>
      _legacyEventDispatchEnabled = enabled;

  void applyPatches(Iterable<SyncPatch> patches) {
    final previous = _suppressPatchEmission;
    _suppressPatchEmission = true;
    try {
      patches.forEach(applyPatch);
    } finally {
      _suppressPatchEmission = previous;
    }
  }

  void applyPatch(SyncPatch patch) {
    switch (patch.type) {
      case SyncPatchType.notification:
        notificationMessage(patch.payload! as MiniNotificationMessage);
      case SyncPatchType.insertOrReplaceMessage:
        insertOrReplaceMessages(
          (patch.payload! as List).cast<MiniMessageItem>(),
        );
      case SyncPatchType.deleteMessage:
        final messageIds = (patch.payload! as List).cast<String>();
        messageIds.forEach(deleteMessage);
      case SyncPatchType.updateExpiredMessage:
        updateExpiredMessageTable();
      case SyncPatchType.updateConversation:
        final conversationIds = (patch.payload! as List).cast<String>();
        conversationIds.forEach(updateConversation);
      case SyncPatchType.updateFavoriteApp:
        updateFavoriteApp((patch.payload! as List).cast<String>());
      case SyncPatchType.updateUser:
        updateUsers((patch.payload! as List).cast<String>());
      case SyncPatchType.updateParticipant:
        updateParticipant((patch.payload! as List).cast<MiniParticipantItem>());
      case SyncPatchType.updateSticker:
        updateSticker((patch.payload! as List).cast<MiniSticker>());
      case SyncPatchType.updateSnapshot:
        updateSnapshot((patch.payload! as List).cast<String>());
      case SyncPatchType.updateMessageMention:
        updateMessageMention((patch.payload! as List).cast<MiniMessageItem>());
      case SyncPatchType.updateCircle:
        updateCircle();
      case SyncPatchType.updateCircleConversation:
        updateCircleConversation();
      case SyncPatchType.updatePinMessage:
        updatePinMessage((patch.payload! as List).cast<MiniMessageItem>());
      case SyncPatchType.updateTranscriptMessage:
        updateTranscriptMessage(
          (patch.payload! as List).cast<MiniTranscriptMessage>(),
        );
      case SyncPatchType.updateAsset:
        updateAsset((patch.payload! as List).cast<String>());
      case SyncPatchType.updateToken:
        updateToken((patch.payload! as List).cast<String>());
      case SyncPatchType.addJob:
        addJob(patch.payload! as MiniJobItem);
    }
  }

  void _emitPatch(SyncPatch patch) {
    if (_suppressPatchEmission) return;
    _patchController.add(patch);
  }

  Stream<T> _watch<T>(_DatabaseEvent event) => EventBus.instance.on
      .whereType<_DatabaseEventWrapper>()
      .where((e) => event == e.type)
      .map((e) {
        if (kDebugMode && e.data is! T) {
          w(
            'DatabaseEvent: event type is not match: ${e.data.runtimeType} != $T',
          );
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
    if (_legacyEventDispatchEnabled) {
      EventBus.instance.fire(_DatabaseEventWrapper(event, value));
    }
  }

  Stream<_DatabaseEvent> _watchEvent(_DatabaseEvent event) => EventBus
      .instance
      .on
      .whereType<_DatabaseEventWrapper>()
      .map((e) => e.type)
      .where((e) => e == event);

  void _sendEvent(_DatabaseEvent event) {
    if (_legacyEventDispatchEnabled) {
      EventBus.instance.fire(_DatabaseEventWrapper(event, null));
    }
  }

  // user
  late Stream<List<String>> updateUserIdsStream = _watch<List<String>>(
    _DatabaseEvent.updateUser,
  );

  Stream<List<String>> watchUpdateUserStream(Iterable<String> userIds) =>
      updateUserIdsStream.where((event) => event.any(userIds.contains));

  void updateUsers(Iterable<String> userIds) {
    final newUserIds = userIds.where((id) {
      if (id.trim().isNotEmpty) return true;
      i('DatabaseEvent: insertOrReplaceUsers userId is empty: $id');
      return false;
    }).toList();

    if (newUserIds.isEmpty) {
      w('DatabaseEvent: insertOrReplaceUsers userIds is empty');
      return;
    }

    _emitPatch(SyncPatch.updateUser(newUserIds));
    _send(_DatabaseEvent.updateUser, newUserIds);
  }

  // circle
  late Stream<void> updateCircleStream = _watch<void>(
    _DatabaseEvent.updateCircle,
  );

  void updateCircle() {
    _emitPatch(SyncPatch.updateCircle());
    _sendEvent(_DatabaseEvent.updateCircle);
  }

  // circleConversation
  late Stream<void> updateCircleConversationStream = _watch<void>(
    _DatabaseEvent.updateCircleConversation,
  );

  void updateCircleConversation() {
    _emitPatch(SyncPatch.updateCircleConversation());
    _sendEvent(_DatabaseEvent.updateCircleConversation);
  }

  // conversation
  late final Stream<List<String>> updateConversationIdStream =
      _watch<List<String>>(_DatabaseEvent.updateConversation);

  Stream<List<String>> watchUpdateConversationStream(
    Iterable<String> conversationIds,
  ) => updateConversationIdStream.where(
    (event) => event.any(conversationIds.contains),
  );

  void updateConversation(String conversationId) {
    if (conversationId.trim().isEmpty) {
      w('DatabaseEvent: insertOrReplaceConversation conversationId is empty');
      return;
    }
    final payload = [conversationId];
    _emitPatch(SyncPatch.updateConversation(payload));
    _send(_DatabaseEvent.updateConversation, payload);
  }

  // participant
  late Stream<List<MiniParticipantItem>> updateParticipantIdStream =
      _watch<List<MiniParticipantItem>>(_DatabaseEvent.updateParticipant);

  Stream<List<MiniParticipantItem>> watchUpdateParticipantStream({
    Iterable<String> conversationIds = const [],
    Iterable<String> userIds = const [],
    bool and = false,
  }) => updateParticipantIdStream.where(
    (event) => event.any((element) {
      bool isContainConversationId() =>
          conversationIds.contains(element.conversationId);
      bool isContainUserId() => userIds.contains(element.userId);
      if (and) {
        return isContainConversationId() && isContainUserId();
      } else {
        return isContainConversationId() || isContainUserId();
      }
    }),
  );

  void updateParticipant(Iterable<MiniParticipantItem> participants) {
    final newParticipants = participants.where((participant) {
      if (participant.conversationId.trim().isNotEmpty &&
          participant.userId.trim().isNotEmpty) {
        return true;
      }
      i('DatabaseEvent: updateParticipant participantId is empty');
      return false;
    }).toList();

    if (newParticipants.isEmpty) {
      w('DatabaseEvent: updateParticipant participantIds is empty');
      return;
    }
    _emitPatch(SyncPatch.updateParticipant(newParticipants));
    _send(_DatabaseEvent.updateParticipant, newParticipants);
  }

  // message
  late Stream<List<MiniMessageItem>> insertOrReplaceMessageIdsStream =
      _watch<List<MiniMessageItem>>(_DatabaseEvent.insertOrReplaceMessage);

  Stream<List<MiniMessageItem>> watchInsertOrReplaceMessageIdsStream({
    Iterable<String> conversationIds = const [],
    Iterable<String> messageIds = const [],
    bool and = false,
  }) => insertOrReplaceMessageIdsStream.where(
    (event) => event.any((element) {
      bool isContainConversationId() =>
          conversationIds.contains(element.conversationId);
      bool isContainMessageId() => messageIds.contains(element.messageId);
      if (and) {
        return isContainConversationId() && isContainMessageId();
      } else {
        return isContainConversationId() || isContainMessageId();
      }
    }),
  );

  void insertOrReplaceMessages(Iterable<MiniMessageItem> messageEvents) {
    final newMessageEvents = messageEvents.where((event) {
      if (event.messageId.trim().isNotEmpty &&
          event.conversationId.trim().isNotEmpty) {
        return true;
      }
      i(
        'DatabaseEvent: insertOrReplaceMessages messageId or conversationId is empty: $event',
      );
      return false;
    }).toList();

    if (newMessageEvents.isEmpty) {
      i('DatabaseEvent: insertOrReplaceMessages messageIds is empty');
      return;
    }
    _emitPatch(SyncPatch.insertOrReplaceMessage(newMessageEvents));
    _send(_DatabaseEvent.insertOrReplaceMessage, newMessageEvents);
  }

  late Stream<List<String>> deleteMessageIdStream = _watch<List<String>>(
    _DatabaseEvent.deleteMessage,
  );

  void deleteMessage(String messageId) {
    if (messageId.trim().isEmpty) {
      w('DatabaseEvent: deleteMessage messageId is empty');
      return;
    }
    final payload = [messageId];
    _emitPatch(SyncPatch.deleteMessage(payload));
    _send(_DatabaseEvent.deleteMessage, payload);
  }

  late Stream<MiniNotificationMessage> notificationMessageStream =
      _watch<MiniNotificationMessage>(_DatabaseEvent.notification);

  void notificationMessage(MiniNotificationMessage miniNotificationMessage) {
    if (miniNotificationMessage.messageId.trim().isEmpty ||
        miniNotificationMessage.conversationId.trim().isEmpty) {
      w('DatabaseEvent: notificationMessage messageId is empty');
      return;
    }
    _emitPatch(SyncPatch.notification(miniNotificationMessage));
    _send(_DatabaseEvent.notification, miniNotificationMessage);
  }

  late Stream<List<MiniMessageItem>> updateMessageMentionStream =
      _watch<List<MiniMessageItem>>(_DatabaseEvent.updateMessageMention);

  Stream<List<MiniMessageItem>> watchUpdateMessageMention({
    Iterable<String> conversationIds = const [],
    Iterable<String> messageIds = const [],
    bool and = false,
  }) => updateMessageMentionStream.where(
    (event) => event.any((element) {
      bool isContainConversationId() =>
          conversationIds.contains(element.conversationId);
      bool isContainMessageId() => messageIds.contains(element.messageId);
      if (and) {
        return isContainConversationId() && isContainMessageId();
      } else {
        return isContainConversationId() || isContainMessageId();
      }
    }),
  );

  void updateMessageMention(Iterable<MiniMessageItem> messageEvents) {
    final newMessageEvents = messageEvents.where((event) {
      if (event.messageId.trim().isNotEmpty &&
          event.conversationId.trim().isNotEmpty) {
        return true;
      }
      i(
        'DatabaseEvent: insertOrReplaceMessages messageId or conversationId is empty: $event',
      );
      return false;
    }).toList();

    if (newMessageEvents.isEmpty) {
      i('DatabaseEvent: insertOrReplaceMessages messageIds is empty');
      return;
    }
    _emitPatch(SyncPatch.updateMessageMention(newMessageEvents));
    _send(_DatabaseEvent.updateMessageMention, newMessageEvents);
  }

  // pinMessage
  late Stream<List<MiniMessageItem>> updatePinMessageStream =
      _watch<List<MiniMessageItem>>(_DatabaseEvent.updatePinMessage);

  Stream<List<MiniMessageItem>> watchPinMessageStream({
    Iterable<String> conversationIds = const [],
    Iterable<String> messageIds = const [],
    bool and = false,
  }) => updatePinMessageStream.where(
    (event) => event.any((element) {
      bool isContainConversationId() =>
          conversationIds.contains(element.conversationId);
      bool isContainMessageId() => messageIds.contains(element.messageId);
      if (and) {
        return isContainConversationId() && isContainMessageId();
      } else {
        return isContainConversationId() || isContainMessageId();
      }
    }),
  );

  void updatePinMessage(Iterable<MiniMessageItem> messageEvent) {
    final newMessageEvents = messageEvent.where((event) {
      if (event.messageId.trim().isNotEmpty &&
          event.conversationId.trim().isNotEmpty) {
        return true;
      }
      i(
        'DatabaseEvent: updatePinMessage messageId or conversationId is empty: $event',
      );
      return false;
    }).toList();

    if (newMessageEvents.isEmpty) {
      i('DatabaseEvent: updatePinMessage messageIds is empty');
      return;
    }
    _emitPatch(SyncPatch.updatePinMessage(newMessageEvents));
    _send(_DatabaseEvent.updatePinMessage, newMessageEvents);
  }

  // transcriptMessage
  late Stream<List<MiniTranscriptMessage>> updateTranscriptMessageStream =
      _watch<List<MiniTranscriptMessage>>(
        _DatabaseEvent.updateTranscriptMessage,
      );

  Stream<List<MiniTranscriptMessage>> watchUpdateTranscriptMessageStream({
    Iterable<String> transcriptIds = const [],
    Iterable<String> messageIds = const [],
    bool and = false,
  }) => updateTranscriptMessageStream.where(
    (event) => event.any((element) {
      bool isContainTranscriptId() =>
          transcriptIds.contains(element.transcriptId);
      bool isContainMessageId() => messageIds.contains(element.messageId);
      if (and) {
        return isContainTranscriptId() && isContainMessageId();
      } else {
        return isContainTranscriptId() || isContainMessageId();
      }
    }),
  );

  void updateTranscriptMessage(Iterable<MiniTranscriptMessage> messageEvent) {
    final newMessageEvents = messageEvent.where((event) {
      if (event.transcriptId.trim().isNotEmpty) return true;
      i('DatabaseEvent: updateTranscriptMessage transcriptId is empty: $event');
      return false;
    }).toList();

    if (newMessageEvents.isEmpty) {
      i('DatabaseEvent: updateTranscriptMessage is empty');
      return;
    }
    _emitPatch(SyncPatch.updateTranscriptMessage(newMessageEvents));
    _send(_DatabaseEvent.updateTranscriptMessage, newMessageEvents);
  }

  // expiredMessage
  late Stream<void> updateExpiredMessageTableStream = _watchEvent(
    _DatabaseEvent.updateExpiredMessage,
  );

  void updateExpiredMessageTable() {
    _emitPatch(SyncPatch.updateExpiredMessage());
    _sendEvent(_DatabaseEvent.updateExpiredMessage);
  }

  // sticker

  late Stream<List<MiniSticker>> updateStickerStream =
      _watch<List<MiniSticker>>(_DatabaseEvent.updateSticker);

  Stream<List<MiniSticker>> watchUpdateStickerStream({
    Iterable<String> stickerIds = const [],
    Iterable<String> albumIds = const [],
    bool and = false,
  }) => updateStickerStream.where(
    (event) => event.any((element) {
      bool isContainStickerId() => stickerIds.contains(element.stickerId);
      bool isContainAlbumId() => albumIds.contains(element.albumId);
      if (and) {
        return isContainStickerId() && isContainAlbumId();
      } else {
        return isContainStickerId() || isContainAlbumId();
      }
    }),
  );

  void updateSticker(Iterable<MiniSticker> miniStickers) {
    final newMiniStickers = miniStickers
        .where(
          (element) =>
              (element.stickerId?.trim().isNotEmpty ?? false) ||
              (element.albumId?.trim().isNotEmpty ?? false),
        )
        .toList();
    if (newMiniStickers.isEmpty) {
      w('DatabaseEvent: updateSticker miniStickers is empty');
      return;
    }
    _emitPatch(SyncPatch.updateSticker(newMiniStickers));
    _send(_DatabaseEvent.updateSticker, newMiniStickers);
  }

  // app
  late Stream<List<String>> updateAppIdStream = _watch<List<String>>(
    _DatabaseEvent.updateFavoriteApp,
  );

  void updateFavoriteApp(Iterable<String> appIds) {
    final newAppIds = appIds
        .where((element) => element.trim().isNotEmpty)
        .toList();
    if (newAppIds.isEmpty) {
      w('DatabaseEvent: insertOrReplaceFavoriteApp appIds is empty');
      return;
    }
    _emitPatch(SyncPatch.updateFavoriteApp(newAppIds));
    _send(_DatabaseEvent.updateFavoriteApp, newAppIds);
  }

  // Snapshot
  late Stream<List<String>> updateSnapshotStream = _watch<List<String>>(
    _DatabaseEvent.updateSnapshot,
  );

  void updateSnapshot(Iterable<String> snapshotIds) {
    final newSnapshotIds = snapshotIds
        .where(
          (element) => element.trim().isNotEmpty,
        )
        .toList();
    if (newSnapshotIds.isEmpty) {
      w('DatabaseEvent: updateSnapshot snapshotIds is empty');
      return;
    }
    _emitPatch(SyncPatch.updateSnapshot(newSnapshotIds));
    _send(_DatabaseEvent.updateSnapshot, newSnapshotIds);
  }

  // Safe Snapshot
  late Stream<List<String>> updateSafeSnapshotStream = _watch<List<String>>(
    _DatabaseEvent.updateSnapshot,
  );

  void updateSafeSnapshot(Iterable<String> snapshotIds) {
    final newSnapshotIds = snapshotIds
        .where(
          (element) => element.trim().isNotEmpty,
        )
        .toList();
    if (newSnapshotIds.isEmpty) {
      w('DatabaseEvent: updateSafeSnapshot snapshotIds is empty');
      return;
    }
    _emitPatch(SyncPatch.updateSnapshot(newSnapshotIds));
    _send(_DatabaseEvent.updateSnapshot, newSnapshotIds);
  }

  // Asset
  late Stream<List<String>> updateAssetStream = _watch<List<String>>(
    _DatabaseEvent.updateAsset,
  );

  void updateAsset(Iterable<String> assetIds) {
    final newAssetIds = assetIds
        .where((element) => element.trim().isNotEmpty)
        .toList();
    if (newAssetIds.isEmpty) {
      w('DatabaseEvent: updateAsset assetIds is empty');
      return;
    }
    _emitPatch(SyncPatch.updateAsset(newAssetIds));
    _send(_DatabaseEvent.updateAsset, newAssetIds);
  }

  // Token
  late Stream<List<String>> updateTokenStream = _watch<List<String>>(
    _DatabaseEvent.updateToken,
  );

  void updateToken(Iterable<String> tokenIds) {
    final newTokenIds = tokenIds
        .where((element) => element.trim().isNotEmpty)
        .toList();
    if (newTokenIds.isEmpty) {
      w('DatabaseEvent: updateToken tokenIds is empty');
      return;
    }
    _emitPatch(SyncPatch.updateToken(newTokenIds));
    _send(_DatabaseEvent.updateToken, newTokenIds);
  }

  // Job
  late Stream<MiniJobItem> addJobStream = _watch<MiniJobItem>(
    _DatabaseEvent.addJob,
  );

  void addJob(MiniJobItem job) {
    _emitPatch(SyncPatch.addJob(job));
    _send(_DatabaseEvent.addJob, job);
  }
}
