import 'package:flutter/widgets.dart';

import '../ui/provider/conversation_provider.dart';
import 'extension/extension.dart';

extension OpenUriExtension on BuildContext {
  bool openAction(String actionText) {
    if (actionText.startsWith('input:')) {
      final content = actionText.substring(6).trim();
      final conversationItem = providerContainer.read(conversationProvider);
      if (content.isNotEmpty && conversationItem != null) {
        accountServer.sendTextMessage(
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
