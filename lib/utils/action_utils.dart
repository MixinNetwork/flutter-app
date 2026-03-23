import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../ui/provider/account_server_provider.dart';
import '../ui/provider/conversation_provider.dart';

extension OpenUriExtension on BuildContext {
  bool openAction(WidgetRef ref, String actionText) {
    if (actionText.startsWith('input:')) {
      final content = actionText.substring(6).trim();
      final conversationItem = ref.read(conversationProvider);
      final accountServer = ref.read(accountServerProvider).value;
      if (content.isNotEmpty && conversationItem != null) {
        accountServer?.sendTextMessage(
          content,
          conversationItem.encryptCategory,
          conversationId: conversationItem.conversationId,
        );
      }

      return true;
    }
    return false;
  }
}
