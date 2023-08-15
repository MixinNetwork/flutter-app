import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;

import '../../db/mixin_database.dart';
import '../../ui/home/bloc/conversation_cubit.dart';
import '../../utils/extension/extension.dart';
import '../avatar_view/avatar_view.dart';
import '../buttons.dart';
import '../dialog.dart';
import '../toast.dart';

Future<void> showConversationDialog(BuildContext context,
    ConversationResponse conversationResponse, String code) async {
  final localExisted = await context.database.conversationDao
      .hasConversation(conversationResponse.conversationId);
  if (!localExisted) {
    await context.accountServer
        .refreshConversation(conversationResponse.conversationId);
  }

  final existed = conversationResponse.participants
      .any((element) => element.userId == context.account?.userId);
  if (existed) {
    showToast(context.l10n.groupAlreadyIn);
    await ConversationCubit.selectConversation(
      context,
      conversationResponse.conversationId,
    );
    return;
  }

  final userIds = conversationResponse.participants
      .sublist(0, min(conversationResponse.participants.length, 4))
      .map((e) => e.userId)
      .toList();
  final users = await context.accountServer.refreshUsers(userIds);

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

class _ConversationInfo extends HookWidget {
  const _ConversationInfo({
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
          ClipOval(
            child: SizedBox.square(
              dimension: 90,
              child: AvatarPuzzlesWidget(users, 90),
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            conversationResponse.name,
            style: TextStyle(
              color: context.theme.text,
              fontSize: 16,
              height: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          SelectableText(
            context.l10n
                .participantsCount(conversationResponse.participants.length),
            style: TextStyle(
              color: context.theme.secondaryText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          DialogAddOrJoinButton(
            onTap: () => runFutureWithToast(
              () async {
                await context.accountServer.joinGroup(code);
                await ConversationCubit.selectConversation(
                    context, conversationResponse.conversationId);
                Navigator.pop(context);
              }(),
            ),
            title: Text(context.l10n.joinGroupWithPlus),
          ),
          const SizedBox(height: 56),
        ],
      );
}
