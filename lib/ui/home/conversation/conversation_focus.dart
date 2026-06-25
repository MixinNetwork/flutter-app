import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;

import '../../../crypto/uuid/uuid.dart';
import '../../../db/dao/conversation_dao.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/local_notification_center.dart';
import '../../../widgets/toast.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/is_bot_group_provider.dart';
import '../../provider/recent_conversation_provider.dart';
import '../chat/chat_jump_trace.dart';
import '../conversation_info_destination.dart';
import '../notifier/conversation_list_controller.dart';

class ConversationFocus {
  const ConversationFocus._();

  static Future<void> selectConversation(
    BuildContext context,
    String conversationId, {
    ConversationItem? conversation,
    String? initIndexMessageId,
    ConversationInfoDestination? initialChatSidePage,
    String? keyword,
    bool sync = false,
    bool checkCurrentUserExist = false,
  }) async {
    context.providerContainer.read(isBotGroupProvider(conversationId));

    final accountServer = context.accountServer;
    final database = context.database;
    final conversationNotifier = context.providerContainer.read(
      conversationProvider.notifier,
    );
    final state = conversationNotifier.state;

    if (state?.conversationId == conversationId &&
        initIndexMessageId == null &&
        initialChatSidePage == null &&
        keyword == null) {
      conversationNotifier.requestLatestJump();
      return;
    }

    ConversationItem? selectedConversation;
    String? lastReadMessageId;
    bool? hasUnreadMessage;
    if (state?.conversationId == conversationId) {
      selectedConversation = state?.conversation;

      hasUnreadMessage = (selectedConversation?.unseenMessageCount ?? 0) > 0;
      if (hasUnreadMessage) {
        lastReadMessageId = state?.lastReadMessageId;
      }
    }

    selectedConversation =
        conversation ??
        selectedConversation ??
        await _conversationItem(context, conversationId);

    if (selectedConversation == null && sync) {
      showToastLoading();
      await accountServer.refreshConversation(
        conversationId,
        checkCurrentUserExist: checkCurrentUserExist,
      );
      selectedConversation = await _conversationItem(context, conversationId);
    }

    hasUnreadMessage ??= (selectedConversation?.unseenMessageCount ?? 0) > 0;

    if (selectedConversation == null) {
      return showToastFailed(null);
    }

    final selectedHasUnreadMessage = hasUnreadMessage;
    final selectedInitIndexMessageId =
        initIndexMessageId ??
        (selectedHasUnreadMessage
            ? selectedConversation.lastReadMessageId
            : null);

    lastReadMessageId =
        lastReadMessageId ??
        (selectedHasUnreadMessage ? selectedInitIndexMessageId : null);

    traceChatJump(
      'focus conversation '
      'conv=${shortMessageId(conversationId)} '
      'explicitInit=${shortMessageId(initIndexMessageId)} '
      'selectedInit=${shortMessageId(selectedInitIndexMessageId)} '
      'lastRead=${shortMessageId(lastReadMessageId)} '
      'convLastRead=${shortMessageId(selectedConversation.lastReadMessageId)} '
      'unseen=${selectedConversation.unseenMessageCount} '
      'same=${state?.conversationId == conversationId}',
    );

    final ownerId = selectedConversation.ownerId;

    final appFuture =
        (!selectedConversation.isGroupConversation && ownerId != null)
        ? database.appDao.findAppById(ownerId)
        : null;

    final participantFuture =
        selectedConversation.category == ConversationCategory.contact
        ? Future<Participant?>.value()
        : database.participantDao
              .participantById(conversationId, accountServer.userId)
              .getSingleOrNull();

    final conversationState = ConversationState(
      conversationId: conversationId,
      conversation: selectedConversation,
      initIndexMessageId: selectedInitIndexMessageId,
      lastReadMessageId: lastReadMessageId,
      userId: selectedConversation.isGroupConversation
          ? null
          : selectedConversation.ownerId,
      app: await appFuture,
      initialSidePage: initialChatSidePage,
      refreshKey: Object(),
      participant: await participantFuture,
      keyword: keyword,
    );

    Toast.dismiss();
    conversationNotifier.focus(conversationState);

    unawaited(dismissByConversationId(conversationId));
    context.providerContainer
        .read(recentConversationIDsProvider.notifier)
        .add(conversationId);
  }

  static Future<void> selectUser(
    BuildContext context,
    String userId, {
    User? user,
    ConversationInfoDestination? initialChatSidePage,
  }) async {
    final accountServer = context.accountServer;
    final database = context.database;
    final conversationNotifier = context.providerContainer.read(
      conversationProvider.notifier,
    );

    final conversationId = generateConversationId(userId, accountServer.userId);

    context.providerContainer.read(isBotGroupProvider(conversationId));

    final conversation = await _conversationItem(context, conversationId);
    if (conversation != null) {
      return selectConversation(
        context,
        conversationId,
        conversation: conversation,
        initialChatSidePage: initialChatSidePage,
      );
    }

    final selectedUser =
        user ?? await database.userDao.userById(userId).getSingleOrNull();

    if (selectedUser == null) {
      return showToastFailed(ToastError(context.l10n.userNotFound));
    }

    final app = await database.appDao.findAppById(userId);

    conversationNotifier.focus(
      ConversationState(
        conversationId: conversationId,
        userId: userId,
        user: selectedUser,
        app: app,
        initialSidePage: initialChatSidePage,
        refreshKey: Object(),
      ),
    );

    unawaited(dismissByConversationId(conversationId));
  }

  static Future<ConversationItem?> _conversationItem(
    BuildContext context,
    String conversationId,
  ) async {
    final conversations = context.read<ConversationListController>().state.map;
    for (final conversation in conversations.values) {
      if (conversation.conversationId == conversationId) return conversation;
    }
    return context.database.conversationDao
        .conversationItem(conversationId)
        .getSingleOrNull();
  }
}
