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
import '../../utils/rivepod.dart';
import '../../widgets/toast.dart';
import '../home/bloc/conversation_list_bloc.dart';
import '../home/bloc/subscriber_mixin.dart';
import 'account_server_provider.dart';
import 'is_bot_group_provider.dart';
import 'recent_conversation_provider.dart';
import 'responsive_navigator_provider.dart';

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

  bool? get isBot => conversation?.isBotConversation ?? user?.isBot;

  bool get isVerified =>
      conversation?.ownerVerified ?? user?.isVerified ?? false;

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
  }) =>
      ConversationState(
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

class ConversationStateNotifier
    extends DistinctStateNotifier<ConversationState?> with SubscriberMixin {
  ConversationStateNotifier({
    required AccountServer accountServer,
    required ResponsiveNavigatorStateNotifier responsiveNavigatorStateNotifier,
  })  : _responsiveNavigatorStateNotifier = responsiveNavigatorStateNotifier,
        _accountServer = accountServer,
        super(null) {
    addSubscription(stream
        .map((event) => event?.conversationId)
        .distinct()
        .listen(_accountServer.selectConversation));
    addSubscription(
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
            DataBaseEventBus.instance
                .watchUpdateConversationStream([conversationId]),
            if (userId != null)
              DataBaseEventBus.instance.watchUpdateUserStream([userId])
          ],
          duration: kSlowThrottleDuration,
          prepend: false,
        );
      }).listen((event) {
        String? userId;
        if (event != null && !event.isGroupConversation) {
          userId = event.ownerId;
        }
        state = state?.copyWith(conversation: event, userId: userId);
      }),
    );
    addSubscription(
      stream.map((event) => event?.userId).distinct().switchMap((userId) {
        if (userId == null) return Stream.value(null);
        return _database.userDao.userById(userId).watchSingleOrNullWithStream(
          eventStreams: [
            DataBaseEventBus.instance.watchUpdateUserStream([userId])
          ],
          duration: kDefaultThrottleDuration,
          prepend: false,
        );
      }).listen((event) => state = state?.copyWith(user: event)),
    );
    addSubscription(
      stream
          .map((event) => event?.conversationId)
          .where((event) => event != null)
          .distinct()
          .switchMap((conversationId) => _database.participantDao
                  .participantById(conversationId!, _currentUserId)
                  .watchSingleOrNullWithStream(
                eventStreams: [
                  DataBaseEventBus.instance.watchUpdateParticipantStream(
                    conversationIds: [conversationId],
                    userIds: [_currentUserId],
                    and: true,
                  )
                ],
                duration: kSlowThrottleDuration,
                prepend: false,
              ))
          .listen((Participant? event) {
        state = state?.copyWith(participant: event);
      }),
    );

    appActiveListener.addListener(onListen);
  }

  final AccountServer _accountServer;
  final ResponsiveNavigatorStateNotifier _responsiveNavigatorStateNotifier;
  late final Database _database = _accountServer.database;
  late final String _currentUserId = _accountServer.userId;

  @override
  void dispose() {
    appActiveListener.removeListener(onListen);
    super.dispose();
  }

  void onListen() {
    if (isAppActive && state?.conversationId != null) {
      dismissByConversationId(state!.conversationId);
      return;
    }
  }

  void unselected() {
    state = null;
    _responsiveNavigatorStateNotifier.clear();
  }

  static Future<void> selectConversation(
    BuildContext context,
    String conversationId, {
    ConversationItem? conversation,
    String? initIndexMessageId,
    String? initialChatSidePage,
    String? keyword,
    bool sync = false,
    bool checkCurrentUserExist = false,
  }) async {
    context.providerContainer.read(isBotGroupProvider(conversationId));

    final accountServer = context.accountServer;
    final database = context.database;
    final conversationNotifier =
        context.providerContainer.read(conversationProvider.notifier);
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

    _conversation = conversation ??
        _conversation ??
        await _conversationItem(context, conversationId);

    if (_conversation == null && sync) {
      showToastLoading();
      await context.accountServer.refreshConversation(
        conversationId,
        checkCurrentUserExist: checkCurrentUserExist,
      );
      _conversation = await _conversationItem(context, conversationId);
    }

    hasUnreadMessage ??= (_conversation?.unseenMessageCount ?? 0) > 0;

    if (_conversation == null) {
      return showToastFailed(null);
    }

    final _initIndexMessageId = initIndexMessageId ??
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

    conversationNotifier.state = conversationState;

    conversationNotifier._responsiveNavigatorStateNotifier
        .pushPage(ResponsiveNavigatorStateNotifier.chatPage);

    unawaited(dismissByConversationId(conversationId));
    context.providerContainer
        .read(recentConversationIDsProvider)
        .add(conversationId);
  }

  static Future<void> selectUser(
    BuildContext context,
    String userId, {
    User? user,
    String? initialChatSidePage,
  }) async {
    final accountServer = context.accountServer;
    final database = context.database;
    final conversationNotifier =
        context.providerContainer.read(conversationProvider.notifier);

    final conversationId = generateConversationId(userId, accountServer.userId);

    context.providerContainer.read(isBotGroupProvider(conversationId));

    final conversation = await _conversationItem(context, conversationId);
    if (conversation != null) {
      return selectConversation(
        context,
        conversationId,
        conversation: conversation,
        initialChatSidePage: initialChatSidePage,
      );
    }

    final _user =
        user ?? await database.userDao.userById(userId).getSingleOrNull();

    if (_user == null) {
      return showToastFailed(ToastError(context.l10n.userNotFound));
    }

    final app = await database.appDao.findAppById(userId);

    conversationNotifier.state = ConversationState(
      conversationId: conversationId,
      userId: userId,
      user: _user,
      app: app,
      initialSidePage: initialChatSidePage,
      refreshKey: Object(),
    );

    conversationNotifier._responsiveNavigatorStateNotifier
        .pushPage(ResponsiveNavigatorStateNotifier.chatPage);

    unawaited(dismissByConversationId(conversationId));
  }

  static Future<ConversationItem?> _conversationItem(
      BuildContext context, String conversationId) async {
    final conversations = context
        .read<ConversationListBloc>()
        .state
        .map
        .values
        .cast<ConversationItem?>()
        .toList();

    return conversations.firstWhere(
            (element) => element?.conversationId == conversationId,
            orElse: () => null) ??
        await context.database.conversationDao
            .conversationItem(conversationId)
            .getSingleOrNull();
  }
}

