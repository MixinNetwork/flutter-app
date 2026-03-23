import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:rxdart/rxdart.dart';

import '../../account/account_server.dart';
import '../../crypto/uuid/uuid.dart';
import '../../db/dao/conversation_dao.dart';
import '../../db/database.dart';
import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';
import '../../enum/encrypt_category.dart';
import '../../utils/app_lifecycle.dart';
import '../../utils/extension/extension.dart';
import '../../utils/local_notification_center.dart';
import '../../widgets/toast.dart';
import '../home/providers/home_scope_providers.dart';
import 'account_server_provider.dart';
import 'database_provider.dart';
import 'is_bot_group_provider.dart';
import 'recent_conversation_provider.dart';
import 'responsive_navigator_provider.dart';
import 'ui_context_providers.dart';

class ConversationState extends Equatable {
  const ConversationState({
    required this.conversationId,
    required this.refreshKey,
    this.userId,
    this.initIndexMessageId,
    this.lastReadMessageId,
    this.conversation,
    this.user,
    this.app,
    this.participant,
    this.initialSidePage,
    this.keyword,
  });

  final String conversationId;
  final String? userId;
  final String? initIndexMessageId;
  final String? lastReadMessageId;
  final ConversationItem? conversation;
  final User? user;
  final App? app;
  final Participant? participant;
  final Object refreshKey;

  final String? initialSidePage;
  final String? keyword;

  bool get isLoaded => conversation != null || user != null;

  bool get isBot => conversation?.isBotConversation ?? user?.isBot ?? false;

  bool get isVerified =>
      conversation?.ownerVerified ?? user?.isVerified ?? false;

  Membership? get membership => user?.membership ?? conversation?.membership;

  // note: check user information first.
  // because in bot stranger conversation. it might be conversation.isStrangerConversation == false
  bool? get isStranger =>
      user?.isStranger ?? conversation?.isStrangerConversation;

  bool? get isGroup =>
      conversation?.isGroupConversation ?? (user != null ? false : null);

  String? get name => conversation?.validName ?? user?.fullName;

  String? get identityNumber =>
      conversation?.ownerIdentityNumber ?? user?.identityNumber;

  UserRelationship? get relationship =>
      conversation?.relationship ?? user?.relationship;

  EncryptCategory get encryptCategory => _getEncryptCategory(app);

  ParticipantRole? get role =>
      conversation?.category == ConversationCategory.contact
      ? ParticipantRole.owner
      : participant?.role;

  @override
  List<Object?> get props => [
    conversationId,
    userId,
    initIndexMessageId,
    conversation,
    user,
    lastReadMessageId,
    refreshKey,
    initialSidePage,
    participant,
    keyword,
  ];

  ConversationState copyWith({
    String? conversationId,
    String? userId,
    String? initIndexMessageId,
    String? lastReadMessageId,
    ConversationItem? conversation,
    User? user,
    App? app,
    Participant? participant,
    Object? refreshKey,
    String? initialSidePage,
    String? keyword,
  }) => ConversationState(
    conversationId: conversationId ?? this.conversationId,
    userId: userId ?? this.userId,
    initIndexMessageId: initIndexMessageId ?? this.initIndexMessageId,
    conversation: conversation ?? this.conversation,
    user: user ?? this.user,
    app: app ?? this.app,
    lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
    refreshKey: refreshKey ?? this.refreshKey,
    initialSidePage: initialSidePage ?? this.initialSidePage,
    participant: participant ?? this.participant,
    keyword: keyword ?? this.keyword,
  );
}

EncryptCategory _getEncryptCategory(App? app) {
  if (app != null && app.capabilities?.contains('ENCRYPTED') == true) {
    return EncryptCategory.encrypted;
  } else if (app != null) {
    return EncryptCategory.plain;
  }
  return EncryptCategory.signal;
}

class ConversationStateNotifier extends Notifier<ConversationState?> {
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  late final StreamController<ConversationState?> _stateController =
      StreamController<ConversationState?>.broadcast();
  AccountServer? _accountServer;
  ResponsiveNavigatorStateNotifier? _responsiveNavigatorStateNotifier;

  Stream<ConversationState?> get stream => _stateController.stream;

  @override
  ConversationState? build() {
    final accountServerAsync = ref.watch(accountServerProvider);
    if (!accountServerAsync.hasValue) {
      throw Exception('accountServer is not ready');
    }

    _accountServer = accountServerAsync.requireValue;
    _responsiveNavigatorStateNotifier = ref.watch(
      responsiveNavigatorProvider.notifier,
    );

    _resetSubscriptions();
    _bind();

    ref.onDispose(() {
      appActiveListener.removeListener(onListen);
      for (final subscription in _subscriptions) {
        unawaited(subscription.cancel());
      }
      _subscriptions.clear();
      unawaited(_stateController.close());
    });

    return stateOrNull;
  }

