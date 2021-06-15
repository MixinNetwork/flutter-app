import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:tuple/tuple.dart';

import '../../../bloc/subscribe_mixin.dart';
import '../../../db/dao/messages_dao.dart';
import '../../../db/database.dart';
import '../../../db/mixin_database.dart';
import '../../../enum/message_category.dart';
import '../../../enum/message_status.dart';
import '../../../utils/list_utils.dart';
import '../../../widgets/message/item/text/mention_builder.dart';
import 'conversation_cubit.dart';

abstract class _MessageEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class _MessageJumpCurrentEvent extends _MessageEvent {}

class _MessageInitEvent extends _MessageEvent {
  _MessageInitEvent({
    this.centerMessageId,
    this.lastReadMessageId,
  });

  final String? centerMessageId;
  final String? lastReadMessageId;

  @override
  List<Object?> get props => [
        centerMessageId,
        lastReadMessageId,
      ];

  @override
  final stringify = true;
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
    this.isOldest = false,
    this.lastReadMessageId,
    this.refreshKey,
  });

  final String? conversationId;
  final List<MessageItem> top;
  final MessageItem? center;
  final List<MessageItem> bottom;
  final bool isLatest;
  final bool isOldest;
  final String? lastReadMessageId;
  final Object? refreshKey;

  @override
  List<Object?> get props => [
        conversationId,
        top,
        center,
        bottom,
        isLatest,
        isOldest,
        lastReadMessageId,
        refreshKey,
      ];

  MessageItem? get bottomMessage =>
      bottom.lastOrNull ?? center ?? top.lastOrNull;

  MessageItem? get topMessage =>
      top.firstOrNull ?? center ?? bottom.firstOrNull;

  bool get isEmpty => top.isEmpty && center == null && bottom.isEmpty;

  List<MessageItem> get list => [
        ...top,
        if (center != null) center!,
        ...bottom,
      ];

  MessageState copyWith({
    final String? conversationId,
    final List<MessageItem>? top,
    final MessageItem? center,
    final List<MessageItem>? bottom,
    final bool? isLatest,
    final bool? isOldest,
    final String? lastReadMessageId,
    final Object? refreshKey,
  }) =>
      MessageState(
        conversationId: conversationId ?? this.conversationId,
        top: top ?? this.top,
        center: center ?? this.center,
        bottom: bottom ?? this.bottom,
        isLatest: isLatest ?? this.isLatest,
        isOldest: isOldest ?? this.isOldest,
        lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
        refreshKey: refreshKey ?? this.refreshKey,
      );

  MessageState _copyWithJumpCurrentState() => MessageState(
        center: null,
        bottom: const [],
        top: list.toList(),
        refreshKey: Object(),
        conversationId: conversationId,
        isLatest: isLatest,
        isOldest: isOldest,
        lastReadMessageId: lastReadMessageId,
      );
}

