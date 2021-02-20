import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';

import 'package:flutter_app/db/dao/messages_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';

abstract class _MessageEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class _MessageInitEvent extends _MessageEvent {}

class MessageState extends Equatable {
  const MessageState({
    this.top = const [],
    this.center,
    this.bottom = const [],
    this.conversationId,
  });

  final String conversationId;
  final List<MessageItem> top;
  final MessageItem center;
  final List<MessageItem> bottom;

  @override
  List<Object> get props => [
        top,
        center,
        bottom,
      ];

  MessageState copyWith({
    final String conversationId,
    final List<MessageItem> top,
    final MessageItem center,
    final List<MessageItem> bottom,
  }) {
    return MessageState(
      conversationId: conversationId ?? this.conversationId,
      top: top ?? this.top,
      center: center ?? this.center,
      bottom: bottom ?? this.bottom,
    );
  }
}

class MessageBloc extends Bloc<_MessageEvent, MessageState>
    with SubscribeMixin {
  MessageBloc({
    this.conversationCubit,
    this.messagesDao,
    this.limit,
  }) : super(const MessageState()) {
    var conversationId = conversationCubit.state.conversationId;

    add(_MessageInitEvent());
    addSubscription(
      conversationCubit.listen(
        (state) {
          if (state?.conversationId != null &&
              conversationId != state?.conversationId) {
            conversationId = state?.conversationId;
            add(_MessageInitEvent());
          }
        },
      ),
    );

    // addSubscription(
    //   messagesDao.updateEvent.listen((state) => add(PagingUpdateEvent())),
    // );
  }

  final ConversationCubit conversationCubit;
  final MessagesDao messagesDao;
  int limit;

  @override
  Stream<MessageState> mapEventToState(_MessageEvent event) async* {
    if (event is _MessageInitEvent) {
      final unseenMessageCount = conversationCubit.state.unseenMessageCount;
      final lastReadMessageId = conversationCubit.state.lastReadMessageId;
      final conversationId = conversationCubit.state.conversationId;

      final state = await messagesByConversationId(
        conversationId,
        offset: unseenMessageCount,
        centerMessageId: lastReadMessageId,
      );

      yield state.copyWith(
        conversationId: conversationId,
        center: state.center,
        bottom: state.bottom,
        top: state.top,
      );
    }
  }

  Future<int> getCenterMessageOffset(String lastReadMessageId) async {
    var offset = 0;
    if (lastReadMessageId != null)
      offset = (await messagesDao
              .messageRowIdByConversationId(lastReadMessageId)
              .get())
          .firstWhere(
        (element) => element > 0,
        orElse: () => 0,
      );
    return offset;
  }

  Future<MessageState> messagesByConversationId(
    String conversationId, {
    int offset,
    String centerMessageId,
  }) async {
    final centerLimit = limit ~/ 2;
    final list = await messagesDao
        .messagesByConversationId(
          conversationId,
          limit,
          offset: max(offset - centerLimit, 0),
        )
        .get();

    MessageItem center;
    final top = <MessageItem>[];
    final bottom = <MessageItem>[];
    for (final item in list.reversed) {
      if (item.messageId == centerMessageId)
        center = item;
      else if (center == null)
        top.add(item);
      else
        bottom.add(item);
    }

    return MessageState(
      top: top,
      center: center,
      bottom: bottom,
    );
  }
}
