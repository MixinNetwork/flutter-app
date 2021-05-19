import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';
import 'package:stream_transform/stream_transform.dart';

import '../db/extension/conversation.dart';
import '../db/extension/message_category.dart';
import '../ui/home/bloc/conversation_cubit.dart';
import '../ui/home/bloc/multi_auth_cubit.dart';
import '../ui/home/bloc/slide_category_cubit.dart';
import '../ui/home/local_notification_center.dart';
import '../utils/load_balancer_utils.dart';
import '../utils/message_optimize.dart';
import '../utils/reg_exp_utils.dart';
import 'account_server.dart';

class NotificationService extends WidgetsBindingObserver {
  NotificationService({
    required BuildContext context,
  }) {
    assert(WidgetsBinding.instance != null);
    WidgetsBinding.instance!.addObserver(this);
    streamSubscriptions
      ..add(context
          .read<AccountServer>()
          .database
          .messagesDao
          .notificationMessageStream
          .where((event) {
            if (active) {
              final conversationState = context.read<ConversationCubit>().state;
              return event.conversationId !=
                  (conversationState?.conversationId ??
                      conversationState?.conversation?.conversationId);
            }
            return true;
          })
          .where(
              (event) => event.senderId != context.read<AccountServer>().userId)
          .asyncWhere((event) async {
            final muteUntil = event.category == ConversationCategory.group
                ? event.muteUntil
                : event.ownerMuteUntil;
            if (muteUntil?.isAfter(DateTime.now()) != true) return true;

            if (!event.type.isText) return false;

            final account =
                context.read<MultiAuthCubit>().state.current!.account;

            // mention current user
            if (mentionNumberRegExp
                .allMatches(event.content ?? '')
                .any((element) => element[0] == '@${account.identityNumber}')) {
              return true;
            }

            // quote current user
            if (event.quoteContent?.isNotEmpty ?? false) {
              if ((await jsonDecodeWithIsolate(event.quoteContent ?? '') ??
                      {})['user_id'] ==
                  account.userId) return true;
            }

            return false;
          })
          .where((event) => event.createdAt
              .isAfter(DateTime.now().subtract(const Duration(minutes: 2))))
          .asyncMap((event) async {
            final name = conversationValidName(
              event.groupName,
              event.ownerFullName,
            );

            String? body;
            if (context.read<MultiAuthCubit>().state.currentMessagePreview) {
              body = (await messageOptimize(
                event.status,
                event.type,
                event.content,
                false,
              ))
                  .item2;
            }
            if ((body?.isNotEmpty ?? false) &&
                (event.category == ConversationCategory.group ||
                    event.senderId != event.ownerUserId)) {
              body = '${event.senderFullName} : $body';
            }

            await showNotification(
              title: name,
              body: body,
              uri: Uri(
                scheme: EnumToString.convertToString(
                    NotificationScheme.conversation),
                host: event.conversationId,
                path: event.messageId,
              ),
            );
          })
          .listen((_) {}))
      ..add(
        notificationSelectEvent(NotificationScheme.conversation).listen(
          (event) {
            final slideCategoryCubit = context.read<SlideCategoryCubit>();
            if (slideCategoryCubit.state.type == SlideCategoryType.setting) {
              slideCategoryCubit.select(SlideCategoryType.chats);
            }
            context
                .read<ConversationCubit>()
                .selectConversation(event.host, event.path);
          },
        ),
      );
  }

  List<StreamSubscription> streamSubscriptions = [];
  bool active = true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
  }

  Future<void> close() async {
    await Future.wait(streamSubscriptions.map((e) => e.cancel()));
    WidgetsBinding.instance!.removeObserver(this);
  }
}
