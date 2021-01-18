import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';

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
    @required this.user,
    @required this.message,
    @required this.unread,
    @required this.createdAt,
    @required this.conversation,
    @required this.status,
    @required this.isCurrentUser,
  });

  final String user;
  final String id;
  final bool isCurrentUser;

  // todo message should be object
  final String message;
  final bool unread;
  final DateTime createdAt;
  final ConversationItem conversation;
  final MessageStatus status;

  @override
  List<Object> get props => [
        id,
        user,
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

class _LoadMoreMessageEvent extends _MessageEvent {
  const _LoadMoreMessageEvent(this.messages);

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
          user: 'loadMore user name',
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
  MessageBloc(ConversationCubit conversationCubit)
      : super(const MessageState()) {
    _setConversation(conversationCubit.state.conversationId);
    addSubscription(conversationCubit.listen(
        (conversation) => _setConversation(conversation.conversationId)));
  }

  String _conversationId;
  _LoadMoreMessageCubit loadMoreMessageCubit;

  void _setConversation(String conversationId) {
    if (_conversationId == conversationId) return;
    _conversationId = conversationId;
    setupLoadMore();
    if (_conversationId != null) firstLoad();
  }

  @override
  Stream<MessageState> mapEventToState(
    _MessageEvent event,
  ) async* {
    final messages = state.messages?.toList() ?? [];

    if (event is _ReplaceMessageEvent) {
      yield state.copyWith(
        noMoreData: false,
        messages: event.messages,
        conversationId: _conversationId,
      );
    }
    if (event is _LoadMoreMessageEvent) {
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
        messages.insert(0, event.message);
      }
      yield state.copyWith(messages: messages);
      return;
    }
  }

  void setupLoadMore() {
    loadMoreMessageCubit?.close();
    loadMoreMessageCubit = _LoadMoreMessageCubit();
    addSubscription(loadMoreMessageCubit
        .listen((messages) => add(_LoadMoreMessageEvent(messages))));
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
            user: '$_conversationId name',
            isCurrentUser: index < 10,
            conversation: null,
            createdAt: DateTime.now().subtract(Duration(hours: index)),
            unread: false,
            status: MessageStatus.delivered,
            message: 'mock first message $index',
          ),
        ),
      ),
    );
  }

  void send(String text) {
    add(
      _InsertOrReplaceMessageEvent(
        Message(
          id: text,
          user: 'conversation',
          isCurrentUser: true,
          conversation: null,
          createdAt: DateTime.now(),
          unread: false,
          status: MessageStatus.delivered,
          message: text,
        ),
      ),
    );
  }
}
