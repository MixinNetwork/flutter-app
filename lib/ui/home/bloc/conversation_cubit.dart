import 'package:equatable/equatable.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:rxdart/rxdart.dart';

import '../../../account/account_server.dart';
import '../../../bloc/simple_cubit.dart';
import '../../../bloc/subscribe_mixin.dart';
import '../../../crypto/uuid/uuid.dart';
import '../../../db/extension/conversation.dart';
import '../../../db/extension/user.dart';
import '../../../db/mixin_database.dart';
import '../route/responsive_navigator_cubit.dart';

class ConversationState extends Equatable {
  const ConversationState({
    required this.conversationId,
    this.userId,
    this.initIndexMessageId,
    this.conversation,
    this.user,
  });

  final String conversationId;
  final String? userId;
  final String? initIndexMessageId;
  final ConversationItem? conversation;
  final User? user;

  bool get isLoaded => conversation != null || user != null;

  bool? get isBot => conversation?.isBotConversation ?? user?.isBot;

  bool? get isStranger =>
      conversation?.isStrangerConversation ?? user?.isStranger;

  bool? get isGroup =>
      (conversation?.isGroupConversation) ?? (user != null ? false : null);

  String? get name => conversation?.validName ?? user?.fullName;

  String? get identityNumber =>
      conversation?.ownerIdentityNumber ?? user?.identityNumber;

  UserRelationship? get relationship =>
      conversation?.relationship ?? user?.relationship;

  @override
  List<Object?> get props => [
        conversationId,
        userId,
        initIndexMessageId,
        conversation,
        user,
      ];

  ConversationState copyWith({
    final String? conversationId,
    final String? userId,
    final String? initIndexMessageId,
    final int? unseenMessageCount,
    final ConversationItem? conversation,
    final User? user,
  }) =>
      ConversationState(
        conversationId: conversationId ?? this.conversationId,
        userId: userId ?? this.userId,
        initIndexMessageId: initIndexMessageId ?? this.initIndexMessageId,
        conversation: conversation ?? this.conversation,
        user: user ?? this.user,
      );
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
      stream
          .map((event) => event?.userId)
          .where((event) => event != null)
          .distinct()
          .switchMap((event) => accountServer.database.userDao
              .findUserById(event!)
              .watchSingleOrNull())
          .listen((event) => emit(
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

  void selectConversation(String conversationId, [String? initIndexMessageId]) {
    emit(ConversationState(
      conversationId: conversationId,
      initIndexMessageId: initIndexMessageId,
    ));
    accountServer.selectConversation(conversationId);
    responsiveNavigatorCubit.pushPage(ResponsiveNavigatorCubit.chatPage);
  }

  void selectUser(String userId) {
    final conversationId = generateConversationId(userId, accountServer.userId);
    emit(ConversationState(
      conversationId: conversationId,
      userId: userId,
    ));
    accountServer.selectConversation(conversationId);
    responsiveNavigatorCubit.pushPage(ResponsiveNavigatorCubit.chatPage);
  }
}
