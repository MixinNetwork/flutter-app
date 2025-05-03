import 'package:flutter/material.dart';

import '../../ui/provider/conversation_provider.dart';
import '../../utils/extension/extension.dart';
import '../user_selector/conversation_selector.dart';
import 'actions.dart';

class CreateConversationAction extends Action<CreateConversationIntent> {
  CreateConversationAction(this.context);

  final BuildContext context;

  @override
  Object? invoke(CreateConversationIntent intent) async {
    final list = await showConversationSelector(
      context: context,
      singleSelect: true,
      title: context.l10n.createConversation,
      onlyContact: true,
    );
    if (list == null || list.isEmpty || (list.first.userId?.isEmpty ?? true)) {
      return null;
    }
    final userId = list.first.userId!;

    await ConversationStateNotifier.selectUser(context, userId);
  }
}
