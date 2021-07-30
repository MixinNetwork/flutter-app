import 'dart:async';

import 'package:desktop_lifecycle/desktop_lifecycle.dart';
import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';
import 'package:stream_transform/stream_transform.dart';

import '../db/extension/conversation.dart';
import '../db/extension/message_category.dart';
import '../enum/message_category.dart';
import '../ui/home/bloc/conversation_cubit.dart';
import '../ui/home/bloc/slide_category_cubit.dart';
import '../ui/home/local_notification_center.dart';
import '../utils/extension/extension.dart';
import '../utils/load_balancer_utils.dart';
import '../utils/message_optimize.dart';
import '../utils/reg_exp_utils.dart';
import '../widgets/message/item/system_message.dart';
import '../widgets/message/item/text/mention_builder.dart';

class NotificationService {
  NotificationService({
    required BuildContext context,
  }) {
    streamSubscriptions
      ..add(context.database.messageDao.notificationMessageStream
          .where((event) {
            if (DesktopLifecycle.instance.isActive.value) {
              final conversationState = context.read<ConversationCubit>().state;
              return event.conversationId !=
                  (conversationState?.conversationId ??
                      conversationState?.conversation?.conversationId);
            }
            return true;
          })
          .where((event) => event.senderId != context.accountServer.userId)
          .asyncWhere((event) async {
            final muteUntil = event.category == ConversationCategory.group
                ? event.muteUntil
                : event.ownerMuteUntil;
            if (muteUntil?.isAfter(DateTime.now()) != true) return true;

            if (!event.type.isText) return false;

            final account = context.multiAuthState.current!.account;

            // mention current user
            if (mentionNumberRegExp
                .allMatches(event.content ?? '')
                .any((element) => element[1] == account.identityNumber)) {
              return true;
            }

            // quote current user
            if (event.quoteContent?.isNotEmpty ?? false) {
              // ignore: avoid_dynamic_calls
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

            var body = event.content;
            if (context.multiAuthState.currentMessagePreview) {
              if (event.type == MessageCategory.systemConversation) {
                body = generateSystemText(
                  actionName: event.actionName,
                  participantIsCurrentUser:
                      event.participantUserId == context.accountServer.userId,
                  relationship: event.relationship,
                  participantFullName: event.participantFullName,
                  senderFullName: event.senderFullName,
                  groupName: event.groupName,
                );
              } else {
                final isGroup = event.category == ConversationCategory.group ||
                    event.senderId != event.ownerUserId;

                if (event.type.isText) {
                  final mentionCache = context.read<MentionCache>();
                  body = mentionCache.replaceMention(
                    event.content,
                    await mentionCache.checkMentionCache({event.content!}),
                  );
                }
                body = await messagePreviewOptimize(
                  event.status,
                  event.type,
                  body,
                  false,
                  isGroup,
                  event.senderFullName,
                );
              }
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
            ConversationCubit.selectConversation(
              context,
              event.host,
              initIndexMessageId: event.path,
            );
          },
        ),
      );
  }

  List<StreamSubscription> streamSubscriptions = [];

  Future<void> close() async {
    await Future.wait(streamSubscriptions.map((e) => e.cancel()));
  }
}
