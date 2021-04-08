import 'dart:async';

import 'package:flutter_app/bloc/paging/paging_bloc.dart';
import 'package:flutter_app/db/dao/messages_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class SearchMessageBloc extends PagingBloc<SearchMessageDetailItem> {
  SearchMessageBloc(
    int limit,
    this.messagesDao,
    this.keyword,
  ) : super(
          initState: const PagingState<SearchMessageDetailItem>(),
          itemPositionsListener: ItemPositionsListener.create(),
          limit: limit,
        ) {
    addSubscription(messagesDao.searchMessageUpdateEvent
        .listen((event) => add(PagingUpdateEvent())));
  }

  final MessagesDao messagesDao;
  final String keyword;

  @override
  Future<int> queryCount() =>
      messagesDao.fuzzySearchMessageCount(keyword).getSingle();

  @override
  Future<List<SearchMessageDetailItem>> queryRange(int limit, int offset) =>
      messagesDao
          .fuzzySearchMessage(query: keyword, limit: limit, offset: offset)
          .get();
}
