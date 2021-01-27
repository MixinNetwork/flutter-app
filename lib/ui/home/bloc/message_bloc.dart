import 'dart:async';

import 'package:flutter_app/bloc/paging/paging_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:flutter_app/db/dao/messages_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';

class MessageBloc extends PagingBloc<MessageItem> {
  MessageBloc({
    this.conversationCubit,
    this.messagesDao,
    int limit,
    int offset = 0,
    int index = 0,
    double alignment = 0,
    void Function({int index, double alignment}) jumpTo,
  })  : conversationId = conversationCubit.state.conversationId,
        super(
          itemPositionsListener: ItemPositionsListener.create(),
          limit: limit,
          offset: offset,
          index: index,
          alignment: alignment,
          initState: const PagingState<MessageItem>(),
          jumpTo: jumpTo,
        ) {
    add(PagingInitEvent(
      offset: offset,
      index: index,
      alignment: alignment,
    ));
    addSubscription(conversationCubit.listen((state) {
      conversationId = state?.conversationId;
      if (conversationId != null)
        add(PagingInitEvent(
          offset: offset,
          index: index,
          alignment: alignment,
        ));
    }));

    addSubscription(
      messagesDao.updateEvent.listen((state) => add(PagingUpdateEvent())),
    );
  }

  final ConversationCubit conversationCubit;
  final MessagesDao messagesDao;
  String conversationId;

  @override
  Future<int> queryCount() =>
      messagesDao.messageCountByConversationId(conversationId).getSingle();

  @override
  Future<List<MessageItem>> queryRange(int limit, int offset) => messagesDao
      .messagesByConversationId(conversationId, limit, offset: offset)
      .get();
}
