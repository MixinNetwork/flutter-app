import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/simple_cubit.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/local_notification_center.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator_cubit.dart';
import 'package:flutter_app/utils/message_optimize.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:tuple/tuple.dart';

class ConversationCubit extends SimpleCubit<ConversationItem?>
    with SubscribeMixin {
  ConversationCubit({
    required this.accountServer,
    required ResponsiveNavigatorCubit responsiveNavigatorCubit,
  }) : super(null) {
    addSubscription(
      LocalNotificationCenter.notificationSelectEvent(
              NotificationScheme.conversation)
          .asyncMap((event) => accountServer.database.conversationDao
              .conversationItem(event.host))
          .where((event) => event != null)
          .listen((event) {
            emit(event);
            responsiveNavigatorCubit
                .pushPage(ResponsiveNavigatorCubit.chatPage);
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
          final conversation = event.item1;
          final name = conversation.groupName?.trim().isNotEmpty == true
              ? conversation.groupName
              : conversation.userFullName ?? '';

          LocalNotificationCenter.showNotification(
            title: name ?? '',
            body: event.item2.item2 ?? '',
            uri: Uri(
              scheme:
                  EnumToString.convertToString(NotificationScheme.conversation),
              host: conversation.conversationId,
            ),
          );
        },
      ),
    );
  }

  int? initIndex;
  final AccountServer accountServer;

  @override
  void emit(ConversationItem? state) {
    accountServer.selectConversation(state?.conversationId);
    super.emit(state);
  }
}
