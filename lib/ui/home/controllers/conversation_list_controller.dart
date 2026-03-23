import 'dart:async';

import 'package:flutter_app_icon_badge/flutter_app_icon_badge.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rxdart/rxdart.dart' hide ThrottleExtensions;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../db/dao/conversation_dao.dart';
import '../../../db/database.dart';
import '../../../db/database_event_bus.dart';
import '../../../paging/paging_controller.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/logger.dart';
import '../../../utils/platform.dart';
import '../../provider/account_server_provider.dart';
import '../../provider/mention_cache_provider.dart';
import '../../provider/slide_category_provider.dart';

const kDefaultLimit = 15;

class ConversationListController
    extends Notifier<PagingState<ConversationItem>> {
  SlideCategoryStateNotifier get slideCategoryStateNotifier =>
      ref.read(slideCategoryProvider.notifier);
  Database get database =>
      ref.read(accountServerProvider).requireValue.database;
  MentionCache get mentionCache => ref.read(mentionCacheProvider);

  final Map<SlideCategoryState, _ConversationListController> _map = {};
  StreamSubscription<SlideCategoryState>? _slideCategorySubscription;
  StreamSubscription<PagingState<ConversationItem>>? _streamSubscription;
  bool _badgeInitialized = false;

  int? _limit;

  int get limit {
    if (_limit == null) {
      w('conversation list controller: limit is null');
      return kDefaultLimit;
    }
    return _limit!;
  }

  set limit(int limit) {
    if (limit <= 0) {
      w('conversation list controller: ignore limit <= 0');
      return;
    }

    _limit = limit;
    for (final controller in _map.values) {
      controller.limit = limit;
    }
  }

  SlideCategoryState? _activeState;

  @override
  PagingState<ConversationItem> build() {
    _slideCategorySubscription ??= slideCategoryStateNotifier.stream
        .distinct()
        .listen((event) => _switchController(event, _limit));
    if (!_badgeInitialized) {
      _badgeInitialized = true;
      unawaited(_initBadge());
    }

    ref.onDispose(() async {
      await _slideCategorySubscription?.cancel();
      await _streamSubscription?.cancel();
      _map[_activeState]?.deactivate();
      for (final controller in _map.values) {
        controller.dispose();
      }
      _map.clear();
    });

    return stateOrNull ?? const PagingState<ConversationItem>();
  }

  ItemPositionsListener? itemPositionsListener(
    SlideCategoryState slideCategoryState,
  ) => _map[slideCategoryState]?.itemPositionsListener;

  ItemScrollController? itemScrollController(
    SlideCategoryState slideCategoryState,
  ) => _map[slideCategoryState]?.itemScrollController;

  void init() => _switchController(slideCategoryStateNotifier.state, _limit);

  late final Stream<void> updateEvent = Rx.merge([
    DataBaseEventBus.instance.updateConversationIdStream,
    DataBaseEventBus.instance.updateUserIdsStream,
    DataBaseEventBus.instance.insertOrReplaceMessageIdsStream,
    DataBaseEventBus.instance.updateMessageMentionStream,
  ]).throttleTime(kDefaultThrottleDuration).asBroadcastStream();

  late final Stream<void> circleUpdateEvent = Rx.merge([
    DataBaseEventBus.instance.updateConversationIdStream,
    DataBaseEventBus.instance.updateUserIdsStream,
    DataBaseEventBus.instance.insertOrReplaceMessageIdsStream,
    DataBaseEventBus.instance.updateMessageMentionStream,
    DataBaseEventBus.instance.updateCircleStream,
    DataBaseEventBus.instance.updateCircleConversationStream,
  ]).throttleTime(kDefaultThrottleDuration).asBroadcastStream();

  void _switchController(SlideCategoryState state, int? limit) {
    final dao = database.conversationDao;

    switch (state.type) {
      case SlideCategoryType.chats:
      case SlideCategoryType.contacts:
      case SlideCategoryType.groups:
      case SlideCategoryType.bots:
      case SlideCategoryType.strangers:
        _map[state] ??= _ConversationListController(
          limit ?? kDefaultLimit,
          () => dao.conversationCountByCategory(state.type),
          (limit, offset) =>
              dao.conversationItemsByCategory(state.type, limit, offset).get(),
          updateEvent,
          mentionCache,
          () => dao.conversationHasDataByCategory(state.type),
        );
      case SlideCategoryType.circle:
        _map[state] ??= _ConversationListController(
          limit ?? kDefaultLimit,
          () => database.conversationDao
              .conversationsCountByCircleId(state.id!)
              .getSingle(),
          (limit, offset) => database.conversationDao
              .conversationsByCircleId(state.id!, limit, offset)
              .get(),
          circleUpdateEvent,
          mentionCache,
          () =>
              database.conversationDao.conversationHasDataByCircleId(state.id!),
        );
      case SlideCategoryType.setting:
        return;
    }

    final previous = _activeState;
    if (previous != null && previous != state) {
      _map[previous]?.deactivate();
    }

    final controller = _map[state]!..activate();
    _activeState = state;

    this.state = controller.state;
    unawaited(_streamSubscription?.cancel());
    _streamSubscription = controller.stream.listen(
      (value) => this.state = value,
    );
  }

  Future<void> _initBadge() async {
    Future<void> updateBadge(int count) async {
      if (!kPlatformIsDarwin) {
        return;
      }
      if (count == 0) {
        await FlutterAppIconBadge.removeBadge();
        return;
      }
      await FlutterAppIconBadge.updateBadge(count);
    }

    if (!ref.mounted) return;
    final db = database;
    final count = await db.conversationDao
        .allUnseenIgnoreMuteMessageCount()
        .getSingle();
    if (!ref.mounted) return;
    await updateBadge(count);
    if (!ref.mounted) return;
    final subscription = db
        .conversationDao
        .allUnseenIgnoreMuteMessageCountEvent
        .distinct()
        .asyncBufferMap((event) => updateBadge(event.last))
        .listen((_) {});
    ref.onDispose(subscription.cancel);
  }
}

