import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_app_icon_badge/flutter_app_icon_badge.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    show ConversationCategory;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../core/conversation/conversation_list_store.dart';
import '../../../db/dao/conversation_dao.dart';
import '../../../db/database.dart';
import '../../../db/extension/conversation.dart';
import '../../../utils/logger.dart';
import '../../../utils/platform.dart';
import '../../provider/mention_cache_provider.dart';
import '../../provider/slide_category_provider.dart';
import '../conversation/conversation_avatar_cache.dart';

const kDefaultLimit = 15;

class ConversationListState {
  const ConversationListState({
    this.items = const [],
    this.initialized = false,
  });

  final List<ConversationItem> items;
  final bool initialized;

  int get count => items.length;

  bool get hasData => items.isNotEmpty;
}

class ConversationListController extends ValueNotifier<ConversationListState> {
  ConversationListController(
    this.slideCategoryStateNotifier,
    Database database,
    this.mentionCache,
    this.store,
  ) : avatarCache = ConversationAvatarCache(database),
      super(const ConversationListState()) {
    _subscriptions
      ..add(
        slideCategoryStateNotifier.stream.distinct().listen(_switchCategory),
      )
      ..add(store.events.listen(_rebuild));
  }

  final SlideCategoryStateNotifier slideCategoryStateNotifier;
  final MentionCache mentionCache;
  final ConversationListStore store;
  final ConversationAvatarCache avatarCache;
  final Map<SlideCategoryState, _ConversationListView> _views = {};
  final List<StreamSubscription<void>> _subscriptions = [];

  int? _limit;
  int? _badgeCount;
  SlideCategoryState? _activeState;
  var _disposed = false;

  ConversationListState get state => value;

  int get limit => _limit ?? kDefaultLimit;

  set limit(int limit) {
    if (limit <= 0) {
      w('conversation list controller: ignore limit <= 0');
      return;
    }
    _limit = limit;
  }

  ItemPositionsListener? itemPositionsListener(
    SlideCategoryState slideCategoryState,
  ) => _views[slideCategoryState]?.itemPositionsListener;

  ItemScrollController? itemScrollController(
    SlideCategoryState slideCategoryState,
  ) => _views[slideCategoryState]?.itemScrollController;

  void init() => _switchCategory(slideCategoryStateNotifier.state);

  void _switchCategory(SlideCategoryState state) {
    if (state.type == SlideCategoryType.setting) return;
    _views.putIfAbsent(
      state,
      () => _ConversationListView(
        (indices) => _warmVisible(state, indices),
      ),
    );
    _activeState = state;
    _rebuild(const ConversationListSnapshot());
  }

  void _rebuild(ConversationListEvent event) {
    if (_disposed) return;
    final activeState = _activeState;
    if (activeState == null) return;
    final items = _itemsFor(activeState);
    value = ConversationListState(
      items: items,
      initialized: true,
    );
    final warmItems = switch (event) {
      ConversationListDelta(:final changedIds) => items.where(
        (item) => changedIds.contains(item.conversationId),
      ),
      ConversationListSnapshot() => items.take(limit),
    };
    unawaited(_warm(warmItems));
    final badgeCount = store.unseenCountIgnoringMuted;
    if (_badgeCount != badgeCount) {
      _badgeCount = badgeCount;
      unawaited(_updateBadge(badgeCount));
    }
  }

  List<ConversationItem> _itemsFor(SlideCategoryState state) {
    final items = store.items;
    return switch (state.type) {
      SlideCategoryType.chats => items,
      SlideCategoryType.contacts =>
        items.where((item) => item.isContactConversation).toList(),
      SlideCategoryType.groups =>
        items.where((item) => item.isGroupConversation).toList(),
      SlideCategoryType.bots =>
        items
            .where(
              (item) =>
                  item.category == ConversationCategory.contact &&
                  item.appId != null,
            )
            .toList(),
      SlideCategoryType.strangers =>
        items.where((item) => item.isStrangerConversation).toList(),
      SlideCategoryType.circle =>
        items
            .where(
              (item) => store
                  .conversationIdsInCircle(state.id!)
                  .contains(item.conversationId),
            )
            .toList(),
      SlideCategoryType.setting => const [],
    };
  }

  void _warmVisible(SlideCategoryState state, Set<int> indices) {
    final items = _itemsFor(state);
    unawaited(
      _warm(
        indices
            .where((index) => index >= 0 && index < items.length)
            .map((index) => items[index]),
      ),
    );
  }

  Future<void> _warm(Iterable<ConversationItem> items) async {
    final list = items.toList();
    if (list.isEmpty) return;
    try {
      await Future.wait([
        mentionCache.checkMentionCache(
          list.map((item) => item.content).toSet(),
        ),
        avatarCache.warm(list),
      ]);
    } catch (error) {
      e('conversation list cache warm failed: $error');
    }
  }

  static Future<void> _updateBadge(int count) async {
    if (!kPlatformIsDarwin) return;
    try {
      if (count == 0) {
        await FlutterAppIconBadge.removeBadge();
      } else {
        await FlutterAppIconBadge.updateBadge(count);
      }
    } catch (error) {
      w('failed to update app badge: $error');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    for (final view in _views.values) {
      view.dispose();
    }
    avatarCache.dispose();
    super.dispose();
  }
}

class _ConversationListView {
  _ConversationListView(this.onVisible) {
    itemPositionsListener.itemPositions.addListener(_onPositionsChanged);
  }

  final void Function(Set<int> indices) onVisible;
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final ItemScrollController itemScrollController = ItemScrollController();

  void _onPositionsChanged() => onVisible(
    itemPositionsListener.itemPositions.value.map((item) => item.index).toSet(),
  );

  void dispose() =>
      itemPositionsListener.itemPositions.removeListener(_onPositionsChanged);
}
