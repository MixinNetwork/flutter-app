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

enum MessageWindowJumpSource {
  conversation,
  message,
  quote,
  pin,
  mention,
  search,
  restore,
}

sealed class MessageWindowAnchor extends Equatable {
  const MessageWindowAnchor();

  String? get centerMessageId => null;

  String get debugName;
}

final class LatestMessageWindowAnchor extends MessageWindowAnchor {
  const LatestMessageWindowAnchor();

  @override
  String get debugName => 'latest';

  @override
  List<Object?> get props => const [];
}

final class UnreadMessageWindowAnchor extends MessageWindowAnchor {
  const UnreadMessageWindowAnchor({required this.lastReadMessageId});

  final String lastReadMessageId;

  @override
  String get centerMessageId => lastReadMessageId;

  @override
  String get debugName => 'unread';

  @override
  List<Object?> get props => [lastReadMessageId];
}

final class AroundMessageWindowAnchor extends MessageWindowAnchor {
  const AroundMessageWindowAnchor({
    required this.messageId,
    required this.source,
  });

  final String messageId;
  final MessageWindowJumpSource source;

  @override
  String get centerMessageId => messageId;

  @override
  String get debugName => 'message:$source';

  @override
  List<Object?> get props => [messageId, source];
}

final class RestoreMessageWindowAnchor extends MessageWindowAnchor {
  const RestoreMessageWindowAnchor({
    required this.messageId,
    required this.offset,
  });

  final String messageId;
  final double offset;

  @override
  String get centerMessageId => messageId;

  @override
  String get debugName => 'restore';

