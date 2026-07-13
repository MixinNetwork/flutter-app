import 'dart:async';

import '../../db/dao/conversation_dao.dart';
import '../../db/database_event_bus.dart';
import '../../db/extension/conversation.dart';
import '../../db/mixin_database.dart';
import '../../utils/logger.dart';

sealed class ConversationListEvent {
  const ConversationListEvent();
}

class ConversationListSnapshot extends ConversationListEvent {
  const ConversationListSnapshot();
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
  final Set<String> _pendingUserIds = {};

  final List<StreamSubscription<void>> _subscriptions = [];
  Timer? _flushTimer;
  Timer? _userFlushTimer;
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
      final muteUntil = item.validMuteUntil;
      if (muteUntil?.isAfter(now) == true) return count;
      return count + (item.unseenMessageCount ?? 0);
    });
  }

  Stream<ConversationListEvent> get events => Stream.multi(
    (controller) {
      if (_initialized) {
        controller.add(const ConversationListSnapshot());
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
      ..add(_eventBus.updateUserIdsStream.listen(_handleUserUpdate))
      ..add(
        _eventBus.updateCircleConversationStream.listen(
          (_) => unawaited(_reloadCircleConversations()),
        ),
      );
    final items = await _database.conversationDao.conversationItems().get();
    if (_closed) return;
    await _reloadCircleConversations(notify: false);
    if (_closed) return;
    _items
      ..clear()
      ..addEntries(items.map((item) => MapEntry(item.conversationId, item)));
    _resort();
    _initialized = true;
    _changes.add(const ConversationListSnapshot());
    if (_pendingIds.isNotEmpty) _schedule(const []);
  }

  Future<void> close() async {
    _closed = true;
    _flushTimer?.cancel();
    _userFlushTimer?.cancel();
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
    if (_closed) return;
    _pendingUserIds.addAll(userIds);
    _userFlushTimer ??= Timer(
      const Duration(milliseconds: 16),
      _flushUserUpdates,
    );
  }

  Future<void> _flushUserUpdates() async {
    _userFlushTimer = null;
    final ids = _pendingUserIds.toList();
    _pendingUserIds.clear();
    if (ids.isEmpty || _closed) return;
    try {
      _schedule(
        await _database.conversationDao.conversationIdsAffectedByUsers(ids),
      );
    } catch (error, stackTrace) {
      e('conversation user refresh failed: $error $stackTrace');
    }
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
      _changes.add(const ConversationListSnapshot());
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
      final results = {
        for (final item
            in await _database.conversationDao.conversationItemsByIds(ids))
          item.conversationId: item,
      };
      final changedIds = <String>{};
      final removedIds = <String>{};
      for (final id in ids) {
        final item = results[id];
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
    } catch (error, stackTrace) {
      e('conversation refresh failed: $error $stackTrace');
    } finally {
      _flushing = false;
      if (_pendingIds.isNotEmpty) _schedule(const []);
    }
  }

  void _resort() {
    _sortedItems
      ..clear()
      ..addAll(_items.values);
    _database.conversationDao.sortConversationItems(_sortedItems);
  }
}
