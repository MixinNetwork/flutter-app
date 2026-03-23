import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../blaze/vo/pin_message_minimal.dart';
import '../../../constants/resources.dart';
import '../../../utils/extension/extension.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/message/message.dart';
import '../../../widgets/message/message_day_time.dart';
import '../../provider/account_server_provider.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/ui_context_providers.dart';
import '../providers/home_scope_providers.dart';

class PinMessagesPage extends HookConsumerWidget {
  const PinMessagesPage(this.conversationState, {super.key});

  final ConversationState conversationState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final conversationId = conversationState.conversationId;
    final rawList = ref.watch(pinnedMessagesProvider(conversationId)).value;

    useEffect(() {
      if (rawList?.isNotEmpty ?? true) return;
      scheduleMicrotask(() => Navigator.pop(context));
    }, [rawList?.isNotEmpty]);

    final list = (rawList ?? []).reversed.toList();
    final scrollController = useMemoized(ScrollController.new);
    final listKey = useMemoized(() => GlobalKey(debugLabel: 'PinMessagesPage'));

    return Scaffold(
      backgroundColor: theme.popUp,
      appBar: MixinAppBar(
        title: Text(l10n.pinnedMessageTitle(list.length, list.length)),
        backgroundColor: theme.popUp,
        actions: [
          if (!Navigator.of(context).canPop())
            ActionButton(
              name: Resources.assetsImagesIcCloseSvg,
              color: theme.icon,
              onTap: () =>
                  ref.read(chatSideControllerProvider.notifier).onPopPage(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MessageDayTimeViewportWidget.singleList(
              scrollController: scrollController,
              listKey: listKey,
              reTraversalKey: list,
              reverse: true,
              child: ListView.builder(
                key: listKey,
                reverse: true,
                padding: const EdgeInsets.only(bottom: 16),
                controller: scrollController,
                itemBuilder: (context, index) {
                  final messageItem = list[index];
                  return MessageItemWidget(
                    key: ValueKey(messageItem.messageId),
                    prev: list.getOrNull(index + 1),
                    message: messageItem,
                    next: list.getOrNull(index - 1),
                    blink: false,
                    isPinnedPage: true,
                  );
                },
                itemCount: list.length,
              ),
            ),
          ),
          InteractiveDecoratedBox(
            cursor: SystemMouseCursors.click,
            onTap: () async {
              await showMixinDialog<bool>(
                context: context,
                child: Builder(
                  builder: (context) => AlertDialogLayout(
                    title: Text(l10n.unpinAllMessagesConfirmation),
                    content: const SizedBox(),
                    actions: [
                      MixinButton(
                        backgroundTransparent: true,
                        onTap: () => Navigator.pop(context),
                        child: Text(l10n.cancel),
                      ),
                      MixinButton(
                        onTap: () {
                          Navigator.pop(context);
                          ref
                              .read(accountServerProvider)
                              .requireValue
                              .unpinMessage(
                                conversationId: conversationId,
                                pinMessageMinimals: list
                                    .map(
                                      (e) => PinMessageMinimal(
                                        type: e.type,
                                        messageId: e.messageId,
                                        content: e.content,
                                      ),
                                    )
                                    .toList(),
                              );
                        },
                        child: Text(l10n.confirm),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Container(
              height: 56,
              alignment: Alignment.center,
              child: Text(
                l10n.unpinAllMessages,
                style: TextStyle(fontSize: 16, color: theme.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
