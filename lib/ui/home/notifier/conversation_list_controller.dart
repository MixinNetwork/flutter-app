import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_app_icon_badge/flutter_app_icon_badge.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    show ConversationCategory, UserRelationship;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../core/conversation/conversation_list_store.dart';
import '../../../db/dao/conversation_dao.dart';
import '../../../db/database.dart';
import '../../../utils/logger.dart';
import '../../../utils/platform.dart';
import '../../provider/mention_cache_provider.dart';
import '../../provider/slide_category_provider.dart';
import '../conversation/conversation_avatar_cache.dart';

const kDefaultLimit = 15;

class PagingState<T> {
  const PagingState({
    this.map = const {},
    this.count = 0,
    this.initialized = false,
    this.hasData = false,
  });

  final Map<int, T> map;
  final int count;
  final bool initialized;
  final bool hasData;
}

class ConversationListController
    extends ValueNotifier<PagingState<ConversationItem>> {
  ConversationListController(
    this.slideCategoryStateNotifier,
    Database database,
    this.mentionCache,
    this.store,
  ) : avatarCache = ConversationAvatarCache(database),
      super(const PagingState<ConversationItem>()) {
    _subscriptions
      ..add(
        slideCategoryStateNotifier.stream.distinct().listen(_switchCategory),
      )
      ..add(store.events.listen((_) => _rebuild()));
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

  PagingState<ConversationItem> get state => value;

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
    _views.putIfAbsent(state, _ConversationListView.new);
    _activeState = state;
    _rebuild();
  }

  void _rebuild() {
    if (_disposed) return;
    final activeState = _activeState;
    if (activeState == null) return;
    final items = _itemsFor(activeState);
    value = PagingState(
      map: {for (final (index, item) in items.indexed) index: item},
      count: items.length,
      initialized: true,
      hasData: items.isNotEmpty,
    );
    unawaited(_warm(items));
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
        items
            .where(
              (item) =>
                  item.category == ConversationCategory.contact &&
                  item.relationship == UserRelationship.friend &&
                  item.appId == null,
            )
            .toList(),
      SlideCategoryType.groups =>
        items
            .where((item) => item.category == ConversationCategory.group)
            .toList(),
      SlideCategoryType.bots =>
        items
            .where(
              (item) =>
                  item.category == ConversationCategory.contact &&
                  item.appId != null,
            )
            .toList(),
      SlideCategoryType.strangers =>
        items
            .where(
              (item) =>
                  item.category == ConversationCategory.contact &&
                  item.relationship == UserRelationship.stranger &&
                  item.appId == null,
            )
            .toList(),
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

  Future<void> _warm(List<ConversationItem> items) async {
    try {
      await Future.wait([
        mentionCache.checkMentionCache(
          items.map((item) => item.content).toSet(),
        ),
        avatarCache.warm(items),
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
    avatarCache.dispose();
    super.dispose();
  }
}

class _ConversationListView {
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final ItemScrollController itemScrollController = ItemScrollController();
}
