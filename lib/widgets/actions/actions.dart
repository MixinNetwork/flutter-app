import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ui/provider/account_server_provider.dart';
import '../../ui/provider/ui_context_providers.dart';
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

class MixinAppActions extends ConsumerWidget {
  const MixinAppActions({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountServer = ref.read(accountServerProvider).value;
    final l10n = ref.watch(localizationProvider);
    if (accountServer == null) {
      return child;
    }
    return Actions(
      actions: {
        CreateConversationIntent: CreateConversationAction(
          context: context,
          container: ref.container,
          l10n: l10n,
        ),
        CreateGroupConversationIntent: CreateGroupConversationAction(
          context: context,
          accountServer: accountServer,
          l10n: l10n,
        ),
        CreateCircleIntent: CreateCircleAction(
          context: context,
          accountServer: accountServer,
          l10n: l10n,
        ),
        ToggleCommandPaletteIntent: CommandPaletteAction(
          context,
          ref.container,
        ),
      },
      child: child,
    );
  }
}
