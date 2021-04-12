import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/enum/message_status.dart';
import 'package:flutter_app/utils/list_utils.dart';
import 'package:flutter_app/db/dao/messages_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';

abstract class _MessageEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class _MessageInitEvent extends _MessageEvent {
  _MessageInitEvent({this.centerOffset});

  final int? centerOffset;

  @override
  List<Object?> get props => [centerOffset];
}

class _MessageScrollEvent extends _MessageEvent {
  _MessageScrollEvent({required this.messageId});

  final String messageId;

  @override
  List<Object?> get props => [messageId];
}

class _MessageLoadMoreEvent extends _MessageEvent {}

class _MessageLoadAfterEvent extends _MessageLoadMoreEvent {}

class _MessageLoadBeforeEvent extends _MessageLoadMoreEvent {}

class _MessageInsertOrReplaceEvent extends _MessageEvent {
  _MessageInsertOrReplaceEvent(this.data);

  final List<MessageItem> data;

  @override
  List<Object> get props => [data];
}

class MessageState extends Equatable {
  const MessageState({
    this.top = const [],
    this.center,
    this.bottom = const [],
    this.conversationId,
    this.bottomOffset = 0,
    this.topOffset = 0,
    this.initUUID,
  });

  final String? conversationId;
  final List<MessageItem> top;
  final MessageItem? center;
  final List<MessageItem> bottom;
  final int bottomOffset;
  final int topOffset;
  final String? initUUID;

  @override
  List<Object?> get props => [
        conversationId,
        top,
        center,
        bottom,
        bottomOffset,
        topOffset,
        initUUID,
      ];

  MessageItem? get bottomMessage =>
      bottom.lastOrNull ?? center ?? top.lastOrNull;

  MessageItem? get topMessage =>
      top.firstOrNull ?? center ?? bottom.firstOrNull;

  MessageState copyWith({
    final String? conversationId,
    final List<MessageItem>? top,
    final MessageItem? center,
    final List<MessageItem>? bottom,
    final int? bottomOffset,
    final int? topOffset,
    final String? initUUID,
  }) {
    return MessageState(
      conversationId: conversationId ?? this.conversationId,
      top: top ?? this.top,
      center: center ?? this.center,
      bottom: bottom ?? this.bottom,
      bottomOffset: bottomOffset ?? this.bottomOffset,
      topOffset: topOffset ?? this.topOffset,
      initUUID: initUUID ?? this.initUUID,
    );
  }
}

class MessageBloc extends Bloc<_MessageEvent, MessageState>
    with SubscribeMixin {
  MessageBloc({
    required this.conversationCubit,
    required this.messagesDao,
    required this.limit,
  }) : super(const MessageState()) {
    var conversationId = conversationCubit.state?.conversationId;

    add(_MessageInitEvent());
    addSubscription(
      conversationCubit.stream.listen(
        (state) {
          if (state?.conversationId != null &&
              conversationId != state?.conversationId) {
            conversationId = state?.conversationId;
            add(_MessageInitEvent());
          }
        },
      ),
    );

    addSubscription(
      messagesDao.insertOrReplaceMessageStream
          .listen((state) => add(_MessageInsertOrReplaceEvent(state))),
    );
  }

  final ScrollController scrollController = ScrollController();
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

    if (event is _MessageInitEvent) {
      yield await _resetMessageList(
        conversationId,
        finalLimit,
        event.centerOffset,
      );
      conversationCubit.initIndex = null;
    } else {
      if (event is _MessageLoadMoreEvent) {
        if (event is _MessageLoadAfterEvent) {
          if (state.bottomOffset == 0) return;
          yield await _after(conversationId);
        } else if (event is _MessageLoadBeforeEvent) {
          yield await _before(conversationId);
        }
      } else if (event is _MessageInsertOrReplaceEvent) {
        final result = _insertOrReplace(conversationId, event.data);
        if (result != null) yield result;
      } else if (event is _MessageScrollEvent) {
        final index = await messagesDao
            .messageIndex(conversationId, event.messageId)
            .getSingleOrNull();
        if (index != null) add(_MessageInitEvent(centerOffset: index));
      }
    }
  }

  void after() => add(_MessageLoadAfterEvent());

  void before() => add(_MessageLoadBeforeEvent());

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
    int? centerOffset,
  ]) async {
    final _centerOffset = centerOffset ??
        conversationCubit.initIndex ??
        (conversationCubit.state?.unseenMessageCount ?? 0) - 1;

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
      initUUID: const Uuid().v4(),
    );
    return result;
  }

  Future<MessageState> _messagesByConversationId(
    String conversationId,
    int limit, {
    int centerOffset = 0,
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

    MessageItem? centerMessage;
    if (centerOffset >= 0)
      centerMessage = list.getOrNull(max(centerOffset - bottomOffset, 0));

    MessageItem? center;
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

  MessageState? _insertOrReplace(
      String conversationId, List<MessageItem> list) {
    final top = state.top.toList();
    var center = state.center;
    var bottom = state.bottom.toList();

    final bottomMessage = state.bottomMessage;
    var newBottomMessage = false;
    for (final item in list) {
      if (item.conversationId != conversationId) continue;

      if (item.messageId == center?.messageId) {
        center = item;
        continue;
      }

      final topIndex =
          top.indexWhere((element) => element.messageId == item.messageId);
      if (topIndex > -1) {
        top[topIndex] = item;
        continue;
      }

      final bottomIndex =
          bottom.indexWhere((element) => element.messageId == item.messageId);
      if (bottomIndex > -1) {
        bottom[bottomIndex] = item;
        continue;
      }

      // New message must be after last bottom message.
      if (bottomMessage != null &&
          bottomMessage.createdAt.isAfter(item.createdAt)) continue;

      if (state.bottomOffset == 0) {
        bottom = [...bottom, item];
        newBottomMessage = true;
      } else {
        if (item.relationship == UserRelationship.me &&
            item.status == MessageStatus.sent) {
          add(_MessageInitEvent(centerOffset: 0));
          return null;
        }
      }
    }

    if (scrollController.hasClients && newBottomMessage) {
      final position = scrollController.position;
      final oldMaxScrollExtent = position.maxScrollExtent;
      final oldPixels = position.pixels;
      if (oldPixels == oldMaxScrollExtent) {
        WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
          if (!scrollController.hasClients) return;
          final newMaxScrollExtent = position.maxScrollExtent;
          final newPixels = position.pixels;
          if (newMaxScrollExtent != oldMaxScrollExtent &&
              newMaxScrollExtent != newPixels) {
            scrollController.jumpTo(newMaxScrollExtent);
          }
        });
      }
    }
    return state.copyWith(
      top: top,
      center: center,
      bottom: bottom,
    );
  }

  void scrollTo(String messageId) =>
      add(_MessageScrollEvent(messageId: messageId));
}