class _LastConversationNotifier
    extends DistinctStateNotifier<ConversationState?> {
  _LastConversationNotifier(super.state);

  set _state(ConversationState? value) => super.state = value;
}

final conversationProvider = StateNotifierProvider.autoDispose<
    ConversationStateNotifier, ConversationState?>((ref) {
  final keepAlive = ref.keepAlive();

  final accountServerAsync = ref.watch(accountServerProvider);

  if (!accountServerAsync.hasValue) {
    throw Exception('accountServer is not ready');
  }

  final responsiveNavigatorNotifier =
      ref.watch(responsiveNavigatorProvider.notifier);

  ref
    ..listen(accountServerProvider, (previous, next) => keepAlive.close())
    ..listen(responsiveNavigatorProvider.notifier,
        (previous, next) => keepAlive.close());

  return ConversationStateNotifier(
    accountServer: accountServerAsync.requireValue,
    responsiveNavigatorStateNotifier: responsiveNavigatorNotifier,
  );
});

final _lastConversationProvider = StateNotifierProvider.autoDispose<
    _LastConversationNotifier, ConversationState?>((ref) {
  final conversation = ref.read(conversationProvider);
  final lastConversationNotifier = _LastConversationNotifier(conversation);
  ref.listen(conversationProvider, (previous, next) {
    if (next == null) return;
    lastConversationNotifier._state = next;
  });
  return lastConversationNotifier;
});

final filterLastConversationProvider = StateNotifierProvider.autoDispose.family<
    _LastConversationNotifier,
    ConversationState?,
    bool Function(ConversationState?)>((ref, filter) {
  final conversation = ref.read(conversationProvider);
  final lastConversationNotifier = _LastConversationNotifier(conversation);
  ref.listen(conversationProvider, (previous, next) {
    if (!filter(next)) return;
    lastConversationNotifier._state = next;
  });
  return lastConversationNotifier;
});

final lastConversationProvider =
    _lastConversationProvider.select((value) => value);

final lastConversationIdProvider =
    lastConversationProvider.select((value) => value?.conversationId);

final currentConversationIdProvider =
    conversationProvider.select((value) => value?.conversationId);

final currentConversationNameProvider =
    conversationProvider.select((value) => value?.conversation?.name);

final currentConversationHasParticipantProvider =
    conversationProvider.select((value) {
  if (value?.conversation == null) return true;
  if (value?.conversation?.category == ConversationCategory.contact) {
    return true;
  }
  if (value?.conversation?.status == ConversationStatus.quit) {
    return false;
  }
  return value?.participant != null;
});
