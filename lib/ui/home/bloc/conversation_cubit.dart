import 'package:equatable/equatable.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/simple_cubit.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/crypto/uuid/uuid.dart';
import 'package:flutter_app/db/extension/conversation.dart';
import 'package:flutter_app/db/extension/user.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/local_notification_center.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator_cubit.dart';
import 'package:flutter_app/utils/message_optimize.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

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
  }) {
    return ConversationState(
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      initIndexMessageId: initIndexMessageId ?? this.initIndexMessageId,
      conversation: conversation ?? this.conversation,
      user: user ?? this.user,
    );
  }
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
          .flatMap((event) => accountServer.database.conversationDao
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
          .flatMap((event) => accountServer.database.userDao
              .findUserById(event!)
              .watchSingleOrNull())
          .listen((event) => emit(
                state?.copyWith(user: event),
              )),
    );

    addSubscription(
      LocalNotificationCenter.notificationSelectEvent(
              NotificationScheme.conversation)
          .listen((event) {
        selectConversation(event.host, event.path);
      }),
    );
    addSubscription(
      accountServer.database.messagesDao.insertMessageStream
          .where((event) => event.userId != accountServer.userId)
          .where((event) => event.conversationId != state?.conversationId)
          .where((event) => event.muteUntil?.isAfter(DateTime.now()) != true)
          .asyncMap(
            (event) async => Tuple2(
              event,
              await messageOptimize(
                event.status,
                event.type,
                event.content,
                false,
              ),
            ),
          )
          .listen(
        (event) {
          final message = event.item1;
          final name = conversationValidName(
            message.groupName,
            message.userFullName,
          );

          LocalNotificationCenter.showNotification(
            title: name,
            body: event.item2.item2 ?? '',
            uri: Uri(
              scheme:
                  EnumToString.convertToString(NotificationScheme.conversation),
              host: message.conversationId,
              path: message.messageId,
            ),
          );
        },
      ),
    );
  }

  final AccountServer accountServer;
  final ResponsiveNavigatorCubit responsiveNavigatorCubit;

  void unselected() {
    emit(null);
    responsiveNavigatorCubit.clear();
  }

  void selectConversation(String conversationId, [String? initIndexMessageId]) {
    emit(ConversationState(
      conversationId: conversationId,
      initIndexMessageId: initIndexMessageId,
    ));
    responsiveNavigatorCubit.pushPage(ResponsiveNavigatorCubit.chatPage);
  }

  void selectUser(String userId) {
    final conversationId = generateConversationId(userId, accountServer.userId);
    emit(ConversationState(
      conversationId: conversationId,
      userId: userId,
    ));
    responsiveNavigatorCubit.pushPage(ResponsiveNavigatorCubit.chatPage);
  }
}
