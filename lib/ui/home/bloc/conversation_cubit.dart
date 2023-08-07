import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:rxdart/rxdart.dart';

import '../../../account/account_server.dart';
import '../../../bloc/simple_cubit.dart';
import '../../../bloc/subscribe_mixin.dart';
import '../../../crypto/uuid/uuid.dart';
import '../../../db/dao/conversation_dao.dart';
import '../../../db/database_event_bus.dart';
import '../../../db/mixin_database.dart';
import '../../../enum/encrypt_category.dart';
import '../../../utils/app_lifecycle.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/local_notification_center.dart';
import '../../../widgets/toast.dart';
import '../route/responsive_navigator_cubit.dart';
import 'conversation_list_bloc.dart';
import 'recent_conversation_cubit.dart';

class ConversationState extends Equatable {
  const ConversationState({
    required this.conversationId,
    this.userId,
    this.initIndexMessageId,
    this.lastReadMessageId,
    this.conversation,
    this.user,
    this.app,
    this.participant,
    required this.refreshKey,
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

  EncryptCategory get encryptCategory => getEncryptCategory(app);

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

EncryptCategory getEncryptCategory(App? app) {
  if (app != null && app.capabilities?.contains('ENCRYPTED') == true) {
    return EncryptCategory.encrypted;
  } else if (app != null) {
    return EncryptCategory.plain;
  }
  return EncryptCategory.signal;
}

class ConversationCubit extends SimpleCubit<ConversationState?>
    with SubscribeMixin {
  ConversationCubit({
    required this.accountServer,
    required this.responsiveNavigatorCubit,
  }) : super(null) {
    addSubscription(
      stream
          .map((event) => (event?.conversationId, event?.userId))
          .where((event) => event.$1 != null)
          .distinct()
          .switchMap((event) {
        final (String? conversationId, String? userId) = event;
        return database.conversationDao
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
        emit(state?.copyWith(conversation: event, userId: userId));
      }),
    );
    addSubscription(
      stream.map((event) => event?.userId).distinct().switchMap((userId) {
        if (userId == null) return Stream.value(null);
        return database.userDao.userById(userId).watchSingleOrNullWithStream(
          eventStreams: [
            DataBaseEventBus.instance.watchUpdateUserStream([userId])
          ],
          duration: kDefaultThrottleDuration,
          prepend: false,
        );
      }).listen((event) => emit(state?.copyWith(user: event))),
    );
    addSubscription(
      stream
          .map((event) => event?.conversationId)
          .where((event) => event != null)
          .distinct()
          .switchMap((conversationId) => database.participantDao
                  .participantById(conversationId!, accountServer.userId)
                  .watchSingleOrNullWithStream(
                eventStreams: [
                  DataBaseEventBus.instance.watchUpdateParticipantStream(
                    conversationIds: [conversationId],
                    userIds: [accountServer.userId],
                    and: true,
                  )
                ],
                duration: kSlowThrottleDuration,
                prepend: false,
              ))
          .listen((Participant? event) {
        emit(state?.copyWith(participant: event));
      }),
    );

    appActiveListener.addListener(onListen);
  }

  final AccountServer accountServer;
  final ResponsiveNavigatorCubit responsiveNavigatorCubit;
  late final database = accountServer.database;

  @override
  Future<void> close() async {
    await super.close();
    appActiveListener.removeListener(onListen);
  }

  void onListen() {
    if (isAppActive && state?.conversationId != null) {
      dismissByConversationId(state!.conversationId);
      return;
    }
  }

  void unselected() {
    emit(null);
    accountServer.selectConversation(null);
    responsiveNavigatorCubit.clear();
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
    final accountServer = context.accountServer;
    final database = context.database;
    final conversationCubit = context.read<ConversationCubit>();
    final state = conversationCubit.state;

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
    conversationCubit.emit(conversationState);

    accountServer.selectConversation(conversationId);
    conversationCubit.responsiveNavigatorCubit
        .pushPage(ResponsiveNavigatorCubit.chatPage);

    unawaited(dismissByConversationId(conversationId));
    context.read<RecentConversationCubit>().add(conversationId);
  }

  static Future<void> selectUser(
    BuildContext context,
    String userId, {
    User? user,
    String? initialChatSidePage,
  }) async {
    final accountServer = context.accountServer;
    final database = context.database;
    final conversationCubit = context.read<ConversationCubit>();

    final conversationId = generateConversationId(userId, accountServer.userId);
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

    conversationCubit.emit(ConversationState(
      conversationId: conversationId,
      userId: userId,
      user: _user,
      app: app,
      initialSidePage: initialChatSidePage,
      refreshKey: Object(),
    ));

    accountServer.selectConversation(conversationId);
    conversationCubit.responsiveNavigatorCubit
        .pushPage(ResponsiveNavigatorCubit.chatPage);

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
