import 'dart:async';

import 'package:flutter_app_icon_badge/flutter_app_icon_badge.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../bloc/paging/paging_bloc.dart';
import '../../../bloc/subscribe_mixin.dart';
import '../../../db/database.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/platform.dart';
import '../../../widgets/message/item/text/mention_builder.dart';
import 'slide_category_cubit.dart';

class ConversationListBloc extends Cubit<PagingState<ConversationItem>>
    with SubscribeMixin {
  ConversationListBloc(
    this.slideCategoryCubit,
    this.database,
    this.mentionCache,
  ) : super(const PagingState<ConversationItem>()) {
    addSubscription(slideCategoryCubit.stream
        .distinct()
        .listen((event) => _switchBloc(event, limit)));
    _initBadge();
  }

  final SlideCategoryCubit slideCategoryCubit;
  final Database database;
  final MentionCache mentionCache;
  final Map<SlideCategoryState, _ConversationListBloc> _map = {};

  late int limit;
  StreamSubscription? streamSubscription;

  ItemPositionsListener itemPositionsListener(
          SlideCategoryState slideCategoryState) =>
      _map[slideCategoryState]!.itemPositionsListener;

  ItemScrollController itemScrollController(
          SlideCategoryState slideCategoryState) =>
      _map[slideCategoryState]!.itemScrollController;

  void init() => _switchBloc(slideCategoryCubit.state, limit);

  void _switchBloc(
    SlideCategoryState state,
    int limit,
  ) {
    final dao = database.conversationDao;
    switch (state.type) {
      case SlideCategoryType.chats:
      case SlideCategoryType.contacts:
      case SlideCategoryType.groups:
      case SlideCategoryType.bots:
      case SlideCategoryType.strangers:
        _map[state] ??= _ConversationListBloc(
          limit,
          () => dao.conversationCountByCategory(state.type),
          (limit, offset) =>
              dao.conversationItemsByCategory(state.type, limit, offset),
          database.conversationDao.updateEvent,
          mentionCache,
          () => dao.conversationHasDataByCategory(state.type),
        );
        break;
      case SlideCategoryType.circle:
        _map[state] ??= _ConversationListBloc(
          limit,
          () => database.conversationDao
              .conversationsCountByCircleId(state.id!)
              .getSingle(),
          (limit, offset) => database.conversationDao
              .conversationsByCircleId(state.id!, limit, offset)
              .get(),
          database.conversationDao.updateEvent,
          mentionCache,
          () =>
              database.conversationDao.conversationHasDataByCircleId(state.id!),
        );
        break;
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
        .asyncMap(updateBadge)
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
