import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:rxdart/rxdart.dart';
import 'package:very_good_analysis/very_good_analysis.dart';

import '../../../account/account_server.dart';
import '../../../bloc/simple_cubit.dart';
import '../../../bloc/subscribe_mixin.dart';
import '../../../crypto/uuid/uuid.dart';
import '../../../db/mixin_database.dart';
import '../../../enum/encrypt_category.dart';
import '../../../utils/app_lifecycle.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/local_notification_center.dart';
import '../../../widgets/toast.dart';
import '../route/responsive_navigator_cubit.dart';
import 'conversation_list_bloc.dart';

class ConversationState extends Equatable {
  const ConversationState({
    required this.conversationId,
    this.userId,
    this.initIndexMessageId,
    this.lastReadMessageId,
    this.conversation,
    this.user,
    this.app,
    required this.refreshKey,
    this.initialSidePage,
  });

  final String conversationId;
  final String? userId;
  final String? initIndexMessageId;
  final String? lastReadMessageId;
  final ConversationItem? conversation;
  final User? user;
  final App? app;
  final Object refreshKey;

  final String? initialSidePage;

  bool get isLoaded => conversation != null || user != null;

  bool? get isBot => conversation?.isBotConversation ?? user?.isBot;

  bool get isVerified =>
      conversation?.ownerVerified ?? user?.isVerified ?? false;

  // note: check user information first.
  // because in bot stranger conversation. it might be conversation.isStrangerConversation == false
  bool? get isStranger =>
      user?.isStranger ?? conversation?.isStrangerConversation;

  bool? get isGroup =>
      (conversation?.isGroupConversation) ?? (user != null ? false : null);

  String? get name => conversation?.validName ?? user?.fullName;

  String? get identityNumber =>
      conversation?.ownerIdentityNumber ?? user?.identityNumber;

  UserRelationship? get relationship =>
      conversation?.relationship ?? user?.relationship;

  EncryptCategory get encryptCategory => getEncryptCategory(app);

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
      ];

  ConversationState copyWith({
    final String? conversationId,
    final String? userId,
    final String? initIndexMessageId,
    final int? unseenMessageCount,
    final String? lastReadMessageId,
    final ConversationItem? conversation,
    final User? user,
    final App? app,
    final Object? refreshKey,
    final String? initialSidePage,
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
          .map((event) => event?.conversationId)
          .where((event) => event != null)
          .distinct()
          .switchMap((event) => accountServer.database.conversationDao
              .conversationItem(event!)
              .watchSingleOrNullThrottle())
          .listen((event) {
        String? userId;
        if (event != null && !event.isGroupConversation) {
          userId = event.ownerId;
        }
        emit(
          state?.copyWith(
            conversation: event,
            userId: userId,
          ),
        );
      }),
    );
    addSubscription(
      stream.map((event) => event?.userId).distinct().switchMap((userId) {
        if (userId == null) return Stream.value(null);
        return accountServer.database.userDao
            .userById(userId)
            .watchSingleOrNullThrottle();
      }).listen((event) => emit(
            state?.copyWith(user: event),
          )),
    );

    appActiveListener.addListener(onListen);
  }

  final AccountServer accountServer;
  final ResponsiveNavigatorCubit responsiveNavigatorCubit;

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
  }) async {
    final accountServer = context.accountServer;
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

    hasUnreadMessage ??= (_conversation?.unseenMessageCount ?? 0) > 0;

    if (_conversation == null) {
      return showToastFailed(context, null);
    }

    final _initIndexMessageId = initIndexMessageId ??
        (hasUnreadMessage ? _conversation.lastReadMessageId : null);

    lastReadMessageId =
        lastReadMessageId ?? (hasUnreadMessage ? _initIndexMessageId : null);

    final ownerId = _conversation.ownerId;
    final app = (!_conversation.isGroupConversation && ownerId != null)
        ? await accountServer.database.appDao.findAppById(ownerId)
        : null;

    final conversationState = ConversationState(
      conversationId: conversationId,
      conversation: _conversation,
      initIndexMessageId: _initIndexMessageId,
      lastReadMessageId: lastReadMessageId,
      userId: _conversation.isGroupConversation ? null : _conversation.ownerId,
      app: app,
      initialSidePage: initialChatSidePage,
      refreshKey: Object(),
    );

    conversationCubit.emit(conversationState);

    accountServer.selectConversation(conversationId);
    conversationCubit.responsiveNavigatorCubit
        .pushPage(ResponsiveNavigatorCubit.chatPage);

    unawaited(dismissByConversationId(conversationId));
  }

  static Future<void> selectUser(
    BuildContext context,
    String userId, {
    User? user,
    String? initialChatSidePage,
  }) async {
    final accountServer = context.accountServer;
    final conversationCubit = context.read<ConversationCubit>();

    final conversationId = generateConversationId(userId, accountServer.userId);

    if (user == null) {
      final conversation = await _conversationItem(context, conversationId);

      if (conversation != null) {
        return selectConversation(
          context,
          conversationId,
          conversation: conversation,
          initialChatSidePage: initialChatSidePage,
        );
      }
    }

    final _user = user ??
        await accountServer.database.userDao.userById(userId).getSingleOrNull();

    if (_user == null) {
      return showToastFailed(context, ToastError(context.l10n.userNotFound));
    }

    final app = await accountServer.database.appDao.findAppById(userId);

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