  Database get _database => _accountServer!.database;
  String get _currentUserId => _accountServer!.userId;

  void _bind() {
    _subscriptions.add(
      stream
          .map((event) => event?.conversationId)
          .distinct()
          .listen(_accountServer!.selectConversation),
    );
    _subscriptions.add(
      stream
          .map((event) => (event?.conversationId, event?.userId))
          .where((event) => event.$1 != null)
          .distinct()
          .switchMap((event) {
            final (String? conversationId, String? userId) = event;
            return _database.conversationDao
                .conversationItem(conversationId!)
                .watchSingleOrNullWithStream(
                  eventStreams: [
                    DataBaseEventBus.instance.watchUpdateConversationStream([
                      conversationId,
                    ]),
                    if (userId != null)
                      DataBaseEventBus.instance.watchUpdateUserStream([userId]),
                  ],
                  duration: kSlowThrottleDuration,
                  prepend: false,
                );
          })
          .listen((event) {
            String? userId;
            if (event != null && !event.isGroupConversation) {
              userId = event.ownerId;
            }
            _updateState(state?.copyWith(conversation: event, userId: userId));
          }),
    );
    _subscriptions.add(
      stream
          .map((event) => event?.userId)
          .distinct()
          .switchMap((userId) {
            if (userId == null) return Stream.value(null);
            return _database.userDao
                .userById(userId)
                .watchSingleOrNullWithStream(
                  eventStreams: [
                    DataBaseEventBus.instance.watchUpdateUserStream([userId]),
                  ],
                  duration: kDefaultThrottleDuration,
                  prepend: false,
                );
          })
          .listen((event) => _updateState(state?.copyWith(user: event))),
    );
    _subscriptions.add(
      stream
          .map((event) => event?.conversationId)
          .where((event) => event != null)
          .distinct()
          .switchMap(
            (conversationId) => _database.participantDao
                .participantById(conversationId!, _currentUserId)
                .watchSingleOrNullWithStream(
                  eventStreams: [
                    DataBaseEventBus.instance.watchUpdateParticipantStream(
                      conversationIds: [conversationId],
                      userIds: [_currentUserId],
                      and: true,
                    ),
                  ],
                  duration: kSlowThrottleDuration,
                  prepend: false,
                ),
          )
          .listen((event) {
            _updateState(state?.copyWith(participant: event));
          }),
    );

    appActiveListener.addListener(onListen);
  }

  void _resetSubscriptions() {
    appActiveListener.removeListener(onListen);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }

  void _updateState(ConversationState? next) {
    state = next;
    if (!_stateController.isClosed) {
      _stateController.add(next);
    }
  }

  void replaceState(ConversationState? next) {
    _updateState(next);
  }

  void onListen() {
    if (isAppActive && state?.conversationId != null) {
      dismissByConversationId(state!.conversationId);
      return;
    }
  }

  void unselected() {
    _updateState(null);
    _responsiveNavigatorStateNotifier!.clear();
  }

  static Future<void> selectConversation(
    ProviderContainer container,
    BuildContext context,
    String conversationId, {
    ConversationItem? conversation,
    String? initIndexMessageId,
    String? initialChatSidePage,
    String? keyword,
    bool sync = false,
    bool checkCurrentUserExist = false,
  }) async {
    container.read(isBotGroupProvider(conversationId));

    final accountServer = container.read(accountServerProvider).requireValue;
    final database = container.read(databaseProvider).requireValue;
    final conversationNotifier = container.read(
      conversationProvider.notifier,
    );
    final state = conversationNotifier.state;

    ConversationItem? _conversation;
    String? lastReadMessageId;
    bool? hasUnreadMessage;
    if (state?.conversationId == conversationId) {
      _conversation = state?.conversation;

      hasUnreadMessage = (_conversation?.unseenMessageCount ?? 0) > 0;
      if (hasUnreadMessage) {
        lastReadMessageId = state?.lastReadMessageId;
      }
    }

    _conversation =
        conversation ??
        _conversation ??
        await _conversationItem(container, conversationId);

    if (_conversation == null && sync) {
      showToastLoading();
      await accountServer.refreshConversation(
        conversationId,
        checkCurrentUserExist: checkCurrentUserExist,
      );
      _conversation = await _conversationItem(container, conversationId);
    }

    hasUnreadMessage ??= (_conversation?.unseenMessageCount ?? 0) > 0;

    if (_conversation == null) {
      return showToastFailed(null);
    }

    final _initIndexMessageId =
        initIndexMessageId ??
        (hasUnreadMessage ? _conversation.lastReadMessageId : null);

    lastReadMessageId =
        lastReadMessageId ?? (hasUnreadMessage ? _initIndexMessageId : null);

    final ownerId = _conversation.ownerId;

    final appFuture = (!_conversation.isGroupConversation && ownerId != null)
        ? database.appDao.findAppById(ownerId)
        : null;

    final participantFuture = database.participantDao
        .participantById(conversationId, accountServer.userId)
        .getSingleOrNull();

    final conversationState = ConversationState(
      conversationId: conversationId,
      conversation: _conversation,
      initIndexMessageId: _initIndexMessageId,
      lastReadMessageId: lastReadMessageId,
      userId: _conversation.isGroupConversation ? null : _conversation.ownerId,
      app: await appFuture,
      initialSidePage: initialChatSidePage,
      refreshKey: Object(),
      participant: await participantFuture,
      keyword: keyword,
    );

    Toast.dismiss();

    conversationNotifier.replaceState(conversationState);

    conversationNotifier._responsiveNavigatorStateNotifier!.pushPage(
      ResponsiveNavigatorStateNotifier.chatPage,
    );

    unawaited(dismissByConversationId(conversationId));
    container.read(recentConversationIDsProvider.notifier).add(conversationId);
  }

