import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;

import '../../account/account_server.dart';
import '../../db/database.dart';
import '../../db/mixin_database.dart';
import '../../ui/provider/account_server_provider.dart';
import '../../ui/provider/conversation_provider.dart';
import '../../ui/provider/ui_context_providers.dart';
import '../../utils/extension/extension.dart';
import '../avatar_view/avatar_view.dart';
import '../buttons.dart';
import '../dialog.dart';
import '../high_light_text.dart';
import '../toast.dart';

Future<void> showConversationDialog(
  BuildContext context,
  ProviderContainer container,
  ConversationResponse conversationResponse,
  String code, {
  required Database database,
  required AccountServer accountServer,
  required Account? account,
  required Localization l10n,
}) async {
  final localExisted = await database.conversationDao.hasConversation(
    conversationResponse.conversationId,
  );
  if (!localExisted) {
    await accountServer.refreshConversation(
      conversationResponse.conversationId,
    );
  }
  final existed = conversationResponse.participants.any(
    (element) => element.userId == account?.userId,
  );
  if (existed) {
    showToast(l10n.groupAlreadyIn);
    await ConversationStateNotifier.selectConversation(
      container,
      context,
      conversationResponse.conversationId,
    );
    return;
  }

  final userIds = conversationResponse.participants
      .sublist(0, min(conversationResponse.participants.length, 4))
      .map((e) => e.userId)
      .toList();
  final users = await accountServer.refreshUsers(userIds);

  Toast.dismiss();
  await showMixinDialog(
    context: context,
    child: _ConversationDialog(
      conversationResponse: conversationResponse,
      users: users!,
      code: code,
    ),
  );
}

class _ConversationDialog extends StatelessWidget {
  const _ConversationDialog({
    required this.conversationResponse,
    required this.users,
    required this.code,
  });

  final ConversationResponse conversationResponse;
  final List<User> users;
  final String code;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 340,
        child: Column(
          children: [
            const Row(
              children: [
                Spacer(),
                Padding(
                  padding: EdgeInsets.only(right: 12, top: 12),
                  child: MixinCloseButton(),
                ),
              ],
            ),
            _ConversationInfo(
              conversationResponse: conversationResponse,
              users: users,
              code: code,
            ),
          ],
        ),
      ),
    ],
  );
}

class _ConversationInfo extends HookConsumerWidget {
  const _ConversationInfo({
    required this.conversationResponse,
    required this.users,
    required this.code,
  });

  final ConversationResponse conversationResponse;
  final List<User> users;
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final brightnessTheme = ref.watch(brightnessThemeDataProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: SizedBox.square(
            dimension: 90,
            child: AvatarPuzzlesWidget(users, 90),
          ),
        ),
        const SizedBox(height: 8),
        CustomSelectableText(
          conversationResponse.name,
          style: TextStyle(
            color: brightnessTheme.text,
            fontSize: 16,
            height: 1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        CustomSelectableText(
          l10n.participantsCount(conversationResponse.participants.length),
          style: TextStyle(
            color: brightnessTheme.secondaryText,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        DialogAddOrJoinButton(
          onTap: () => runFutureWithToast(() async {
            await ref.read(accountServerProvider).requireValue.joinGroup(code);
            await ConversationStateNotifier.selectConversation(
              ref.container,
              context,
              conversationResponse.conversationId,
            );
            Navigator.pop(context);
          }()),
          title: Text(l10n.joinGroupWithPlus),
        ),
        const SizedBox(height: 56),
      ],
    );
  }
}
