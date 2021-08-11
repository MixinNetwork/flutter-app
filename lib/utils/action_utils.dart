import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../ui/home/bloc/conversation_cubit.dart';
import 'extension/extension.dart';

extension OpenUriExtension on BuildContext {
  bool openAction(String actionText) {
    if (actionText.startsWith('input:')) {
      final content = actionText.substring(6).trim();
      final conversationItem = read<ConversationCubit>().state;
      if (content.isNotEmpty == true && conversationItem != null) {
        accountServer.sendTextMessage(content, conversationItem.encryptCategory,
            conversationId: conversationItem.conversationId);
      }

      return true;
    }
    return false;
  }
}
