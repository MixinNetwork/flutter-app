import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

import '../../../bloc/subscribe_mixin.dart';
import '../../../db/dao/messages_dao.dart';
import '../../../db/database.dart';
import '../../../db/mixin_database.dart';
import '../../../enum/message_status.dart';
import '../../../utils/list_utils.dart';
import 'conversation_cubit.dart';

abstract class _MessageEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class _MessageInitEvent extends _MessageEvent {
  _MessageInitEvent({this.centerMessageId, this.isLatest = true});

  final String? centerMessageId;
  final bool? isLatest;

  @override
  List<Object?> get props => [centerMessageId, isLatest];
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
    this.isLatest = false,
    this.initUUID,
  });

  final String? conversationId;
  final List<MessageItem> top;
  final MessageItem? center;
  final List<MessageItem> bottom;
  final bool isLatest;
  final String? initUUID;

  @override
  List<Object?> get props => [
        conversationId,
        top,
        center,
        bottom,
        isLatest,
        initUUID,
      ];

  MessageItem? get bottomMessage =>
      bottom.lastOrNull ?? center ?? top.lastOrNull;

  MessageItem? get topMessage =>
      top.firstOrNull ?? center ?? bottom.firstOrNull;

  bool get isEmpty => top.isEmpty && center == null && bottom.isEmpty;

  MessageState copyWith({
    final String? conversationId,
    final List<MessageItem>? top,
    final MessageItem? center,
    final List<MessageItem>? bottom,
    final bool? isLatest,
    final String? initUUID,
  }) =>
      MessageState(
        conversationId: conversationId ?? this.conversationId,
        top: top ?? this.top,
        center: center ?? this.center,
        bottom: bottom ?? this.bottom,
        isLatest: isLatest ?? this.isLatest,
        initUUID: initUUID ?? this.initUUID,
      );
}

class MessageBloc extends Bloc<_MessageEvent, MessageState>
    with SubscribeMixin {
  MessageBloc({
    required this.conversationCubit,
    required this.limit,
    required this.database,
  }) : super(const MessageState()) {
    add(_MessageInitEvent());
    addSubscription(
      conversationCubit.stream
          .where((event) => event?.conversationId != null)
          .map((event) =>
              Tuple2(event?.conversationId, event?.initIndexMessageId))
          .distinct()
          .asyncMap((event) async => _MessageInitEvent(
              centerMessageId: event.item2, isLatest: event.item2 == null))
          .listen(add),
    );

    addSubscription(
      messagesDao.insertOrReplaceMessageStream
          .listen((state) => add(_MessageInsertOrReplaceEvent(state))),
    );
  }

  final ScrollController scrollController = ScrollController();
  final ConversationCubit conversationCubit;
  final Database database;
  int limit;

  MessagesDao get messagesDao => database.messagesDao;

  @override
  Stream<MessageState> mapEventToState(_MessageEvent event) async* {
    // Avoid value change
    final finalLimit = limit;

    final conversationId = conversationCubit.state?.conversationId;
    if (conversationId == null) return;
    // If the conversationId has changed, then events other than init are ignored
    if (event is! _MessageInitEvent && state.conversationId != conversationId) {
      return;
    }

    if (event is _MessageInitEvent) {
      yield await _resetMessageList(
        conversationId,
        finalLimit,
        event.centerMessageId,
      );
    } else {
      if (event is _MessageLoadMoreEvent) {
        if (event is _MessageLoadAfterEvent) {
          if (state.isLatest) return;
          yield await _after(conversationId);
        } else if (event is _MessageLoadBeforeEvent) {
          yield await _before(conversationId);
        }
      } else if (event is _MessageInsertOrReplaceEvent) {
        final result = _insertOrReplace(conversationId, event.data);
        if (result != null) yield result;
      } else if (event is _MessageScrollEvent) {
        add(_MessageInitEvent(
          centerMessageId: event.messageId,
          isLatest: false,
        ));
      }
    }
  }

  void after() => add(_MessageLoadAfterEvent());

  void before() => add(_MessageLoadBeforeEvent());

  Future<MessageState> _before(String conversationId) async {
    final topMessageId = state.topMessage?.messageId;
    assert(topMessageId != null);
    final list = await database.transaction(() async {
      final rowId = await messagesDao.messageRowId(topMessageId!).getSingle();
      return messagesDao
          .beforeMessagesByConversationId(rowId, conversationId, limit)
          .get();
    });
    final result = state.copyWith(
      top: [
        ...list.reversed.toList(),
        ...state.top,
      ],
    );
    return result;
  }

  Future<MessageState> _after(String conversationId) async {
    final bottomMessageId = state.bottomMessage?.messageId;
    assert(bottomMessageId != null);
    final list = await database.transaction(() async {
      final rowId =
          await messagesDao.messageRowId(bottomMessageId!).getSingle();
      return messagesDao
          .afterMessagesByConversationId(rowId, conversationId, limit)
          .get();
    });

    final isLatest = list.length < limit ? true : null;
    final result = state.copyWith(
      bottom: [
        ...state.bottom,
        ...list,
      ],
      isLatest: isLatest,
    );
    return result;
  }

  Future<MessageState> _resetMessageList(
    String conversationId,
    int limit, [
    String? centerMessageId,
  ]) async {
    final _centerMessageId = centerMessageId ??
        conversationCubit.state?.conversation?.lastReadMessageId;

    final state = await _messagesByConversationId(
      conversationId,
      limit,
      centerMessageId: _centerMessageId,
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
    String? centerMessageId,
  }) async {
    Future<MessageState> recentMessages() async {
      final list = await messagesDao
          .messagesByConversationId(
            conversationId,
            limit,
            0,
          )
          .get();

      return MessageState(
        top: list.reversed.toList(),
        isLatest: true,
      );
    }

    if (centerMessageId == null) return recentMessages();

    return database.transaction(() async {
      final rowId =
          await messagesDao.messageRowId(centerMessageId).getSingleOrNull();
      if (rowId == null) {
        return recentMessages();
      }
      final _limit = limit ~/ 2;
      final bottomList = await messagesDao
          .afterMessagesByConversationId(rowId, conversationId, _limit)
          .get();
      return MessageState(
          top: (await messagesDao
                  .beforeMessagesByConversationId(rowId, conversationId, _limit)
                  .get())
              .reversed
              .toList(),
          center: await messagesDao
              .messageItemByMessageId(centerMessageId)
              .getSingleOrNull(),
          bottom: bottomList,
          isLatest: bottomList.length < _limit);
    });
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

      if (state.isLatest) {
        bottom = [...bottom, item];
        newBottomMessage = true;
      } else {
        if (item.relationship == UserRelationship.me &&
            item.status == MessageStatus.sent) {
          add(_MessageInitEvent());
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

  void reload() {
    add(_MessageInitEvent());
  }

  void jumpToCurrent() {
    if (scrollController.hasClients && state.isLatest) {
      return scrollController.jumpTo(scrollController.position.maxScrollExtent);
    }
    return add(_MessageInitEvent());
  }
}
