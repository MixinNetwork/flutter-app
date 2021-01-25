import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/bloc/paging/paging_bloc.dart';
import 'package:flutter_app/ui/home/bloc/slide_category_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moor/moor.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ConversationListBloc extends Cubit<PagingState<ConversationItem>>
    with SubscribeMixin {
  ConversationListBloc(this.slideCategoryCubit, this.database)
      : super(const PagingState<ConversationItem>()) {
    addSubscription(slideCategoryCubit
        .distinct()
        .listen((event) => _switchBloc(slideCategoryCubit.state, limit)));
  }

  final SlideCategoryCubit slideCategoryCubit;
  final Database database;
  final Map<SlideCategoryState, _ConversationListBloc> _map = {};

  int limit;
  StreamSubscription streamSubscription;

  ItemPositionsListener get itemPositionsListener =>
      _map[slideCategoryCubit.state].itemPositionsListener;

  void init() => _switchBloc(slideCategoryCubit.state, limit);

  void _switchBloc(
    SlideCategoryState state,
    int limit,
  ) {
    switch (state.type) {
      case SlideCategoryType.contacts:
        _map[state] ??= _ConversationListBloc(
          limit,
          ItemPositionsListener.create(),
          () => database.conversationDao.contactConversationCount().getSingle(),
          (limit, offset) => database.conversationDao
              .contactConversations(limit, offset)
              .get(),
        );
        break;
      case SlideCategoryType.groups:
        _map[state] ??= _ConversationListBloc(
          limit,
          ItemPositionsListener.create(),
          () => database.conversationDao.groupConversationCount().getSingle(),
          (limit, offset) =>
              database.conversationDao.groupConversations(limit, offset).get(),
        );
        break;
      case SlideCategoryType.bots:
        _map[state] ??= _ConversationListBloc(
          limit,
          ItemPositionsListener.create(),
          () => database.conversationDao.botConversationCount().getSingle(),
          (limit, offset) =>
              database.conversationDao.botConversations(limit, offset).get(),
        );
        break;
      case SlideCategoryType.strangers:
        _map[state] ??= _ConversationListBloc(
          limit,
          ItemPositionsListener.create(),
          () =>
              database.conversationDao.strangerConversationCount().getSingle(),
          (limit, offset) => database.conversationDao
              .strangerConversations(limit, offset)
              .get(),
        );
        break;
      case SlideCategoryType.circle:
        _map[state] ??= _ConversationListBloc(
          limit,
          ItemPositionsListener.create(),
          () =>
              database.conversationDao.strangerConversationCount().getSingle(),
          (limit, offset) => database.conversationDao
              .strangerConversations(limit, offset)
              .get(),
        );
        break;
      default:
        return null;
        break;
    }
    final bloc = _map[state];
    emit(bloc.state);
    streamSubscription?.cancel();
    streamSubscription = bloc.listen(emit);
  }
}

class _ConversationListBloc extends PagingBloc<ConversationItem> {
  _ConversationListBloc(
    int limit,
    ItemPositionsListener itemPositionsListener,
    // ignore: invalid_required_positional_param
    @required Future<int> Function() queryCount,
    // ignore: invalid_required_positional_param
    @required
        Future<List<ConversationItem>> Function(int limit, int offset)
            queryRange,
  )   : assert(queryCount != null),
        assert(queryRange != null),
        _queryCount = queryCount,
        _queryRange = queryRange,
        super(
          initState: const PagingState<ConversationItem>(),
          itemPositionsListener: itemPositionsListener,
          limit: limit,
        );

  final Future<int> Function() _queryCount;

  final Future<List<ConversationItem>> Function(int limit, int offset)
      _queryRange;

  @override
  Future<int> queryCount() => _queryCount();

  @override
  Future<List<ConversationItem>> queryRange(int limit, int offset) =>
      _queryRange(limit, offset);
}
