import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/utils/list_utils.dart';
import 'package:flutter_app/db/dao/messages_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';

abstract class _MessageEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class _MessageInitEvent extends _MessageEvent {}

class _MessageLoadMoreEvent extends _MessageEvent {}

class _MessageLoadAfterEvent extends _MessageLoadMoreEvent {}

class _MessageLoadBeforeEvent extends _MessageLoadMoreEvent {}

class MessageState extends Equatable {
  const MessageState({
    this.top = const [],
    this.center,
    this.bottom = const [],
    this.conversationId,
    this.bottomOffset,
    this.topOffset,
  });

  final String conversationId;
  final List<MessageItem> top;
  final MessageItem center;
  final List<MessageItem> bottom;
  final int bottomOffset;
  final int topOffset;

  @override
  List<Object> get props => [
        top,
        center,
        bottom,
      ];

  MessageItem get bottomMessage =>
      bottom.lastOrNull ?? center ?? top.lastOrNull;

  MessageItem get topMessage => top.firstOrNull ?? center ?? bottom.firstOrNull;

  MessageState copyWith({
    final String conversationId,
    final List<MessageItem> top,
    final MessageItem center,
    final List<MessageItem> bottom,
    final int bottomOffset,
    final int topOffset,
  }) {
    return MessageState(
      conversationId: conversationId ?? this.conversationId,
      top: top ?? this.top,
      center: center ?? this.center,
      bottom: bottom ?? this.bottom,
      bottomOffset: bottomOffset ?? this.bottomOffset,
      topOffset: topOffset ?? this.topOffset,
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
    // Avoid value change
    final finalLimit = limit;

    final conversationId = conversationCubit.state?.conversationId;
    if (conversationId == null) return;
    // If the conversationId has changed, then events other than init are ignored
    if (!(event is _MessageInitEvent) && state.conversationId != conversationId)
      return;

    if (event is _MessageInitEvent)
      yield await _resetMessageList(conversationId, finalLimit);
    else if (event is _MessageLoadMoreEvent) {
      if (event is _MessageLoadAfterEvent) {
        if (state.bottomOffset == 0) return;
        yield await _after(conversationId);
      } else if (event is _MessageLoadBeforeEvent) {
        yield await _before(conversationId);
      }
    }
  }

  Future<MessageState> _before(String conversationId) async {
    final iterator = (await messagesDao
            .messagesByConversationId(
              conversationId,
              limit,
              state.topOffset,
            )
            .get())
        .reversed
        .iterator;
    final list = <MessageItem>[];
    final topMessageId = state.topMessage?.messageId;
    while (iterator.moveNext()) {
      if (iterator.current.messageId == topMessageId) break;
      list.add(iterator.current);
    }
    final result = state.copyWith(
      top: [
        ...list,
        ...state.top,
      ],
      topOffset: state.topOffset + list.length,
    );
    return result;
  }

  Future<MessageState> _after(String conversationId) async {
    final iterator = (await messagesDao
            .messagesByConversationId(
              conversationId,
              limit,
              state.bottomOffset - limit,
            )
            .get())
        .iterator;
    final list = <MessageItem>[];

    final bottomMessageId = state.bottomMessage?.messageId;
    while (iterator.moveNext()) {
      if (iterator.current.messageId == bottomMessageId) break;
      list.add(iterator.current);
    }
    final result = state.copyWith(
      bottom: [
        ...state.bottom,
        ...list.reversed,
      ],
      bottomOffset: state.bottomOffset - list.length,
    );
    return result;
  }

  Future<MessageState> _resetMessageList(
    String conversationId,
    int limit, [
    int centerOffset,
  ]) async {
    final _centerOffset =
        centerOffset ?? (conversationCubit.state.unseenMessageCount ?? 0) - 1;

    final state = await _messagesByConversationId(
      conversationId,
      limit,
      centerOffset: _centerOffset,
    );

    final result = state.copyWith(
      conversationId: conversationId,
      center: state.center,
      bottom: state.bottom,
      top: state.top,
    );
    return result;
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

  Future<MessageState> _messagesByConversationId(
    String conversationId,
    int limit, {
    int centerOffset,
  }) async {
    final bottomOffset = max(centerOffset - limit ~/ 2, 0);
    final list = await messagesDao
        .messagesByConversationId(
          conversationId,
          limit,
          bottomOffset,
        )
        .get();
    final topOffset = list.length + bottomOffset;

    MessageItem centerMessage;
    if (centerOffset >= 0)
      centerMessage = list.getOrNull(max(centerOffset - bottomOffset, 0));

    MessageItem center;
    final top = <MessageItem>[];
    final bottom = <MessageItem>[];
    for (final item in list.reversed) {
      if (item.messageId == centerMessage?.messageId)
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
      bottomOffset: bottomOffset,
      topOffset: topOffset,
    );
  }

  void after() => add(_MessageLoadAfterEvent());

  void before() => add(_MessageLoadBeforeEvent());
}
