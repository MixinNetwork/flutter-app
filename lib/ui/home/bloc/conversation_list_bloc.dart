import 'dart:async';

import 'package:flutter_app_icon_badge/flutter_app_icon_badge.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart' hide ThrottleExtensions;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../bloc/paging/paging_bloc.dart';
import '../../../bloc/subscribe_mixin.dart';
import '../../../db/dao/conversation_dao.dart';
import '../../../db/database.dart';
import '../../../db/database_event_bus.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/logger.dart';
import '../../../utils/platform.dart';
import '../../provider/mention_cache_provider.dart';
import '../../provider/slide_category_provider.dart';

const kDefaultLimit = 15;

class ConversationListBloc extends Cubit<PagingState<ConversationItem>>
    with SubscribeMixin {
  ConversationListBloc(
    this.slideCategoryStateNotifier,
    this.database,
    this.mentionCache,
  ) : super(const PagingState<ConversationItem>()) {
    addSubscription(slideCategoryStateNotifier.stream
        .distinct()
        .listen((event) => _switchBloc(event, _limit)));
    _initBadge();
  }

  final SlideCategoryStateNotifier slideCategoryStateNotifier;
  final Database database;
  final MentionCache mentionCache;
  final Map<SlideCategoryState, _ConversationListBloc> _map = {};

  int? _limit;

  int get limit {
    if (_limit == null) {
      w('conversation list bloc: limit is null');
      return kDefaultLimit;
    }
    return _limit!;
  }

  set limit(int limit) {
    if (limit <= 0) {
      w('conversation list bloc: ignore limit <= 0');
      return;
    }

    _limit = limit;
    _map.values.forEach((element) {
      element.limit = limit;
    });
  }

  StreamSubscription? streamSubscription;

  ItemPositionsListener? itemPositionsListener(
          SlideCategoryState slideCategoryState) =>
      _map[slideCategoryState]?.itemPositionsListener;

  ItemScrollController? itemScrollController(
          SlideCategoryState slideCategoryState) =>
      _map[slideCategoryState]?.itemScrollController;

  void init() => _switchBloc(slideCategoryStateNotifier.state, _limit);

  late Stream<void> updateEvent = Rx.merge([
    DataBaseEventBus.instance.updateConversationIdStream,
    DataBaseEventBus.instance.updateUserIdsStream,
    DataBaseEventBus.instance.insertOrReplaceMessageIdsStream,
    DataBaseEventBus.instance.updateMessageMentionStream,
  ]).throttleTime(kDefaultThrottleDuration).asBroadcastStream();

  late Stream<void> circleUpdateEvent = Rx.merge([
    DataBaseEventBus.instance.updateConversationIdStream,
    DataBaseEventBus.instance.updateUserIdsStream,
    DataBaseEventBus.instance.insertOrReplaceMessageIdsStream,
    DataBaseEventBus.instance.updateMessageMentionStream,
    DataBaseEventBus.instance.updateCircleStream,
    DataBaseEventBus.instance.updateCircleConversationStream,
  ]).throttleTime(kDefaultThrottleDuration).asBroadcastStream();

  void _switchBloc(
    SlideCategoryState state,
    int? limit,
  ) {
    final dao = database.conversationDao;

    switch (state.type) {
      case SlideCategoryType.chats:
      case SlideCategoryType.contacts:
      case SlideCategoryType.groups:
      case SlideCategoryType.bots:
      case SlideCategoryType.strangers:
        _map[state] ??= _ConversationListBloc(
          limit ?? kDefaultLimit,
          () => dao.conversationCountByCategory(state.type),
          (limit, offset) =>
              dao.conversationItemsByCategory(state.type, limit, offset).get(),
          updateEvent,
          mentionCache,
          () => dao.conversationHasDataByCategory(state.type),
        );
      case SlideCategoryType.circle:
        _map[state] ??= _ConversationListBloc(
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
    final bloc = _map[state];
    emit(bloc!.state);
    streamSubscription?.cancel();
    streamSubscription = bloc.stream.listen(emit);
  }

  @override
  Future<void> close() async {
    await Future.wait(_map.values.map((e) => e.close()));
    await super.close();
  }

  Future<void> _initBadge() async {
    Future<void> updateBadge(int count) async {
      if (!kPlatformIsDarwin) {
        // not work on other platform.
        return;
      }
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
    addSubscription(database
        .conversationDao.allUnseenIgnoreMuteMessageCountEvent
        .distinct()
        .asyncBufferMap((event) => updateBadge(event.last))
        .listen((_) {}));
  }
}

class _ConversationListBloc extends PagingBloc<ConversationItem> {
  _ConversationListBloc(
    int limit,
    Future<int> Function() queryCount,
    Future<List<ConversationItem>> Function(int limit, int offset) queryRange,
    Stream<void> updateEvent,
    this.mentionCache,
    Future<bool> Function() queryHasData,
  )   : _queryCount = queryCount,
        _queryRange = queryRange,
        _queryHasData = queryHasData,
        super(
          initState: const PagingState<ConversationItem>(),
          itemPositionsListener: ItemPositionsListener.create(),
          limit: limit,
        ) {
    addSubscription(updateEvent.listen((event) => add(PagingUpdateEvent())));
  }

  final MentionCache mentionCache;
  final Future<int> Function() _queryCount;
  final Future<List<ConversationItem>> Function(int limit, int offset)
      _queryRange;
  final Future<bool> Function() _queryHasData;

  final ItemScrollController itemScrollController = ItemScrollController();

  @override
  Future<int> queryCount() => _queryCount();

  @override
  Future<List<ConversationItem>> queryRange(int limit, int offset) async {
    final list = await _queryRange(limit, offset);
    await mentionCache.checkMentionCache(
      list.map((e) => e.content).toSet(),
    );

    return list;
  }

  @override
  Future<bool> queryHasData() => _queryHasData();
}
