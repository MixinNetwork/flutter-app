import 'dart:async';

import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    show ConversationCategory, ConversationStatus;

import '../../db/dao/conversation_dao.dart';
import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';

sealed class ConversationListEvent {
  const ConversationListEvent();
}

class ConversationListSnapshot extends ConversationListEvent {
  const ConversationListSnapshot(this.items);

  final List<ConversationItem> items;
}

class ConversationListDelta extends ConversationListEvent {
  const ConversationListDelta({
    this.changedIds = const {},
    this.removedIds = const {},
  });

  final Set<String> changedIds;
  final Set<String> removedIds;
}

class ConversationListStore {
  ConversationListStore(
    this._database, {
    DataBaseEventBus? eventBus,
  }) : _eventBus = eventBus ?? DataBaseEventBus.instance;

  final MixinDatabase _database;
  final DataBaseEventBus _eventBus;
  final StreamController<ConversationListEvent> _changes =
      StreamController.broadcast(sync: true);
  final Map<String, ConversationItem> _items = {};
  final List<ConversationItem> _sortedItems = [];
  final Map<String, Set<String>> _circleConversationIds = {};
  final Set<String> _pendingIds = {};

  final List<StreamSubscription<void>> _subscriptions = [];
  Timer? _flushTimer;
  bool _initialized = false;
  bool _flushing = false;
  bool _closed = false;

  List<ConversationItem> get items => List.unmodifiable(_sortedItems);

  ConversationItem? item(String conversationId) => _items[conversationId];

  Set<String> conversationIdsInCircle(String circleId) =>
      _circleConversationIds[circleId] ?? const {};

  int get unseenCountIgnoringMuted {
    final now = DateTime.now();
    return _items.values.fold(0, (count, item) {
      final muteUntil = item.category == ConversationCategory.group
          ? item.muteUntil
          : item.ownerMuteUntil;
      if (muteUntil?.isAfter(now) == true) return count;
      return count + (item.unseenMessageCount ?? 0);
    });
  }

  Stream<ConversationListEvent> get events => Stream.multi(
    (controller) {
      if (_initialized) {
        controller.add(ConversationListSnapshot(items));
      }
      final subscription = _changes.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    },
    isBroadcast: true,
  );

  Future<void> start() async {
    if (_initialized) return;
    _subscriptions
      ..add(
        _eventBus.updateConversationIdStream.listen(_schedule),
      )
      ..add(
        _eventBus.insertOrReplaceMessageIdsStream.listen(
          (messages) =>
              _schedule(messages.map((message) => message.conversationId)),
        ),
      )
      ..add(
        _eventBus.updateMessageMentionStream.listen(
          (messages) =>
              _schedule(messages.map((message) => message.conversationId)),
        ),
      )
      ..add(_eventBus.updateUserIdsStream.listen(_handleUserUpdate))
      ..add(
        _eventBus.updateCircleConversationStream.listen(
          (_) => unawaited(_reloadCircleConversations()),
        ),
      );
    final items = await _database.conversationDao.conversationItems().get();
    await _reloadCircleConversations(notify: false);
    _items
      ..clear()
      ..addEntries(items.map((item) => MapEntry(item.conversationId, item)));
    _resort();
    _initialized = true;
    _changes.add(ConversationListSnapshot(this.items));
    if (_pendingIds.isNotEmpty) _schedule(const []);
  }

  Future<void> close() async {
    _closed = true;
    _flushTimer?.cancel();
    await Future.wait(
      _subscriptions.map((subscription) => subscription.cancel()),
    );
    await _changes.close();
  }

  void _schedule(Iterable<String> conversationIds) {
    if (_closed) return;
    _pendingIds.addAll(conversationIds);
    if (!_initialized || _flushing || _flushTimer != null) return;
    _flushTimer = Timer(Duration.zero, _flush);
  }

  void _handleUserUpdate(List<String> userIds) {
    unawaited(
      _database.conversationDao
          .conversationIdsAffectedByUsers(userIds)
          .then(_schedule),
    );
  }

  Future<void> _reloadCircleConversations({bool notify = true}) async {
    final relationships = await _database
        .select(_database.circleConversations)
        .get();
    _circleConversationIds.clear();
    for (final relationship in relationships) {
      _circleConversationIds
          .putIfAbsent(relationship.circleId, () => <String>{})
          .add(relationship.conversationId);
    }
    if (notify && _initialized && !_closed) {
      _changes.add(ConversationListSnapshot(items));
    }
  }

  Future<void> _flush() async {
    _flushTimer = null;
    _flushing = true;
    final ids = _pendingIds.toList();
    _pendingIds.clear();
    if (ids.isEmpty) {
      _flushing = false;
      return;
    }

    try {
      final results = await Future.wait(
        ids.map(
          (id) async => (
            id,
            await _database.conversationDao
                .conversationItem(id)
                .getSingleOrNull(),
          ),
        ),
      );
      final changedIds = <String>{};
      final removedIds = <String>{};
      for (final (id, item) in results) {
        if (item == null) {
          if (_items.remove(id) != null) removedIds.add(id);
        } else if (_items[id] != item) {
          _items[id] = item;
          changedIds.add(id);
        }
      }
      if (!_closed && (changedIds.isNotEmpty || removedIds.isNotEmpty)) {
        _resort();
        _changes.add(
          ConversationListDelta(
            changedIds: changedIds,
            removedIds: removedIds,
          ),
        );
      }
    } finally {
      _flushing = false;
      if (_pendingIds.isNotEmpty) _schedule(const []);
    }
  }

  void _resort() {
    _sortedItems
      ..clear()
      ..addAll(_items.values)
      ..sort((a, b) {
        final pin = _compareNullableDateDescending(a.pinTime, b.pinTime);
        if (pin != 0) return pin;
        if (_hasDraft(a) != _hasDraft(b)) return _hasDraft(a) ? -1 : 1;
        final lastMessage = _compareNullableDateDescending(
          a.lastMessageCreatedAt,
          b.lastMessageCreatedAt,
        );
        if (lastMessage != 0) return lastMessage;
        final createdAt = b.createdAt.compareTo(a.createdAt);
        if (createdAt != 0) return createdAt;
        return a.conversationId.compareTo(b.conversationId);
      });
  }

  static bool _hasDraft(ConversationItem item) =>
      item.status != ConversationStatus.quit && item.draft?.isNotEmpty == true;

  static int _compareNullableDateDescending(DateTime? a, DateTime? b) {
    if (a == null) return b == null ? 0 : 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }
}
