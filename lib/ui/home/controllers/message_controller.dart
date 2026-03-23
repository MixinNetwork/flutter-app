import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
import '../../provider/account_server_provider.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/database_provider.dart';
import '../../provider/mention_cache_provider.dart';
import '../providers/home_scope_providers.dart';

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

  List<MessageItem> get list => [...top, ?center, ...bottom];

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

  MessageState copyWithJumpCurrentState() => MessageState(
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

class MessageController extends Notifier<MessageState> {
  final ScrollController scrollController = ScrollController();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  ConversationStateNotifier? _conversationNotifier;
  Database? _database;
  MentionCache? _mentionCache;
  AccountServer? _accountServer;
  int _limit = 0;
  bool _initialized = false;

  int _initToken = 0;
  bool _loadingBefore = false;
  bool _loadingAfter = false;
  int? _lastBuiltLimit;

  ConversationStateNotifier get conversationNotifier => _conversationNotifier!;
  Database get database => _database!;
  MentionCache get mentionCache => _mentionCache!;
  AccountServer get accountServer => _accountServer!;
  int get limit => _limit;
  set limit(int value) => _limit = value;

  @override
  MessageState build() {
    final accountServer = ref.watch(accountServerProvider).value;
    final database = ref.watch(databaseProvider).value;
    if (accountServer == null || database == null) {
      throw StateError('MessageControllerDeps');
    }

    _accountServer = accountServer;
    _database = database;
    _mentionCache = ref.watch(mentionCacheProvider);
    _conversationNotifier = ref.read(conversationProvider.notifier);
    final nextLimit =
        ref.watch(messagePageLimitProvider) ?? (_limit > 0 ? _limit : 30);
    final limitChanged =
        _lastBuiltLimit != null && _lastBuiltLimit != nextLimit;
    _limit = nextLimit;
    _lastBuiltLimit = nextLimit;

    _resetSubscriptions();
    _bindConversation();
    _bindUpdates();
    if (!_initialized) {
      _initialized = true;
      unawaited(
        initialize(
          centerMessageId: conversationNotifier.state?.initIndexMessageId,
          lastReadMessageId: conversationNotifier.state?.lastReadMessageId,
        ),
      );
    } else if (limitChanged) {
      reload();
    }

    ref.onDispose(() {
      scrollController.dispose();
      _resetSubscriptions();
    });

    return stateOrNull ?? MessageState();
  }

  MessageDao get messageDao => database.messageDao;

  void _bindConversation() {
    _subscriptions.add(
      conversationNotifier.stream
          .where((event) => event?.conversationId != null)
          .map(
            (event) => (
              event?.conversationId,
              event?.initIndexMessageId,
              event?.lastReadMessageId,
              event?.refreshKey,
            ),
          )
          .distinct()
          .listen((event) {
            unawaited(
              initialize(
                centerMessageId: event.$2,
                lastReadMessageId: event.$3,
              ),
            );
          }),
    );
  }

  void _bindUpdates() {
    _subscriptions.add(
      conversationNotifier.stream
          .startWith(conversationNotifier.state)
          .map((event) => event?.conversationId)
          .distinct()
          .switchMap((conversationId) {
            if (conversationId == null) {
              return const Stream<List<MessageItem>>.empty();
            }
            return messageDao.watchInsertOrReplaceMessageStream(conversationId);
          })
          .listen((items) {
            unawaited(insertOrReplace(items));
          }),
    );

    _subscriptions.add(
      DataBaseEventBus.instance.deleteMessageIdStream.listen((messageIds) {
        for (final messageId in messageIds) {
          deleteMessage(messageId);
        }
      }),
    );
  }

  void _resetSubscriptions() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }

  Future<void> initialize({
    String? centerMessageId,
    String? lastReadMessageId,
  }) async {
    final conversationId = conversationNotifier.state?.conversationId;
    if (conversationId == null) return;

    final token = ++_initToken;
    final messageState = await _resetMessageList(
      conversationId,
      limit,
      centerMessageId,
    );
    if (token != _initToken) return;

    await _preCacheMention(messageState);
    if (token != _initToken) return;

    state = _pretreatment(
      messageState.copyWith(
        refreshKey: Object(),
        lastReadMessageId: lastReadMessageId,
      ),
    );
  }

  Future<void> after() async {
    if (_loadingAfter || state.isLatest) return;

    final conversationId = conversationNotifier.state?.conversationId;
    if (conversationId == null || state.conversationId != conversationId) {
      return;
    }

    _loadingAfter = true;
    try {
      final messageState = await _after(conversationId);
      await _preCacheMention(messageState);
      if (state.conversationId == conversationId) {
        state = _pretreatment(messageState);
      }
    } finally {
      _loadingAfter = false;
    }
  }

  Future<void> before() async {
    if (_loadingBefore || state.isOldest) return;

    final conversationId = conversationNotifier.state?.conversationId;
    if (conversationId == null || state.conversationId != conversationId) {
      return;
    }

    _loadingBefore = true;
    try {
      final messageState = await _before(conversationId);
      await _preCacheMention(messageState);
      if (state.conversationId == conversationId) {
        state = _pretreatment(messageState);
      }
    } finally {
      _loadingBefore = false;
    }
  }

  Future<void> insertOrReplace(List<MessageItem> items) async {
    final conversationId = conversationNotifier.state?.conversationId;
    if (conversationId == null || state.conversationId != conversationId) {
      return;
    }

    final result = _insertOrReplace(conversationId, items);
    if (result == null) return;

    await _preCacheMention(result);
    if (state.conversationId == conversationId) {
      state = _pretreatment(result);
    }
  }

  void deleteMessage(String messageId) {
    final conversationId = conversationNotifier.state?.conversationId;
    if (conversationId == null || state.conversationId != conversationId) {
      return;
    }
    state = _pretreatment(state.removeMessage(messageId));
  }

  void scrollTo(String messageId) {
    unawaited(
      initialize(
        centerMessageId: messageId,
        lastReadMessageId: state.lastReadMessageId,
      ),
    );
  }

  void reload() {
    unawaited(
      initialize(
        centerMessageId: conversationNotifier.state?.initIndexMessageId,
        lastReadMessageId: conversationNotifier.state?.lastReadMessageId,
      ),
    );
  }

  void jumpToCurrent() {
    if (scrollController.hasClients && state.isLatest) {
      state = _pretreatment(state.copyWithJumpCurrentState());
      return;
    }
    reload();
  }

  Future<void> _preCacheMention(MessageState state) async {
    final set = {...state.top, state.center, ...state.bottom};
    await mentionCache.checkMentionCache(
      {
        ...set.map((e) => e?.content),
        ...set.map((e) => e?.quoteContent),
      }.nonNulls.toSet(),
    );
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
    int limit, [
    String? centerMessageId,
  ]) async {
    final conversation = conversationNotifier.state?.conversation;
    final resolvedCenterMessageId =
        centerMessageId ??
        ((conversation?.unseenMessageCount ?? 0) > 0
            ? conversation?.lastReadMessageId
            : null);

    final nextState = await _messagesByConversationId(
      conversationId,
      limit,
      centerMessageId: resolvedCenterMessageId,
    );

    return nextState.copyWith(
      conversationId: conversationId,
      center: nextState.center,
      bottom: nextState.bottom,
      top: nextState.top,
    );
  }

  Future<MessageState> _messagesByConversationId(
    String conversationId,
    int limit, {
    String? centerMessageId,
  }) async {
    Future<MessageState> recentMessages() async {
      final list = await messageDao
          .messagesByConversationId(conversationId, limit)
          .get();

      return MessageState(
        top: list.reversed.toList(),
        isLatest: true,
        isOldest: list.length < limit,
      );
    }

    if (centerMessageId == null) return recentMessages();

    final info = await messageDao.messageOrderInfo(centerMessageId);
    if (info == null) {
      return recentMessages();
    }

    final halfLimit = limit ~/ 2;
    final bottomList = await messageDao
        .afterMessagesByConversationId(info, conversationId, halfLimit)
        .get();
    var topList =
        (await messageDao
                .beforeMessagesByConversationId(info, conversationId, halfLimit)
                .get())
            .reversed
            .toList();

    final isLatest = bottomList.length < halfLimit;
    final isOldest = topList.length < halfLimit;

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
  }

  MessageState? _insertOrReplace(
    String conversationId,
    List<MessageItem> list,
  ) {
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
        if (scrollController.hasClients) {
          final position = scrollController.position;
          jumpToBottom =
              currentUserSent ||
              (position.hasContentDimensions &&
                  position.pixels == position.maxScrollExtent);
        }
      } else {
        if (currentUserSent && item.status == MessageStatus.sending) {
          reload();
          return null;
        }
      }
    }

    final result = state.copyWith(top: top, center: center, bottom: bottom);

    if (scrollController.hasClients && jumpToBottom) {
      return result.copyWithJumpCurrentState();
    }
    return result;
  }

  MessageState _pretreatment(MessageState messageState) {
    List<MessageItem>? top;
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
    final nextState = messageState.copyWith(top: top);
    if (isAppActive) {
      accountServer.markRead(conversationNotifier.state!.conversationId);
    }
    return nextState;
  }
}
