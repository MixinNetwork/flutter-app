import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:rxdart/rxdart.dart';

import '../../../account/account_server.dart';
import '../../../db/dao/message_dao.dart';
import '../../../db/database.dart';
import '../../../db/database_event_bus.dart';
import '../../../db/mixin_database.dart';
import '../../../enum/message_category.dart';
import '../../../utils/app_lifecycle.dart';
import '../../../utils/extension/extension.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/mention_cache_provider.dart';
import '../chat/chat_jump_trace.dart';

part 'message_window_loader.dart';

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
    ?center,
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
  }) => MessageState(
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
      return copyWith(top: top.where(exclusive).toList());
    }

    if (bottom.any(include)) {
      return copyWith(bottom: bottom.where(exclusive).toList());
    }

    return this;
  }
}

class MessageController extends ValueNotifier<MessageState> {
  MessageController({
    required this.conversationNotifier,
    required this.limit,
    required this.database,
    required this.mentionCache,
    required this.accountServer,
  }) : super(MessageState()) {
    _init(
      centerMessageId: conversationNotifier.state?.initIndexMessageId,
      lastReadMessageId: conversationNotifier.state?.lastReadMessageId,
    );

    _subscriptions
      ..add(
        conversationNotifier.stream
            .where((event) => event?.conversationId != null)
            .map(
              (event) => (
                event?.conversationId,
                event?.initIndexMessageId,
                event?.lastReadMessageId,
                event?.refreshKey,
                event?.forceLatestKey,
              ),
            )
            .distinct()
            .listen(
              (event) => _init(
                centerMessageId: event.$2,
                lastReadMessageId: event.$3,
                forceLatest: event.$5 != null,
              ),
            ),
      )
      ..add(
        conversationNotifier.stream
            .startWith(conversationNotifier.state)
            .map((event) => event?.conversationId)
            .distinct()
            .switchMap((conversationId) {
              if (conversationId == null) {
                return const Stream<List<MessageItem>>.empty();
              }
              return messageDao.watchInsertOrReplaceMessageStream(
                conversationId,
              );
            })
            .listen(_insertOrReplaceCurrentConversation),
      )
      ..add(
        DataBaseEventBus.instance.deleteMessageIdStream.listen((messageIds) {
          messageIds.forEach(_deleteMessage);
        }),
      );
  }

  final ConversationStateNotifier conversationNotifier;
  final Database database;
  final MentionCache mentionCache;
  final AccountServer accountServer;
  final List<StreamSubscription?> _subscriptions = [];
  int limit;
  var _generation = 0;
  var _loadAfterInFlight = false;
  var _loadBeforeInFlight = false;
  var _disposed = false;
  late final MessageWindowLoader _messageWindowLoader =
      MessageWindowLoader.fromDao(messageDao);

  MessageState get state => value;

  MessageDao get messageDao => database.messageDao;

  Future<void> _preCacheMention(MessageState state) async {
    final set = {...state.top, state.center, ...state.bottom};
    await mentionCache.checkMentionCache(
      {
        ...set.map((e) => e?.content),
        ...set.map((e) => e?.quoteContent),
      }.nonNulls.toSet(),
    );
  }

