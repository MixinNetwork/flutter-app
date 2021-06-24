import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../../../account/account_server.dart';
import '../../../bloc/simple_cubit.dart';
import '../../../bloc/subscribe_mixin.dart';
import '../../../crypto/uuid/uuid.dart';
import '../../../db/extension/conversation.dart';
import '../../../db/extension/user.dart';
import '../../../db/mixin_database.dart';
import '../../../generated/l10n.dart';
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
    required this.refreshKey,
  });

  final String conversationId;
  final String? userId;
  final String? initIndexMessageId;
  final String? lastReadMessageId;
  final ConversationItem? conversation;
  final User? user;
  final Object refreshKey;

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

  bool get isPlainConversation => isPlain(isGroup!, isBot!);

  @override
  List<Object?> get props => [
        conversationId,
        userId,
        initIndexMessageId,
        conversation,
        user,
        lastReadMessageId,
        refreshKey,
      ];

  ConversationState copyWith({
    final String? conversationId,
    final String? userId,
    final String? initIndexMessageId,
    final int? unseenMessageCount,
    final String? lastReadMessageId,
    final ConversationItem? conversation,
    final User? user,
    final Object? refreshKey,
  }) =>
      ConversationState(
        conversationId: conversationId ?? this.conversationId,
        userId: userId ?? this.userId,
        initIndexMessageId: initIndexMessageId ?? this.initIndexMessageId,
        conversation: conversation ?? this.conversation,
        user: user ?? this.user,
        lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
        refreshKey: refreshKey ?? this.refreshKey,
      );
}

bool isPlain(bool isGroup, bool isBot) {
  bool isPlain;
  if (isGroup) {
    isPlain = false;
  } else {
    isPlain = isBot;
  }
  return isPlain;
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
              .watchSingleOrNull())
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
            .watchSingleOrNull();
      }).listen((event) => emit(
            state?.copyWith(user: event),
          )),
    );
  }

  final AccountServer accountServer;
  final ResponsiveNavigatorCubit responsiveNavigatorCubit;

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
  }) async {
    final accountServer = context.read<AccountServer>();
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

    final conversationState = ConversationState(
      conversationId: conversationId,
      conversation: _conversation,
      initIndexMessageId: _initIndexMessageId,
      lastReadMessageId: lastReadMessageId,
      userId: _conversation.isGroupConversation ? null : _conversation.ownerId,
      refreshKey: Object(),
    );

    conversationCubit.emit(conversationState);

    accountServer.selectConversation(conversationId);
    conversationCubit.responsiveNavigatorCubit
        .pushPage(ResponsiveNavigatorCubit.chatPage);
  }

  static Future<void> selectUser(
    BuildContext context,
    String userId, {
    User? user,
  }) async {
    final accountServer = context.read<AccountServer>();
    final conversationCubit = context.read<ConversationCubit>();

    final conversationId = generateConversationId(userId, accountServer.userId);

    if (user == null) {
      final conversation = await _conversationItem(context, conversationId);

      if (conversation != null) {
        return selectConversation(
          context,
          conversationId,
          conversation: conversation,
        );
      }
    }

    final _user = user ??
        await accountServer.database.userDao.userById(userId).getSingleOrNull();

    if (_user == null) {
      return showToastFailed(
          context, ToastError(Localization.of(context).userNotFound));
    }

    conversationCubit.emit(ConversationState(
      conversationId: conversationId,
      userId: userId,
      user: _user,
      refreshKey: Object(),
    ));

    accountServer.selectConversation(conversationId);
    conversationCubit.responsiveNavigatorCubit
        .pushPage(ResponsiveNavigatorCubit.chatPage);
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
        await context
            .read<AccountServer>()
            .database
            .conversationDao
            .conversationItem(conversationId)
            .getSingleOrNull();
  }
}
