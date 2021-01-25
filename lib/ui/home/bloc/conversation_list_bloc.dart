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

class ConversationListManagerBloc extends Cubit<Set<SlideCategoryState>>
    with SubscribeMixin {
  ConversationListManagerBloc(SlideCategoryCubit slideCategoryCubit)
      : super(const {}) {
    addSubscription(slideCategoryCubit.listen((event) {
      emit({...state, event});
    }));
  }

  static ConversationListBloc createBloc(
    SlideCategoryState state,
    int limit,
    ItemPositionsListener itemPositionsListener,
    Database database,
  ) {
    switch (state.type) {
      case SlideCategoryType.contacts:
        return ConversationListBloc(
          limit,
          itemPositionsListener,
          () => database.conversationDao.contactConversationCount().getSingle(),
          (limit, offset) => database.conversationDao
              .contactConversations(limit, offset)
              .get(),
        );
        break;
      case SlideCategoryType.groups:
        return ConversationListBloc(
          limit,
          itemPositionsListener,
          () => database.conversationDao.groupConversationCount().getSingle(),
          (limit, offset) =>
              database.conversationDao.groupConversations(limit, offset).get(),
        );
      case SlideCategoryType.bots:
        return ConversationListBloc(
          limit,
          itemPositionsListener,
          () => database.conversationDao.botConversationCount().getSingle(),
          (limit, offset) =>
              database.conversationDao.botConversations(limit, offset).get(),
        );
        break;
      case SlideCategoryType.strangers:
        return ConversationListBloc(
          limit,
          itemPositionsListener,
          () async {
            final count = await database.conversationDao
                .strangerConversationCount()
                .getSingle();
            print('count: $count');
            return count;
          },
          (limit, offset) async {
            try {
              final list = await database.conversationDao
                  .strangerConversations(limit, offset)
                  .get();
              print('length: ${list.length}, limit: $limit, offset: $offset');
              return list;
            } on Exception catch (e) {
              print(e);
            }
          },
        );

      case SlideCategoryType.circle:
        return ConversationListBloc(
          limit,
          itemPositionsListener,
          () =>
              database.conversationDao.strangerConversationCount().getSingle(),
          (limit, offset) => database.conversationDao
              .strangerConversations(limit, offset)
              .get(),
        );
      default:
        return null;
        break;
    }
  }
}

class ConversationListBloc extends PagingBloc<ConversationItem> {
  ConversationListBloc(
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
