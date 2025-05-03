import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:stream_transform/stream_transform.dart';

import '../blaze/vo/pin_message_minimal.dart';
import '../db/database_event_bus.dart';
import '../db/extension/conversation.dart';
import '../enum/message_category.dart';
import '../generated/l10n.dart';

import '../ui/provider/conversation_provider.dart';
import '../ui/provider/mention_cache_provider.dart';
import '../ui/provider/slide_category_provider.dart';
import '../utils/app_lifecycle.dart';
import '../utils/extension/extension.dart';
import '../utils/load_balancer_utils.dart';
import '../utils/local_notification_center.dart';
import '../utils/logger.dart';
import '../utils/message_optimize.dart';
import '../utils/reg_exp_utils.dart';
import '../widgets/message/item/pin_message.dart';
import '../widgets/message/item/system_message.dart';

const _keyConversationId = 'conversationId';

class NotificationService {
  NotificationService({required BuildContext context}) {
    streamSubscriptions
      ..add(
        DataBaseEventBus.instance.notificationMessageStream
            .where((event) => event.type == MessageCategory.messageRecall)
            .listen((event) {
              try {
                dismissByMessageId(event.messageId, event.conversationId);
              } catch (e) {
                w('dismiss notification error: $e');
              }
            }),
      )
      ..add(
        DataBaseEventBus.instance.notificationMessageStream
            .where((event) => event.type != MessageCategory.messageRecall)
            .where((event) => event.senderId != context.accountServer.userId)
            .where(
              (event) =>
                  event.createdAt != null &&
                  event.createdAt!.isAfter(
                    DateTime.now().subtract(const Duration(minutes: 2)),
                  ),
            )
            .where((event) {
              if (isAppActive) {
                final conversationState = context.providerContainer.read(
                  conversationProvider,
                );
                return event.conversationId !=
                    (conversationState?.conversationId ??
                        conversationState?.conversation?.conversationId);
              }
              return true;
            })
            .asyncMapBuffer(
              (event) =>
                  context.database.messageDao
                      .notificationMessage(
                        event.map((e) => e.messageId).toList(),
                      )
                      .get(),
            )
            .expand((event) => event)
            .asyncWhere((event) async {
              final account = context.account!;

              bool mentionedCurrentUser() => mentionNumberRegExp
                  .allMatchesAndSort(event.content ?? '')
                  .any((element) => element[1] == account.identityNumber);
              // mention current user
              if (event.type.isText && mentionedCurrentUser()) return true;

              Future<bool> quotedCurrentUser() async {
                if (event.quoteContent?.isEmpty ?? true) return false;
                try {
                  final json =
                      await jsonDecodeWithIsolate(event.quoteContent ?? '') ??
                      {};
                  // ignore: avoid_dynamic_calls
                  return json['user_id'] == account.userId;
                } catch (_) {
                  // json decode failed
                  return false;
                }
              }

              // quote current user
              if (await quotedCurrentUser()) return true;

              final muteUntil =
                  event.category == ConversationCategory.group
                      ? event.muteUntil
                      : event.ownerMuteUntil;
              return muteUntil?.isAfter(DateTime.now()) != true;
            })
            .asyncMap((event) async {
              final name = conversationValidName(
                event.groupName,
                event.ownerFullName,
              );

              String? body;
              if (context.settingChangeNotifier.messagePreview) {
                final mentionCache = context.providerContainer.read(
                  mentionCacheProvider,
                );

                if (event.type == MessageCategory.systemConversation) {
                  body = generateSystemText(
                    actionName: event.actionName,
                    participantUserId: event.participantUserId,
                    senderId: event.senderId,
                    currentUserId: context.accountServer.userId,
                    participantFullName: event.participantFullName,
                    senderFullName: event.senderFullName,
                    expireIn: int.tryParse(event.content ?? '0'),
                  );
                } else if (event.type.isPin) {
                  final pinMessageMinimal = PinMessageMinimal.fromJsonString(
                    event.content ?? '',
                  );

                  if (pinMessageMinimal == null) {
                    body = Localization.current.chatPinMessage(
                      event.senderFullName ?? '',
                      Localization.current.aMessage,
                    );
                  } else {
                    final preview = await generatePinPreviewText(
                      pinMessageMinimal: pinMessageMinimal,
                      mentionCache: mentionCache,
                    );

                    body = Localization.current.chatPinMessage(
                      event.senderFullName ?? '',
                      preview,
                    );
                  }
                } else {
                  final isGroup =
                      event.category == ConversationCategory.group ||
                      event.senderId != event.ownerUserId;

                  if (event.type.isText) {
                    body = mentionCache.replaceMention(
                      event.content,
                      await mentionCache.checkMentionCache({event.content}),
                    );
                  }
                  body = messagePreviewOptimize(
                    event.status,
                    event.type,
                    body ?? event.content,
                    false,
                    isGroup,
                    event.senderFullName,
                  );
                }
                body ??= Localization.current.messageNotSupport;
              } else {
                body = Localization.current.aMessage;
              }

              await showNotification(
                title: name,
                body: body,
                uri: Uri(
                  scheme: enumConvertToString(NotificationScheme.conversation),
                  host: event.conversationId,
                  path: event.messageId,
                  queryParameters: {
                    // use queryParameters to avoid case transform.
                    _keyConversationId: event.conversationId,
                  },
                ),
                messageId: event.messageId,
                conversationId: event.conversationId,
              );
            })
            .listen((_) {}),
      )
      ..add(
        notificationSelectEvent(NotificationScheme.conversation).listen((
          event,
        ) {
          i('select notification $event');

          context.providerContainer
              .read(slideCategoryStateProvider.notifier)
              .switchToChatsIfSettings();

          final conversationId =
              event.queryParameters[_keyConversationId] ?? event.host;
          ConversationStateNotifier.selectConversation(
            context,
            conversationId,
            initIndexMessageId: event.path,
          );
        }),
      );
  }

  List<StreamSubscription> streamSubscriptions = [];

  Future<void> close() async {
    clearNotificationEvent();
    await Future.wait(streamSubscriptions.map((e) => e.cancel()));
  }
}
