import 'dart:async';

import 'package:flutter_app/bloc/paging/paging_bloc.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/db/dao/messages_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/utils/multi_field_compare.dart';

part 'message_state.dart';

class MessageBloc extends PagingBloc<MessageItem, MessageState>
    with SubscribeMixin {
  MessageBloc(this.messagesDao, ConversationCubit conversationCubit, this.limit)
      : conversationId = conversationCubit.state.conversationId,
        super(const MessageState()) {
    addSubscription(conversationCubit.distinct().listen((conversation) {
      conversationId = conversation.conversationId;
      setup();
    }));
  }

  final MessagesDao messagesDao;
  int limit;
  String conversationId;

  @override
  Future<List<MessageItem>> before(List<MessageItem> list) => messagesDao
      .messageByConversationId(
        conversationId,
        limit,
        oldestCreatedAt: list.last.createdAt,
        loadedMessageId: list.map((e) => e.messageId).toList(),
      )
      .get();

  @override
  void firstLoad() async {
    add(
      ReplacePagingEvent(
        await messagesDao.messageByConversationId(conversationId, limit).get(),
      ),
    );
  }

  @override
  final List<MultiFieldCompareParameter<MessageItem>> parameters = [
    MultiFieldCompareParameter((e) => e.createdAt, true)
  ];

  @override
  bool test(MessageItem a, MessageItem b) => a.messageId == b.messageId;
}
