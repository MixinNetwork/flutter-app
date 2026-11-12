import 'package:flutter/material.dart';

import 'command_palette_action.dart';
import 'create_circle_action.dart';
import 'create_conversation_action.dart';
import 'create_group_conversation_action.dart';

class EscapeIntent extends Intent {
  const EscapeIntent();
}

class CreateConversationIntent extends Intent {
  const CreateConversationIntent();
}

class CreateGroupConversationIntent extends Intent {
  const CreateGroupConversationIntent();
}

class CreateCircleIntent extends Intent {
  const CreateCircleIntent();
}

class ToggleCommandPaletteIntent extends Intent {
  const ToggleCommandPaletteIntent();
}

class MixinAppActions extends StatelessWidget {
  const MixinAppActions({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Actions(
    actions: {
      CreateConversationIntent: CreateConversationAction(context),
      CreateGroupConversationIntent: CreateGroupConversationAction(context),
      CreateCircleIntent: CreateCircleAction(context),
      ToggleCommandPaletteIntent: CommandPaletteAction(context),
    },
    child: child,
  );
}
