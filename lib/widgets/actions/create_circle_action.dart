import 'package:flutter/material.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../utils/extension/extension.dart';
import '../dialog.dart';
import '../toast.dart';
import '../user_selector/conversation_selector.dart';
import 'actions.dart';

class CreateCircleAction extends Action<CreateCircleIntent> {
  CreateCircleAction(this.context);

  final BuildContext context;

  @override
  Future<void> invoke(CreateCircleIntent intent) async {
    final name = await showMixinDialog<String>(
      context: context,
      child: EditDialog(
        title: Text(context.l10n.circles),
        hintText: context.l10n.editCircleName,
        maxLength: 64,
      ),
    );

    if (name?.isEmpty ?? true) return;

    final list = await showConversationSelector(
      context: context,
      singleSelect: false,
      title: context.l10n.createCircle,
      onlyContact: false,
      allowEmpty: true,
    );

    if (list == null) return;

    await runFutureWithToast(
      context.accountServer.createCircle(
        name!,
        list
            .map(
              (e) => CircleConversationRequest(
                action: CircleConversationAction.add,
                conversationId: e.conversationId,
                userId: e.userId,
              ),
            )
            .toList(),
      ),
    );
  }
}
