import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ui/provider/conversation_provider.dart';
import '../../utils/extension/extension.dart';
import '../user_selector/conversation_selector.dart';
import 'actions.dart';

class CreateConversationAction extends Action<CreateConversationIntent> {
  CreateConversationAction({
    required this.context,
    required this.container,
    required this.l10n,
  });

  final BuildContext context;
  final ProviderContainer container;
  final Localization l10n;

  @override
  Object? invoke(CreateConversationIntent intent) async {
    final list = await showConversationSelector(
      context: context,
      singleSelect: true,
      title: l10n.createConversation,
      onlyContact: true,
    );
    if (list == null || list.isEmpty || (list.first.userId?.isEmpty ?? true)) {
      return null;
    }
    final userId = list.first.userId!;

    await ConversationStateNotifier.selectUser(container, context, userId);
  }
}
