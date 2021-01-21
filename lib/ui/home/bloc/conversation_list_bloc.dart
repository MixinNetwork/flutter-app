import 'dart:async';

import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/db/dao/conversations_dao.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/bloc/paging/paging_bloc.dart';
import 'package:flutter_app/ui/home/bloc/slide_category_cubit.dart';
import 'package:flutter_app/utils/multi_field_compare.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moor/moor.dart';
import 'package:flutter_app/db/extension/conversation.dart';

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
          database.conversationDao,
          database.conversationDao.contactConversations,
          (c) => c.isContactConversation,
        );
        break;
      case SlideCategoryType.groups:
        slideListBloc[slideCategoryCubit.state] ??= _ConversationListBloc(
          database.conversationDao,
          database.conversationDao.groupConversations,
          (c) => c.isGroupConversation,
        );
        break;
      case SlideCategoryType.bots:
        slideListBloc[slideCategoryCubit.state] ??= _ConversationListBloc(
          database.conversationDao,
          database.conversationDao.botConversations,
          (c) => c.isBotConversation,
        );
        break;
      case SlideCategoryType.strangers:
        slideListBloc[slideCategoryCubit.state] ??= _ConversationListBloc(
          database.conversationDao,
          database.conversationDao.strangerConversations,
          (c) => c.isStrangerConversation,
        );
        break;
      case SlideCategoryType.circle:
        slideListBloc[slideCategoryCubit.state] ??= _ConversationListBloc(
          database.conversationDao,
          database.conversationDao.strangerConversations,
          (c) => c.isStrangerConversation,
        );
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
  _ConversationListBloc(
      this.conversationsDao, this.conversationList, this.filter)
      : super(const PagingState<ConversationItem>());

  final ConversationsDao conversationsDao;
  final Selectable<ConversationItem> Function(
          DateTime oldestCreatedAt, int limit, [List<String> excludeId])
      conversationList;
  final bool Function(ConversationItem conversation) filter;

  @override
  final List<MultiFieldCompareParameter<ConversationItem>> parameters = [
    MultiFieldCompareParameter((e) => e.pinTime, true),
    MultiFieldCompareParameter(
        (e) => e.lastMessageCreatedAt ?? e.createdAt, true),
  ];

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
      conversationsDao.updateConversion.where(filter).listen(
            (item) => add(InsertOrUpdatePagingEvent(item)),
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
