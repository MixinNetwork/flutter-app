import 'package:flutter/material.dart';

import 'create_circle_action.dart';
import 'create_conversation_action.dart';
import 'create_group_conversation_action.dart';

class CreateConversationIntent extends Intent {
  const CreateConversationIntent();
}

class CreateGroupConversationIntent extends Intent {
  const CreateGroupConversationIntent();
}

class CreateCircleIntent extends Intent {
  const CreateCircleIntent();
}

class MixinAppActions extends StatelessWidget {
  const MixinAppActions({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) => Actions(
        actions: {
          CreateConversationIntent: CreateConversationAction(context),
          CreateGroupConversationIntent: CreateGroupConversationAction(context),
          CreateCircleIntent: CreateCircleAction(context),
        },
        child: child,
      );
}