class MessageBloc extends Bloc<_MessageEvent, MessageState>
    with SubscribeMixin {
  MessageBloc({
    required this.conversationCubit,
    required this.limit,
    required this.database,
    required this.mentionCache,
  }) : super(const MessageState()) {
    add(_MessageInitEvent(
      centerMessageId: conversationCubit.state?.initIndexMessageId,
      lastReadMessageId: conversationCubit.state?.lastReadMessageId,
    ));
    addSubscription(
      conversationCubit.stream
          .where((event) => event?.conversationId != null)
          .map((event) => Tuple4(
                event?.conversationId,
                event?.initIndexMessageId,
                event?.lastReadMessageId,
                event?.refreshKey,
              ))
          .distinct()
          .asyncMap(
            (event) async => _MessageInitEvent(
              centerMessageId: event.item2,
              lastReadMessageId: event.item3,
            ),
          )
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
  final MentionCache mentionCache;
  int limit;

  MessagesDao get messagesDao => database.messagesDao;

  Future<void> _preCacheMention(MessageState state) async {
    final set = {...state.top, state.center, ...state.bottom};
    await mentionCache.checkMentionCache(
      {...set.map((e) => e?.content), ...set.map((e) => e?.quoteContent)}
          .where((element) => element != null)
          .cast<String>()
          .toSet(),
    );
  }

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
      final messageState = await _resetMessageList(
        conversationId,
        finalLimit,
        event.centerMessageId,
      );
      await _preCacheMention(messageState);
      yield _pretreatment(messageState.copyWith(
        refreshKey: Object(),
        lastReadMessageId: event.lastReadMessageId,
      ));
    } else {
      if (event is _MessageLoadMoreEvent) {
        if (event is _MessageLoadAfterEvent) {
          if (state.isLatest) return;
          final messageState = await _after(conversationId);
          await _preCacheMention(messageState);
          yield _pretreatment(messageState);
        } else if (event is _MessageLoadBeforeEvent) {
          if (state.isOldest) return;
          final messageState = await _before(conversationId);
          await _preCacheMention(messageState);
          yield _pretreatment(messageState);
        }
      } else if (event is _MessageInsertOrReplaceEvent) {
        final result = _insertOrReplace(conversationId, event.data);
        if (result != null) {
          await _preCacheMention(result);
          yield _pretreatment(result);
        }
      } else if (event is _MessageScrollEvent) {
        add(_MessageInitEvent(
          centerMessageId: event.messageId,
          lastReadMessageId: state.lastReadMessageId,
        ));
      } else if (event is _MessageJumpCurrentEvent) {
        yield _pretreatment(state._copyWithJumpCurrentState());
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

    final isOldest = list.length < limit;
    final result = state.copyWith(
      top: [
        ...list.reversed.toList(),
        ...state.top,
      ],
      isOldest: isOldest,
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
      final topList = (await messagesDao
              .beforeMessagesByConversationId(rowId, conversationId, _limit)
              .get())
          .reversed
          .toList();
      return MessageState(
        top: topList,
        center: await messagesDao
            .messageItemByMessageId(centerMessageId)
            .getSingleOrNull(),
        bottom: bottomList,
        isLatest: bottomList.length < _limit,
        isOldest: topList.length < _limit,
      );
    });
  }

  MessageState? _insertOrReplace(
      String conversationId, List<MessageItem> list) {
    final top = state.top.toList();
    var center = state.center;
    var bottom = state.bottom.toList();

    final bottomMessage = state.bottomMessage;
    var jumpToBottom = false;
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

      final currentUserSent = item.relationship == UserRelationship.me;

      if (state.isLatest) {
        bottom = [...bottom, item];
        final position = scrollController.position;
        jumpToBottom = currentUserSent ||
            (position.hasContentDimensions &&
                position.pixels == position.maxScrollExtent);
      } else {
        if (currentUserSent) {
          add(_MessageInitEvent());
          return null;
        }
      }
    }

    final result = state.copyWith(
      top: top,
      center: center,
      bottom: bottom,
    );

    if (scrollController.hasClients && jumpToBottom) {
      return result._copyWithJumpCurrentState();
    }
    return result;
  }

  void scrollTo(String messageId) =>
      add(_MessageScrollEvent(messageId: messageId));

  void reload() {
    add(_MessageInitEvent());
  }

  void jumpToCurrent() {
    if (scrollController.hasClients && state.isLatest) {
      return add(_MessageJumpCurrentEvent());
    }
    return add(_MessageInitEvent());
  }

  MessageState _pretreatment(MessageState messageState) {
    List<MessageItem>? top;
    // check secretMessage
    if (messageState.isOldest && conversationCubit.state?.isBot == false) {
      if (messageState.top.firstOrNull?.type == MessageCategory.secret) {
        messageState.top.remove(messageState.top.first);
      }

      top = [
        MessageItem(
          sharedUserIdentityNumber: '',
          status: MessageStatus.read,
          messageId: '',
          conversationId: '',
          userIdentityNumber: '',
          participantUserId: '',
          userId: '',
          type: MessageCategory.secret,
          createdAt: messageState.topMessage?.createdAt ?? DateTime.now(),
        ),
        ...messageState.top,
      ];
    }
    return messageState.copyWith(
      top: top,
    );
  }
}