  void _warmMentionCache(MessageState state) {
    unawaited(
      _preCacheMention(state).catchError((Object error, StackTrace stackTrace) {
        e('preCacheMention failed: $error');
      }),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _subscriptions
      ..forEach((subscription) => unawaited(subscription?.cancel()))
      ..clear();
    super.dispose();
  }

  bool _isCurrent(int generation, String conversationId) =>
      !_disposed &&
      generation == _generation &&
      conversationNotifier.state?.conversationId == conversationId;

  void _emit(MessageState nextState) {
    if (_disposed) return;
    value = nextState;
    _warmMentionCache(nextState);
  }

  void _init({
    String? centerMessageId,
    String? lastReadMessageId,
    bool forceLatest = false,
  }) {
    final generation = ++_generation;
    unawaited(
      _runInit(
        generation,
        centerMessageId: centerMessageId,
        lastReadMessageId: lastReadMessageId,
        forceLatest: forceLatest,
      ).catchError((Object error, StackTrace stackTrace) {
        e('message init failed: $error $stackTrace');
      }),
    );
  }

  Future<void> _runInit(
    int generation, {
    String? centerMessageId,
    String? lastReadMessageId,
    bool forceLatest = false,
  }) async {
    final finalLimit = limit;
    final conversationId = conversationNotifier.state?.conversationId;
    if (conversationId == null) return;

    if (centerMessageId != null || forceLatest) {
      traceChatJump(
        'message init center=${shortMessageId(centerMessageId)} '
        'forceLatest=$forceLatest limit=$finalLimit',
      );
    }

    final messageState = await _resetMessageList(
      conversationId,
      finalLimit,
      centerMessageId: centerMessageId,
      forceLatest: forceLatest,
    );
    if (!_isCurrent(generation, conversationId)) return;

    final nextState = _pretreatment(
      messageState.copyWith(
        refreshKey: Object(),
        lastReadMessageId: lastReadMessageId,
      ),
    );
    _emit(nextState);
  }

  void after() {
    if (_loadAfterInFlight || state.isLatest) return;
    final conversationId = conversationNotifier.state?.conversationId;
    if (conversationId == null || state.conversationId != conversationId) {
      return;
    }

    _loadAfterInFlight = true;
    final generation = _generation;
    unawaited(
      _loadAfter(generation, conversationId)
          .catchError((Object error, StackTrace stackTrace) {
            e('message load after failed: $error $stackTrace');
          })
          .whenComplete(() => _loadAfterInFlight = false),
    );
  }

  void before() {
    if (_loadBeforeInFlight || state.isOldest) return;
    final conversationId = conversationNotifier.state?.conversationId;
    if (conversationId == null || state.conversationId != conversationId) {
      return;
    }

    _loadBeforeInFlight = true;
    final generation = _generation;
    unawaited(
      _loadBefore(generation, conversationId)
          .catchError((Object error, StackTrace stackTrace) {
            e('message load before failed: $error $stackTrace');
          })
          .whenComplete(() => _loadBeforeInFlight = false),
    );
  }

  Future<void> _loadAfter(int generation, String conversationId) async {
    final messageState = await _after(conversationId);
    if (!_isCurrent(generation, conversationId)) return;
    _emit(_pretreatment(messageState));
  }

  Future<void> _loadBefore(int generation, String conversationId) async {
    final messageState = await _before(conversationId);
    if (!_isCurrent(generation, conversationId)) return;
    _emit(_pretreatment(messageState));
  }

  Future<MessageState> _before(String conversationId) async {
    final topMessageId = state.topMessage?.messageId;
    assert(topMessageId != null);
    final info = await messageDao.messageOrderInfo(topMessageId!);
    final list = await messageDao
        .beforeMessagesByConversationId(info!, conversationId, limit)
        .get();

    final isOldest = list.length < limit;
    return state.copyWith(
      top: [...list.reversed, ...state.top],
      isOldest: isOldest,
    );
  }

  Future<MessageState> _after(String conversationId) async {
    final bottomMessageId = state.bottomMessage?.messageId;
    assert(bottomMessageId != null);
    final info = await messageDao.messageOrderInfo(bottomMessageId!);
    final list = await messageDao
        .afterMessagesByConversationId(info!, conversationId, limit)
        .get();

    final isLatest = list.length < limit ? true : null;
    return state.copyWith(
      bottom: [...state.bottom, ...list],
      isLatest: isLatest,
    );
  }

  Future<MessageState> _resetMessageList(
    String conversationId,
    int limit, {
    String? centerMessageId,
    bool forceLatest = false,
  }) async {
    final conversation = conversationNotifier.state?.conversation;
    final _centerMessageId = forceLatest
        ? null
        : centerMessageId ??
              ((conversation?.unseenMessageCount ?? 0) > 0
                  ? conversation?.lastReadMessageId
                  : null);

    if (centerMessageId != null || forceLatest) {
      traceChatJump(
        'reset list requested=${shortMessageId(centerMessageId)} '
        'resolved=${shortMessageId(_centerMessageId)} '
        'forceLatest=$forceLatest unseen=${conversation?.unseenMessageCount}',
      );
    }

    final state = await _messagesByConversationId(
      conversationId,
      limit,
      centerMessageId: _centerMessageId,
    );

    return state.copyWith(
      conversationId: conversationId,
      center: state.center,
      bottom: state.bottom,
      top: state.top,
    );
  }

  Future<MessageState> _messagesByConversationId(
    String conversationId,
    int limit, {
    String? centerMessageId,
  }) => _messageWindowLoader.load(
    conversationId,
    limit,
    centerMessageId: centerMessageId,
    trace: traceChatJump,
  );

  MessageState? _insertOrReplace(
    String conversationId,
    List<MessageItem> list,
  ) {
    var top = state.top.toList();
    var center = state.center;
    var bottom = state.bottom.toList();

    var jumpToCurrent = false;
    for (final item in list) {
      if (item.conversationId != conversationId) continue;

      if (item.messageId == center?.messageId) {
        center = item;
        continue;
      }

      final topIndex = top.indexWhere(
        (element) => element.messageId == item.messageId,
      );
      if (topIndex > -1) {
        top[topIndex] = item;
        continue;
      }

      final bottomIndex = bottom.indexWhere(
        (element) => element.messageId == item.messageId,
      );
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
        jumpToCurrent = jumpToCurrent || currentUserSent;
      } else {
        if (currentUserSent && item.status == MessageStatus.sending) {
          _init();
          return null;
        }
      }
    }

    final result = state.copyWith(top: top, center: center, bottom: bottom);

    if (jumpToCurrent) {
      return result._copyWithJumpCurrentState();
    }
    return result;
  }

  void _insertOrReplaceCurrentConversation(List<MessageItem> list) {
    final conversationId = conversationNotifier.state?.conversationId;
    if (conversationId == null || state.conversationId != conversationId) {
      return;
    }

    final result = _insertOrReplace(conversationId, list);
    if (result != null) {
      _emit(_pretreatment(result));
    }
  }

  void _deleteMessage(String messageId) {
    final conversationId = conversationNotifier.state?.conversationId;
    if (conversationId == null || state.conversationId != conversationId) {
      return;
    }

    _emit(_pretreatment(state.removeMessage(messageId)));
  }

  void scrollTo(String messageId) {
    traceChatJump('message scrollTo target=${shortMessageId(messageId)}');
    _init(
      centerMessageId: messageId,
      lastReadMessageId: state.lastReadMessageId,
    );
  }

  void reload() {
    _init();
  }

  void jumpToLatestWindow() {
    _init(
      lastReadMessageId: state.lastReadMessageId,
      forceLatest: true,
    );
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
          isVerified: false,
          sharedUserIsVerified: false,
        ),
        ...messageState.top,
      ];
    }
    final _messageState = messageState.copyWith(top: top);
    if (isAppActive) {
      accountServer.markRead(conversationNotifier.state!.conversationId);
    }
    return _messageState;
  }
}
