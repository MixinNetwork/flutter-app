import 'dart:async';

import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/bloc/paging/paging_bloc.dart';
import 'package:flutter_app/ui/home/bloc/slide_category_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moor/moor.dart';

class ConversationListBloc extends Cubit<PagingState<ConversationItem>>
    with SubscribeMixin {
  ConversationListBloc(this.slideCategoryCubit, this.database)
      : super(const PagingState<ConversationItem>()) {
    switchListBLoc(slideCategoryCubit.state);
    slideCategoryCubit.listen(switchListBLoc);
  }

  final SlideCategoryCubit slideCategoryCubit;
  final Database database;
  final Map<SlideCategoryState, _ConversationListBloc> slideListBloc = {};
  _ConversationListBloc lastListBloc;
  StreamSubscription lastStreamSubscription;

  void switchListBLoc(SlideCategoryState state) {
    switch (slideCategoryCubit.state.type) {
      case SlideCategoryType.contacts:
        slideListBloc[slideCategoryCubit.state] ??= _ConversationListBloc(
            database.conversationDao.contactConversations);
        break;
      case SlideCategoryType.groups:
        slideListBloc[slideCategoryCubit.state] ??=
            _ConversationListBloc(database.conversationDao.groupConversations);
        break;
      case SlideCategoryType.bots:
        slideListBloc[slideCategoryCubit.state] ??=
            _ConversationListBloc(database.conversationDao.botConversations);
        break;
      case SlideCategoryType.strangers:
        slideListBloc[slideCategoryCubit.state] ??= _ConversationListBloc(
            database.conversationDao.strangerConversations);
        break;
      case SlideCategoryType.circle:
        slideListBloc[slideCategoryCubit.state] ??= _ConversationListBloc(
            database.conversationDao.strangerConversations);
        break;
      default:
        break;
    }
    lastListBloc = slideListBloc[slideCategoryCubit.state] ?? lastListBloc;
    lastStreamSubscription?.cancel();
    emit(lastListBloc.state);
    lastStreamSubscription = lastListBloc.listen(emit);
  }

  void loadBefore() => lastListBloc?.loadBefore();
}

class _ConversationListBloc
    extends PagingBloc<ConversationItem, PagingState<ConversationItem>> {
  _ConversationListBloc(this.conversationList)
      : super(const PagingState<ConversationItem>());

  final Selectable<ConversationItem> Function(
      DateTime oldestCreatedAt, int limit,
      [List<String> loadedConversationId]) conversationList;

  @override
  void firstLoad() async {
    add(
      ReplacePagingEvent(
        await conversationList(
          null,
          10,
        ).get(),
      ),
    );
    addSubscription(
      conversationList(null, 1)
          .watch()
          .where((event) => event.isNotEmpty)
          .map((event) => event.single)
          .listen(
            (item) => add(InsertOrMovePagingEvent(item)),
          ),
    );
  }

  @override
  Future<List<ConversationItem>> before(List<ConversationItem> list) async {
    final result = await conversationList(
      list.last.createdAt,
      10,
      list.map((e) => e.conversationId).toList(),
    ).get();
    return result;
  }

  @override
  bool test(ConversationItem a, ConversationItem b) =>
      a?.conversationId == b?.conversationId;
}