  static Future<void> selectUser(
    ProviderContainer container,
    BuildContext context,
    String userId, {
    User? user,
    String? initialChatSidePage,
  }) async {
    final accountServer = container.read(accountServerProvider).requireValue;
    final database = container.read(databaseProvider).requireValue;
    final conversationNotifier = container.read(
      conversationProvider.notifier,
    );

    final conversationId = generateConversationId(userId, accountServer.userId);

    container.read(isBotGroupProvider(conversationId));

    final conversation = await _conversationItem(container, conversationId);
    if (conversation != null) {
      return selectConversation(
        container,
        context,
        conversationId,
        conversation: conversation,
        initialChatSidePage: initialChatSidePage,
      );
    }

    final _user =
        user ?? await database.userDao.userById(userId).getSingleOrNull();

    if (_user == null) {
      return showToastFailed(
        ToastError(container.read(localizationProvider).userNotFound),
      );
    }

    final app = await database.appDao.findAppById(userId);

    conversationNotifier.replaceState(
      ConversationState(
        conversationId: conversationId,
        userId: userId,
        user: _user,
        app: app,
        initialSidePage: initialChatSidePage,
        refreshKey: Object(),
      ),
    );

    conversationNotifier._responsiveNavigatorStateNotifier!.pushPage(
      ResponsiveNavigatorStateNotifier.chatPage,
    );

    unawaited(dismissByConversationId(conversationId));
  }

  static Future<ConversationItem?> _conversationItem(
    ProviderContainer container,
    String conversationId,
  ) async {
    final conversations = container
        .read(conversationListControllerProvider.notifier)
        .state
        .map
        .values
        .cast<ConversationItem?>()
        .toList();

    return conversations.firstWhere(
          (element) => element?.conversationId == conversationId,
          orElse: () => null,
        ) ??
        await container
            .read(databaseProvider)
            .requireValue
            .conversationDao
            .conversationItem(conversationId)
            .getSingleOrNull();
  }
}

class _LastConversationNotifier extends Notifier<ConversationState?> {
  _LastConversationNotifier([this._filter]);

  final bool Function(ConversationState?)? _filter;

  @override
  ConversationState? build() {
    final conversation = ref.read(conversationProvider);
    ref.listen(conversationProvider, (previous, next) {
      if (next == null) return;
      if (_filter != null && !_filter(next)) return;
      state = next;
    });
    return conversation;
  }
}

final conversationProvider =
    NotifierProvider.autoDispose<ConversationStateNotifier, ConversationState?>(
      ConversationStateNotifier.new,
    );

final _lastConversationProvider =
    NotifierProvider.autoDispose<_LastConversationNotifier, ConversationState?>(
      _LastConversationNotifier.new,
    );

final filterLastConversationProvider = NotifierProvider.autoDispose
    .family<
      _LastConversationNotifier,
      ConversationState?,
      bool Function(ConversationState?)
    >(_LastConversationNotifier.new);

final lastConversationProvider = _lastConversationProvider.select(
  (value) => value,
);

final lastConversationIdProvider = lastConversationProvider.select(
  (value) => value?.conversationId,
);

final currentConversationIdProvider = conversationProvider.select(
  (value) => value?.conversationId,
);

final currentConversationNameProvider = conversationProvider.select(
  (value) => value?.conversation?.name,
);

final currentConversationHasParticipantProvider = conversationProvider.select((
  value,
) {
  if (value?.conversation == null) return true;
  if (value?.conversation?.category == ConversationCategory.contact) {
    return true;
  }
  if (value?.conversation?.status == ConversationStatus.quit) {
    return false;
  }
  return value?.participant != null;
});