  @override
  List<Object?> get props => [messageId, offset];
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
    this.anchor = const LatestMessageWindowAnchor(),
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
  final MessageWindowAnchor anchor;

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
    anchor,
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
    MessageWindowAnchor? anchor,
  }) => MessageState(
    conversationId: conversationId ?? this.conversationId,
    top: top ?? this.top,
    center: center ?? this.center,
    bottom: bottom ?? this.bottom,
    isLatest: isLatest ?? this.isLatest,
    isOldest: isOldest ?? this.isOldest,
    lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
    refreshKey: refreshKey ?? this.refreshKey,
    anchor: anchor ?? this.anchor,
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
        anchor: anchor,
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
              ),
            )
            .distinct()
            .listen(
              (event) => _init(
                centerMessageId: event.$2,
                lastReadMessageId: event.$3,
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

  Future<void> _preCacheMentionSafely(MessageState state) async {
    try {
      await _preCacheMention(state);
    } catch (error) {
      e('preCacheMention failed: $error');
    }
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

  void _emit(MessageState nextState, {bool warmMentionCache = true}) {
    if (_disposed) return;
    value = nextState;
    if (warmMentionCache) {
      _warmMentionCache(nextState);
    }
  }

  void _init({
    String? centerMessageId,
    String? lastReadMessageId,
    bool forceLatest = false,
    MessageWindowAnchor? anchor,
  }) {
    final generation = ++_generation;
    unawaited(
      _runInit(
        generation,
        centerMessageId: centerMessageId,
        lastReadMessageId: lastReadMessageId,
        forceLatest: forceLatest,
        anchor: anchor,
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
    MessageWindowAnchor? anchor,
  }) async {
    final finalLimit = limit;
    final conversationId = conversationNotifier.state?.conversationId;
    if (conversationId == null) return;
    final conversation = conversationNotifier.state?.conversation;
    final windowAnchor =
        anchor ??
        _resolveWindowAnchor(
          requestedCenterMessageId: centerMessageId,
          forceLatest: forceLatest,
        );
    final resolvedLastReadMessageId =
        lastReadMessageId ??
        conversation?.lastReadMessageId ??
        state.lastReadMessageId;

    traceChatJump(
      'message init '
      'conv=${shortMessageId(conversationId)} '
      'requestedCenter=${shortMessageId(centerMessageId)} '
      'anchor=${windowAnchor.debugName} '
      'anchorCenter=${shortMessageId(windowAnchor.centerMessageId)} '
      'inputLastRead=${shortMessageId(lastReadMessageId)} '
      'stateLastRead=${shortMessageId(state.lastReadMessageId)} '
      'convLastRead=${shortMessageId(conversation?.lastReadMessageId)} '
      'unseen=${conversation?.unseenMessageCount} '
      'forceLatest=$forceLatest limit=$finalLimit',
    );

    final messageState = await _resetMessageList(
      conversationId,
      finalLimit,
      anchor: windowAnchor,
    );
    if (!_isCurrent(generation, conversationId)) return;

    final nextState = _pretreatment(
      messageState.copyWith(
        refreshKey: Object(),
        lastReadMessageId: resolvedLastReadMessageId,
      ),
    );
    traceChatJump(
      'message init loaded '
      'conv=${shortMessageId(conversationId)} '
      'lastRead=${shortMessageId(nextState.lastReadMessageId)} '
      '${_formatWindow(nextState)}',
    );
    await _preCacheMentionSafely(nextState);
    if (!_isCurrent(generation, conversationId)) return;
    _emit(nextState, warmMentionCache: false);
  }

  MessageWindowAnchor _resolveWindowAnchor({
    required String? requestedCenterMessageId,
    required bool forceLatest,
  }) {
    if (forceLatest) return const LatestMessageWindowAnchor();
    if (requestedCenterMessageId != null) {
      return AroundMessageWindowAnchor(
        messageId: requestedCenterMessageId,
        source: MessageWindowJumpSource.conversation,
      );
    }
    final conversation = conversationNotifier.state?.conversation;
    final lastReadMessageId = conversation?.lastReadMessageId;
    if ((conversation?.unseenMessageCount ?? 0) > 0 &&
        lastReadMessageId != null) {
      return UnreadMessageWindowAnchor(lastReadMessageId: lastReadMessageId);
    }
    return const LatestMessageWindowAnchor();
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

  Future<MessageState> _before(String conversationId) =>
      _messageWindowLoader.loadBefore(state, conversationId, limit);

  Future<MessageState> _after(String conversationId) =>
      _messageWindowLoader.loadAfter(state, conversationId, limit);

  Future<MessageState> _resetMessageList(
    String conversationId,
    int limit, {
    required MessageWindowAnchor anchor,
  }) async {
    final conversation = conversationNotifier.state?.conversation;

    traceChatJump(
      'reset list '
      'conv=${shortMessageId(conversationId)} '
      'anchor=${anchor.debugName} '
      'resolved=${shortMessageId(anchor.centerMessageId)} '
      'convLastRead=${shortMessageId(conversation?.lastReadMessageId)} '
      'unseen=${conversation?.unseenMessageCount}',
    );

    final state = await _messagesByConversationId(
      conversationId,
      limit,
      anchor: anchor,
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
    required MessageWindowAnchor anchor,
  }) => _messageWindowLoader.load(
    conversationId,
    limit,
    anchor: anchor,
    trace: traceChatJump,
  );

  Future<MessageWindowDirection?> restoreDirectionFromSource({
    required String? sourceMessageId,
    required String targetMessageId,
  }) => _messageWindowLoader.directionFromSource(
    sourceMessageId: sourceMessageId,
    targetMessageId: targetMessageId,
  );

  MessageState? _insertOrReplace(
    String conversationId,
    List<MessageItem> list,
  ) {
    var top = state.top.toList();
    var center = state.center;
    var bottom = state.bottom.toList();

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
      } else {
        if (currentUserSent && item.status == MessageStatus.sending) {
          loadLatestWindow();
          return null;
        }
      }
    }

    return state.copyWith(
      top: top,
      center: center,
      bottom: bottom,
    );
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

  void loadAroundMessage(String messageId) {
    traceChatJump(
      'message loadAround target=${shortMessageId(messageId)}',
    );
    _init(
      centerMessageId: messageId,
      lastReadMessageId: state.lastReadMessageId,
      anchor: AroundMessageWindowAnchor(
        messageId: messageId,
        source: MessageWindowJumpSource.message,
      ),
    );
  }

  void reload() {
    _init();
  }

  void loadLatestWindow() {
    _init(
      lastReadMessageId: state.lastReadMessageId,
      anchor: const LatestMessageWindowAnchor(),
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

  String _formatWindow(MessageState state) =>
      'top=${state.top.length} '
      'topFirst=${shortMessageId(state.top.firstOrNull?.messageId)} '
      'topLast=${shortMessageId(state.top.lastOrNull?.messageId)} '
      'center=${shortMessageId(state.center?.messageId)} '
      'bottom=${state.bottom.length} '
      'bottomFirst=${shortMessageId(state.bottom.firstOrNull?.messageId)} '
      'bottomLast=${shortMessageId(state.bottom.lastOrNull?.messageId)} '
      'latest=${state.isLatest} oldest=${state.isOldest} '
      'anchor=${state.anchor.debugName}';
}
