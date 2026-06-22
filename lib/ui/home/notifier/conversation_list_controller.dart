import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_app_icon_badge/flutter_app_icon_badge.dart';
import 'package:rxdart/rxdart.dart' hide ThrottleExtensions;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../db/dao/conversation_dao.dart';
import '../../../db/database.dart';
import '../../../db/database_event_bus.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/logger.dart';
import '../../../utils/platform.dart';
import '../../provider/mention_cache_provider.dart';
import '../../provider/slide_category_provider.dart';
import '../conversation/conversation_avatar_cache.dart';
import 'paging_controller.dart';

const kDefaultLimit = 15;

class ConversationListController
    extends ValueNotifier<PagingState<ConversationItem>> {
  ConversationListController(
    this.slideCategoryStateNotifier,
    this.database,
    this.mentionCache,
  ) : super(const PagingState<ConversationItem>()) {
    _subscriptions.add(
      slideCategoryStateNotifier.stream.distinct().listen(
        (event) => _switchController(event, _limit),
      ),
    );
    _initBadge();
  }

  final SlideCategoryStateNotifier slideCategoryStateNotifier;
  final Database database;
  final MentionCache mentionCache;
  late final ConversationAvatarCache avatarCache = ConversationAvatarCache(
    database,
  );
  final Map<SlideCategoryState, _ConversationPagingController> _map = {};
  final List<StreamSubscription?> _subscriptions = [];

  int? _limit;
  VoidCallback? _activeListener;
  SlideCategoryState? _activeState;
  _ConversationPagingController? _activeController;
  var _disposed = false;

  PagingState<ConversationItem> get state => value;

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
        _map[state] ??= _ConversationPagingController(
          limit ?? kDefaultLimit,
          () => dao.conversationCountByCategory(state.type),
          (limit, offset) =>
              dao.conversationItemsByCategory(state.type, limit, offset).get(),
          updateEvent,
          mentionCache,
          avatarCache,
        );
      case SlideCategoryType.circle:
        _map[state] ??= _ConversationPagingController(
          limit ?? kDefaultLimit,
          () => database.conversationDao
              .conversationsCountByCircleId(state.id!)
              .getSingle(),
          (limit, offset) => database.conversationDao
              .conversationsByCircleId(state.id!, limit, offset)
              .get(),
          circleUpdateEvent,
          mentionCache,
          avatarCache,
        );
      case SlideCategoryType.setting:
        return;
    }

    if (_activeState != null && _activeState != state) {
      _activeController?.deactivate();
    }
    _activeState = state;

    final controller = _map[state]!..activate();
    _listenTo(controller);
    value = controller.value;
  }

  void _listenTo(_ConversationPagingController controller) {
    if (_activeController != null && _activeListener != null) {
      _activeController!.removeListener(_activeListener!);
    }

    _activeController = controller;
    _activeListener = () {
      if (!_disposed) value = controller.value;
    };
    controller.addListener(_activeListener!);
  }

  @override
  void dispose() {
    _disposed = true;
    if (_activeController != null && _activeListener != null) {
      _activeController!.removeListener(_activeListener!);
    }
    _activeController?.deactivate();
    for (final subscription in _subscriptions) {
      unawaited(subscription?.cancel());
    }
    for (final controller in _map.values) {
      controller.dispose();
    }
    avatarCache.dispose();
    super.dispose();
  }

  Future<void> _initBadge() async {
    Future<void> updateBadge(int count) async {
      if (!kPlatformIsDarwin) return;
      if (count == 0) {
        await FlutterAppIconBadge.removeBadge();
        return;
      }
      await FlutterAppIconBadge.updateBadge(count);
    }

    final count = await database.conversationDao
        .allUnseenIgnoreMuteMessageCount()
        .getSingle();
    await updateBadge(count);
    _subscriptions.add(
      database.conversationDao.allUnseenIgnoreMuteMessageCountEvent
          .distinct()
          .asyncBufferMap((event) => updateBadge(event.last))
          .listen((_) {}),
    );
  }
}

class _ConversationPagingController extends PagingController<ConversationItem> {
  _ConversationPagingController(
    int limit,
    Future<int> Function() queryCount,
    Future<List<ConversationItem>> Function(int limit, int offset) queryRange,
    Stream<void> updateEvent,
    MentionCache mentionCache,
    ConversationAvatarCache avatarCache,
  ) : _updateEvent = updateEvent,
      super(
        itemPositionsListener: ItemPositionsListener.create(),
        limit: limit,
        queryCount: queryCount,
        queryRange: (limit, offset) async {
          final list = await queryRange(limit, offset);
          unawaited(_warmMentionCache(mentionCache, list));
          unawaited(avatarCache.warm(list));
          return list;
        },
      );

  final Stream<void> _updateEvent;
  final ItemScrollController itemScrollController = ItemScrollController();

  StreamSubscription<void>? _updateSubscription;

  void activate() {
    _updateSubscription ??= _updateEvent.listen((_) => update());
    if (value.initialized) update();
  }

  void deactivate() {
    unawaited(_updateSubscription?.cancel());
    _updateSubscription = null;
  }

  @override
  void dispose() {
    deactivate();
    super.dispose();
  }

  static Future<void> _warmMentionCache(
    MentionCache mentionCache,
    List<ConversationItem> list,
  ) async {
    try {
      await mentionCache.checkMentionCache(list.map((e) => e.content).toSet());
    } catch (error) {
      e('conversation mention cache failed: $error');
    }
  }
}
