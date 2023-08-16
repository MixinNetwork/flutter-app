import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../db/mixin_database.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../avatar_view/avatar_view.dart';
import '../dialog.dart';
import '../toast.dart';
import '../user_selector/conversation_selector.dart';
import 'actions.dart';

class CreateGroupConversationAction
    extends Action<CreateGroupConversationIntent> {
  CreateGroupConversationAction(this.context);

  final BuildContext context;

  @override
  Future<void> invoke(CreateGroupConversationIntent intent) async {
    final result = await showConversationSelector(
      context: context,
      singleSelect: false,
      title: context.l10n.createGroup,
      onlyContact: true,
    );
    if (result == null || result.isEmpty) return;
    final userIds = result
        .where((e) => e.userId != null)
        .map(
          (e) => e.userId!,
        )
        .toList();

    final name = await showMixinDialog<String>(
      context: context,
      child:
          _NewConversationConfirm([context.accountServer.userId, ...userIds]),
    );
    if (name?.isEmpty ?? true) return;

    await runFutureWithToast(
      context.accountServer.createGroupConversation(name!, userIds),
    );
  }
}

class _NewConversationConfirm extends HookConsumerWidget {
  const _NewConversationConfirm(
    this.userIds,
  );

  final List<String> userIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = useMemoizedFuture(
      () => context.database.userDao
          .usersByIn(userIds.sublist(0, math.min(4, userIds.length)))
          .get(),
      <User>[],
    ).requireData;

    final textEditingController = useTextEditingController();
    final textEditingValue = useValueListenable(textEditingController);
    return AlertDialogLayout(
      title: Text(context.l10n.groups),
      titleMarginBottom: 24,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: SizedBox(
              height: 60,
              width: 60,
              child: AvatarPuzzlesWidget(users, 60),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.participantsCount(userIds.length),
            style: TextStyle(
              fontSize: 14,
              color: context.theme.secondaryText,
            ),
          ),
          const SizedBox(height: 48),
          DialogTextField(
            textEditingController: textEditingController,
            hintText: context.l10n.groupName,
            maxLength: 40,
          ),
        ],
      ),
      actions: [
        MixinButton(
            backgroundTransparent: true,
            onTap: () => Navigator.pop(context),
            child: Text(context.l10n.cancel)),
        MixinButton(
          disable: textEditingValue.text.isEmpty,
          onTap: () => Navigator.pop(context, textEditingController.text),
          child: Text(context.l10n.create),
        ),
      ],
    );
  }
}
