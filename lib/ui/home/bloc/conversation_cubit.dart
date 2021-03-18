import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/simple_cubit.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/local_notification_center.dart';

class ConversationCubit extends SimpleCubit<ConversationItem?>
    with SubscribeMixin {
  ConversationCubit({
    required this.accountServer,
    required LocalNotificationCenter localNotificationCenter,
  }) : super(null) {
    addSubscription(
      localNotificationCenter
          .notificationSelectEvent(NotificationScheme.conversation)
          .asyncMap((event) => accountServer.database.conversationDao
              .conversationItem(event.host))
          .where((event) => event != null)
          .listen(emit),
    );
  }

  final AccountServer accountServer;

  @override
  void emit(ConversationItem? state) {
    accountServer.selectConversation(state?.conversationId);
    super.emit(state);
  }
}
