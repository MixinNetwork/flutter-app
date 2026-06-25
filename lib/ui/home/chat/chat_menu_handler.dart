import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/extension/extension.dart';
import '../../../widgets/conversation/mute_dialog.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/toast.dart';
import '../../../widgets/window/menus.dart';
import '../../provider/conversation_provider.dart';
import '../conversation_info_destination.dart';
import '../notifier/chat_side_notifier.dart';

class ChatMenuHandler extends HookConsumerWidget {
  const ChatMenuHandler({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationId = ref.watch(currentConversationIdProvider);

    useEffect(() {
      final menuBarNotifier = ref.read(macMenuBarProvider.notifier);
      if (conversationId == null) return null;

      final handle = _ConversationHandle(context, conversationId);
      Future(() => menuBarNotifier.attach(handle));
      return () => Future(() => menuBarNotifier.unAttach(handle));
    }, [conversationId]);

    return child;
  }
}

class _ConversationHandle extends ConversationMenuHandle {
  _ConversationHandle(this.context, this.conversationId);

  final BuildContext context;
  final String conversationId;

  @override
  Future<void> delete() async {
    final name =
        context.providerContainer.read(currentConversationNameProvider) ?? '';
    assert(name.isNotEmpty, 'name is empty');
    final ret = await showConfirmMixinDialog(
      context,
      context.l10n.conversationDeleteTitle(name),
      description: context.l10n.deleteChatDescription,
    );
    if (ret == null) return;
    await context.accountServer.deleteMessagesByConversationId(conversationId);
    await context.database.conversationDao.deleteConversation(conversationId);
    if (context.providerContainer.read(currentConversationIdProvider) ==
        conversationId) {
      context.providerContainer
          .read(conversationProvider.notifier)
          .unselected();
    }
  }

  @override
  Stream<bool> get isMuted => context.providerContainer
      .read(conversationProvider.notifier)
      .stream
      .map((event) => event?.conversation?.isMute == true);

  @override
  Stream<bool> get isPinned => context.providerContainer
      .read(conversationProvider.notifier)
      .stream
      .map((event) => event?.conversation?.pinTime != null);

  @override
  Future<void> mute() async {
    final result = await showMixinDialog<int?>(
      context: context,
      child: const MuteDialog(),
    );
    if (result == null) return;
    final conversationState = context.providerContainer.read(
      conversationProvider,
    );
    if (conversationState == null) return;

    final isGroupConversation = conversationState.isGroup == true;
    await runFutureWithToast(
      context.accountServer.muteConversation(
        result,
        conversationId: isGroupConversation ? conversationId : null,
        userId: isGroupConversation
            ? null
            : conversationState.conversation?.ownerId,
      ),
    );
  }

  @override
  void pin() {
    runFutureWithToast(context.accountServer.pin(conversationId));
  }

  @override
  void showSearch() {
    context.read<ChatSideNotifier>().toggleDestination(
      ConversationInfoDestination.searchMessageHistory,
    );
  }

  @override
  void toggleSideBar() {
    context.read<ChatSideNotifier>().toggleInfoPage();
  }

  @override
  void unPin() {
    runFutureWithToast(context.accountServer.unpin(conversationId));
  }

  @override
  void unmute() {
    final conversationState = context.providerContainer.read(
      conversationProvider,
    );
    if (conversationState == null) return;

    final isGroup = conversationState.isGroup == true;
    runFutureWithToast(
      context.accountServer.unMuteConversation(
        conversationId: isGroup ? conversationId : null,
        userId: isGroup ? null : conversationState.conversation?.ownerId,
      ),
    );
  }
}
