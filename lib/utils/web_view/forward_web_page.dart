import 'package:flutter/widgets.dart';

import '../../db/extension/app.dart';
import '../../db/mixin_database.dart';
import '../../widgets/message/item/action_card/action_card_data.dart';
import '../../widgets/toast.dart';
import '../../widgets/user_selector/conversation_selector.dart';
import '../extension/extension.dart';

/// Forwards a web page to a conversation the user picks: as an app card when
/// it is one of the app's resources, otherwise as its link. Returns whether
/// it was sent.
Future<bool> forwardWebPage(
  BuildContext context, {
  required String url,
  String? title,
  App? app,
  AppCardData? appCardData,
}) async {
  if (appCardData?.shareable == false) {
    showToastFailed(
      ToastError(context.l10n.appCardShareDisallow),
      context: context,
    );
    return false;
  }
  final selected = await showConversationSelector(
    context: context,
    singleSelect: true,
    title: context.l10n.forward,
    onlyContact: false,
  );
  if (!context.mounted || selected == null || selected.isEmpty) return false;
  final conversation = selected.first;
  final accountServer = context.accountServer;

  return runWithToast(() async {
    var cardApp = app;
    if (appCardData?.appId case final appId?) {
      cardApp = await accountServer.getAppAndCheckUser(
        appId,
        DateTime.tryParse(appCardData?.updatedAt ?? ''),
      );
    }

    if (cardApp != null && cardApp.matchesResource(url)) {
      final pageTitle = title?.trim();
      await accountServer.sendAppCardMessage(
        conversationId: conversation.conversationId,
        recipientId: conversation.userId,
        data: AppCardData(
          cardApp.appId,
          cardApp.iconUrl,
          cardApp.name,
          pageTitle == null || pageTitle.isEmpty ? cardApp.name : pageTitle,
          url,
          cardApp.updatedAt?.toIso8601String() ?? '',
          true,
          [],
          '',
          null,
        ),
      );
      return;
    }

    final category = conversation.encryptCategory;
    if (category == null) {
      throw StateError('selected conversation encrypt category is null');
    }
    await accountServer.sendTextMessage(
      url,
      category,
      conversationId: conversation.conversationId,
      recipientId: conversation.userId,
    );
  });
}
