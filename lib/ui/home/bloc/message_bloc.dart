import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/ui/home/bloc/conversation_list_cubit.dart';

part 'message_state.dart';

// String to enum:
//
// MessageStatus.sent == EnumToString.fromString(MessageStatus.values, 'SENT');
// MessageStatus.sent == EnumToString.fromString(MessageStatus.values, 'sent');
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
  unknown,
}

class Message extends Equatable {
  const Message({
    @required this.id,
    @required this.message,
    @required this.unread,
    @required this.createdAt,
    @required this.conversation,
    @required this.status,
    @required this.isCurrentUser,
  });

  final String id;
  final bool isCurrentUser;

  // todo message should be object
  final String message;
  final bool unread;
  final DateTime createdAt;
  final Conversation conversation;
  final MessageStatus status;

  @override
  List<Object> get props => [
        id,
        message,
        unread,
        createdAt,
        conversation,
        status,
        isCurrentUser,
      ];
}

abstract class _MessageEvent extends Equatable {
  const _MessageEvent();
}

class _InsertAllMessageEvent extends _MessageEvent {
  const _InsertAllMessageEvent(this.messages);

  final List<Message> messages;

  @override
  List<Object> get props => [messages];
}

class _ReplaceMessageEvent extends _MessageEvent {
  const _ReplaceMessageEvent(this.messages);

  final List<Message> messages;

  @override
  List<Object> get props => [messages];
}

class _InsertOrReplaceMessageEvent extends _MessageEvent {
  const _InsertOrReplaceMessageEvent(this.message);

  final Message message;

  @override
  List<Object> get props => [message];
}

class _LoadMoreMessageCubit extends Cubit<List<Message>> {
  _LoadMoreMessageCubit() : super([]);

  bool loadingMore = false;

  void loadMore(String id) {
    if (loadingMore) return;
    loadingMore = true;
    // mock loadMore
    emit(
      List.generate(
        20,
        (index) => Message(
          id: '',
          isCurrentUser: index < 10,
          conversation: null,
          createdAt: DateTime.now()
              .subtract(const Duration(minutes: 10))
              .subtract(const Duration(minutes: 1)),
          unread: false,
          status: MessageStatus.delivered,
          message: 'mock loadMore message $index',
        ),
      ),
    );
    loadingMore = false;
  }

  void mockLoadMore() {}
}

class MessageBloc extends Bloc<_MessageEvent, MessageState>
    with SubscribeMixin {
  MessageBloc([Conversation conversation]) : super(const MessageState()) {
    setConversation(conversation);
  }

  Conversation conversation;
  _LoadMoreMessageCubit loadMoreMessageCubit;

  void setConversation(Conversation conversation) {
    this.conversation = conversation;
    setupLoadMore();
    firstLoad();
  }

  @override
  Stream<MessageState> mapEventToState(
    _MessageEvent event,
  ) async* {
    final messages = state.messages ?? [];

    if (event is _ReplaceMessageEvent) {
      yield state.copyWith(
        noMoreData: false,
        messages: event.messages,
        conversation: conversation,
      );
    }
    if (event is _InsertAllMessageEvent) {
      yield state.copyWith(
        messages: messages + event.messages,
        noMoreData: messages.length < 20,
      );
      return;
    }
    if (event is _InsertOrReplaceMessageEvent) {
      final index =
          messages.indexWhere((element) => element.id == event.message.id);
      if (index >= 0) {
        messages[index] = event.message;
      } else {
        messages.insert(index, event.message);
      }
      yield state.copyWith(messages: messages);
      return;
    }
  }

  void setupLoadMore() {
    loadMoreMessageCubit?.close();
    loadMoreMessageCubit = _LoadMoreMessageCubit();
    addSubscription(loadMoreMessageCubit
        .listen((messages) => add(_InsertAllMessageEvent(messages))));
  }

  void loadMore() {
    if (state.messages?.isEmpty == true || state.noMoreData) return;
    assert(loadMoreMessageCubit != null);
    loadMoreMessageCubit?.loadMore(state.messages.last.id);
  }

  void firstLoad() {
    //mock
    add(
      _ReplaceMessageEvent(
        List.generate(
          20,
          (index) => Message(
            id: '',
            isCurrentUser: index < 10,
            conversation: null,
            createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
            unread: false,
            status: MessageStatus.delivered,
            message: 'mock first message $index',
          ),
        ),
      ),
    );
  }
}
