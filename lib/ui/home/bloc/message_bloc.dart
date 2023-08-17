// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:rxdart/rxdart.dart';

import '../../../account/account_server.dart';
import '../../../bloc/subscribe_mixin.dart';
import '../../../db/dao/message_dao.dart';
import '../../../db/database.dart';
import '../../../db/database_event_bus.dart';
import '../../../db/mixin_database.dart';
import '../../../enum/message_category.dart';
import '../../../utils/app_lifecycle.dart';
import '../../../utils/extension/extension.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/mention_cache_provider.dart';

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

class _MessageDeleteEvent extends _MessageEvent {
  _MessageDeleteEvent(this.messageId);

  final String messageId;

  @override
  List<Object> get props => [messageId];
}

class MessageState extends Equatable {
  MessageState({
    this.top = const [],
    this.center,
    this.bottom = const [],
    this.conversationId,
    this.isLatest = false,
    this.isOldest = false,
    this.lastReadMessageId,
    this.refreshKey,
  }) {
    // check top, center, bottom didn't has same messageId
    assert(() {
      final ids = <String>{};
      for (final item in list) {
        if (ids.contains(item.messageId)) {
          e('MessageState has same messageId: ${item.messageId}');
        }
        ids.add(item.messageId);
      }
      return true;
    }());
  }

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
    String? conversationId,
    List<MessageItem>? top,
    MessageItem? center,
    List<MessageItem>? bottom,
    bool? isLatest,
    bool? isOldest,
    String? lastReadMessageId,
    Object? refreshKey,
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
        top: list.toList(),
        refreshKey: Object(),
        conversationId: conversationId,
        isLatest: isLatest,
        isOldest: isOldest,
        lastReadMessageId: lastReadMessageId,
      );

  MessageState removeMessage(String messageId) {
    if (center?.messageId == messageId) {
      return MessageState(
        conversationId: conversationId,
        top: top,
        bottom: bottom,
        isLatest: isLatest,
        isOldest: isOldest,
        lastReadMessageId: lastReadMessageId,
        refreshKey: refreshKey,
      );
    }

    bool include(MessageItem message) => message.messageId == messageId;
    bool exclusive(MessageItem message) => message.messageId != messageId;

    if (top.any(include)) {
      return copyWith(
        top: top.where(exclusive).toList(),
      );
    }

    if (bottom.any(include)) {
      return copyWith(
        bottom: bottom.where(exclusive).toList(),
      );
    }

    // ignore: avoid_returning_this
    return this;
  }
}