class _ConversationListController extends PagingController<ConversationItem> {
  _ConversationListController(
    int limit,
    Future<int> Function() queryCount,
    Future<List<ConversationItem>> Function(int limit, int offset) queryRange,
    Stream<void> updateEvent,
    this.mentionCache,
    Future<bool> Function() queryHasData,
  ) : _queryCount = queryCount,
      _queryRange = queryRange,
      _queryHasData = queryHasData,
      _updateEvent = updateEvent,
      super(
        initState: const PagingState<ConversationItem>(),
        itemPositionsListener: ItemPositionsListener.create(),
        limit: limit,
      );

  final MentionCache mentionCache;
  final Future<int> Function() _queryCount;
  final Future<List<ConversationItem>> Function(int limit, int offset)
  _queryRange;
  final Future<bool> Function() _queryHasData;
  final Stream<void> _updateEvent;

  StreamSubscription<void>? _updateSubscription;

  final ItemScrollController itemScrollController = ItemScrollController();

  void activate() {
    _updateSubscription ??= _updateEvent.listen((_) {
      unawaited(refresh());
    });
    unawaited(refresh());
  }

  void deactivate() {
    unawaited(_updateSubscription?.cancel());
    _updateSubscription = null;
  }

  @override
  Future<int> queryCount() => _queryCount();

  @override
  Future<List<ConversationItem>> queryRange(int limit, int offset) async {
    final list = await _queryRange(limit, offset);
    await mentionCache.checkMentionCache(list.map((e) => e.content).toSet());
    return list;
  }

  @override
  Future<bool> queryHasData() => _queryHasData();

  @override
  void dispose() {
    deactivate();
    super.dispose();
  }
}
