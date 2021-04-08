import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

extension ActionUtils on BuildContext {
  bool openAction(String actionText) {
    if (actionText.startsWith('input:/')) {
      final content = actionText.substring(6).trim();
      final conversationItem = read<ConversationCubit>().state;
      if (content.isNotEmpty == true && conversationItem != null)
        read<AccountServer>().sendTextMessage(
          content,
          conversationId: conversationItem.conversationId
        );

      return true;
    }
    return false;
  }
}