class MessageBloc extends Bloc<_MessageEvent, MessageState>
    with SubscribeMixin {
  MessageBloc({
    required this.conversationNotifier,
    required this.limit,
    required this.database,
    required this.mentionCache,
    required this.accountServer,
  }) : super(MessageState()) {
    on<_MessageEvent>(
      (event, emit) async {
        await _onEvent(event, emit);
      },
      transformer: sequential(),
    );

    add(_MessageInitEvent(
      centerMessageId: conversationNotifier.state?.initIndexMessageId,
      lastReadMessageId: conversationNotifier.state?.lastReadMessageId,
    ));
    addSubscription(
      conversationNotifier.stream
          .where((event) => event?.conversationId != null)
          .map((event) => (
                event?.conversationId,
                event?.initIndexMessageId,
                event?.lastReadMessageId,
                event?.refreshKey,
              ))
          .distinct()
          .asyncMap(
            (event) async => _MessageInitEvent(
              centerMessageId: event.$2,
              lastReadMessageId: event.$3,
            ),
          )
          .listen(add),
    );

    addSubscription(
      conversationNotifier.stream
          .map((event) => event?.conversationId)
          .distinct()
          .switchMap((conversationId) {
        if (conversationId == null) {
          return const Stream<List<MessageItem>>.empty();
        }
        return messageDao.watchInsertOrReplaceMessageStream(conversationId);
      }).listen((state) => add(_MessageInsertOrReplaceEvent(state))),
    );

    addSubscription(
        DataBaseEventBus.instance.deleteMessageIdStream.listen((messageIds) {
      messageIds.forEach((messageId) {
        add(_MessageDeleteEvent(messageId));
      });
    }));
  }

  final ScrollController scrollController = ScrollController();
  final ConversationStateNotifier conversationNotifier;
  final Database database;
  final MentionCache mentionCache;
  final AccountServer accountServer;
  int limit;

  MessageDao get messageDao => database.messageDao;

  Future<void> _preCacheMention(MessageState state) async {
    final set = {...state.top, state.center, ...state.bottom};
    await mentionCache.checkMentionCache(
      {...set.map((e) => e?.content), ...set.map((e) => e?.quoteContent)}
          .whereNotNull()
          .toSet(),
    );
  }

  Future<void> _onEvent(_MessageEvent event, Emitter<MessageState> emit) async {
    // Avoid value change
    final finalLimit = limit;

    final conversationId = conversationNotifier.state?.conversationId;
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
      emit(_pretreatment(messageState.copyWith(
        refreshKey: Object(),
        lastReadMessageId: event.lastReadMessageId,
      )));
    } else if (event is _MessageDeleteEvent) {
      final messageState = state.removeMessage(event.messageId);
      emit(_pretreatment(messageState));
    } else {
      if (event is _MessageLoadMoreEvent) {
        if (event is _MessageLoadAfterEvent) {
          if (state.isLatest) return;
          final messageState = await _after(conversationId);
          await _preCacheMention(messageState);
          emit(_pretreatment(messageState));
        } else if (event is _MessageLoadBeforeEvent) {
          if (state.isOldest) return;
          final messageState = await _before(conversationId);
          await _preCacheMention(messageState);
          emit(_pretreatment(messageState));
        }
      } else if (event is _MessageInsertOrReplaceEvent) {
        final result = _insertOrReplace(conversationId, event.data);
        if (result != null) {
          await _preCacheMention(result);
          emit(_pretreatment(result));
        }
      } else if (event is _MessageScrollEvent) {
        add(_MessageInitEvent(
          centerMessageId: event.messageId,
          lastReadMessageId: state.lastReadMessageId,
        ));
      } else if (event is _MessageJumpCurrentEvent) {
        emit(_pretreatment(state._copyWithJumpCurrentState()));
      }
    }
  }

  void after() => add(_MessageLoadAfterEvent());

  void before() => add(_MessageLoadBeforeEvent());

  Future<MessageState> _before(String conversationId) async {
    final topMessageId = state.topMessage?.messageId;
    assert(topMessageId != null);
    final info = await messageDao.messageOrderInfo(topMessageId!);
    final list = await messageDao
        .beforeMessagesByConversationId(info!, conversationId, limit)
        .get();

    final isOldest = list.length < limit;
    return state
        .copyWith(top: [...list.reversed, ...state.top], isOldest: isOldest);
  }

  Future<MessageState> _after(String conversationId) async {
    final bottomMessageId = state.bottomMessage?.messageId;
    assert(bottomMessageId != null);
    final info = await messageDao.messageOrderInfo(bottomMessageId!);
    final list = await messageDao
        .afterMessagesByConversationId(info!, conversationId, limit)
        .get();

    final isLatest = list.length < limit ? true : null;
    return state
        .copyWith(bottom: [...state.bottom, ...list], isLatest: isLatest);
  }

  Future<MessageState> _resetMessageList(
    String conversationId,
    int limit, [
    String? centerMessageId,
  ]) async {
    final conversation = conversationNotifier.state?.conversation;
    final _centerMessageId = centerMessageId ??
        ((conversation?.unseenMessageCount ?? 0) > 0
            ? conversation?.lastReadMessageId
            : null);

    final state = await _messagesByConversationId(
      conversationId,
      limit,
      centerMessageId: _centerMessageId,
    );

    return state.copyWith(
        conversationId: conversationId,
        center: state.center,
        bottom: state.bottom,
        top: state.top);
  }

  Future<MessageState> _messagesByConversationId(
    String conversationId,
    int limit, {
    String? centerMessageId,
  }) async {
    Future<MessageState> recentMessages() async {
      final list = await messageDao
          .messagesByConversationId(
            conversationId,
            limit,
          )
          .get();

      return MessageState(
        top: list.reversed.toList(),
        isLatest: true,
        isOldest: list.length < limit,
      );
    }

    if (centerMessageId == null) return recentMessages();

    return database.transaction(() async {
      final info = await messageDao.messageOrderInfo(centerMessageId);
      if (info == null) {
        return recentMessages();
      }
      final _limit = limit ~/ 2;
      final bottomList = await messageDao
          .afterMessagesByConversationId(info, conversationId, _limit)
          .get();
      var topList = (await messageDao
              .beforeMessagesByConversationId(info, conversationId, _limit)
              .get())
          .reversed
          .toList();

      final isLatest = bottomList.length < _limit;
      final isOldest = topList.length < _limit;

      var center = await messageDao
          .messageItemByMessageId(centerMessageId)
          .getSingleOrNull();

      if (bottomList.isEmpty && center != null) {
        topList = [...topList, center];
        center = null;
      }

      return MessageState(
        top: topList,
        center: center,
        bottom: bottomList,
        isLatest: isLatest,
        isOldest: isOldest,
      );
    });
  }

  MessageState? _insertOrReplace(
      String conversationId, List<MessageItem> list) {
    var top = state.top.toList();
    var center = state.center;
    var bottom = state.bottom.toList();

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

      // if don't have messages or older message after then valid item
      if (state.topMessage?.type != MessageCategory.secret &&
          (state.topMessage?.createdAt.isAfter(item.createdAt) ?? false)) {
        continue;
      }

      final currentUserSent = item.relationship == UserRelationship.me;

      if (state.isLatest) {
        if (center?.createdAt.isBefore(item.createdAt) ?? true) {
          bottom = [...bottom, item]
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        } else {
          top = [item, ...top]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
        final position = scrollController.position;
        jumpToBottom = currentUserSent ||
            (position.hasContentDimensions &&
                position.pixels == position.maxScrollExtent);
      } else {
        if (currentUserSent && item.status == MessageStatus.sending) {
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
    if (messageState.isOldest && conversationNotifier.state?.isBot == false) {
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
          pinned: false,
        ),
        ...messageState.top,
      ];
    }
    final _messageState = messageState.copyWith(
      top: top,
    );
    if (isAppActive) {
      accountServer.markRead(conversationNotifier.state!.conversationId);
    }
    return _messageState;
  }
}
