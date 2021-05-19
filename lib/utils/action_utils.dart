import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../account/account_server.dart';
import '../ui/home/bloc/conversation_cubit.dart';

extension ActionUtils on BuildContext {
  bool openAction(String actionText) {
    if (actionText.startsWith('input:/')) {
      final content = actionText.substring(6).trim();
      final conversationItem = read<ConversationCubit>().state;
      if (content.isNotEmpty == true && conversationItem != null) {
        read<AccountServer>().sendTextMessage(
            content, conversationItem.isPlainConversation,
            conversationId: conversationItem.conversationId);
      }

      return true;
    }
    return false;
  }
}
