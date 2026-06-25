import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../../constants/resources.dart';
import '../../../db/database_event_bus.dart';
import '../../../db/mixin_database.dart' hide Offset;
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/menu.dart';
import '../../../widgets/message/message_bubble.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/pending_chat_jump_provider.dart';
import '../notifier/message_controller.dart';
import 'chat_scroll_coordinator.dart';
import 'message_jump.dart';

class JumpCurrentButton extends HookConsumerWidget {
  const JumpCurrentButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollCoordinator = context.read<ChatScrollCoordinator>();

    final state = useValueListenable(context.read<MessageController>());
    final showJumpToLatest = useValueListenable(
      scrollCoordinator.showJumpToLatest,
    );

    final enable = (!state.isEmpty && !state.isLatest) || showJumpToLatest;

    final pendingJumpController = ref.read(pendingChatJumpProvider.notifier);

    if (!enable) {
      Future(() => pendingJumpController.state = null);
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InteractiveDecoratedBox(
        onTap: () async {
          final messageId = pendingJumpController.state;
          if (messageId != null) {
            await context.jumpToMessageInChat(messageId);
            pendingJumpController.state = null;
            return;
          }
          await context.jumpToLatestInChat();
        },
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: context.messageBubbleColor(false),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.15),
                offset: Offset(0, 2),
                blurRadius: 10,
              ),
            ],
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            Resources.assetsImagesJumpCurrentArrowSvg,
            colorFilter: ColorFilter.mode(context.theme.text, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

class JumpMentionButton extends HookConsumerWidget {
  const JumpMentionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationId = ref.watch(currentConversationIdProvider);
    final messageMentions =
        useMemoizedStream(() {
          if (conversationId == null) return Stream.value(<MessageMention>[]);
          return context.database.messageMentionDao
              .unreadMentionMessageByConversationId(conversationId)
              .watchWithStream(
                eventStreams: [
                  DataBaseEventBus.instance.watchUpdateMessageMention(
                    conversationIds: [conversationId],
                  ),
                ],
                duration: kSlowThrottleDuration,
              );
        }, keys: [conversationId]).data ??
        [];

    if (messageMentions.isEmpty) return const SizedBox();

    return CustomContextMenuWidget(
      hitTestBehavior: HitTestBehavior.translucent,
      desktopMenuWidgetBuilder: CustomDesktopMenuWidgetBuilder(),
      menuProvider: (request) => Menu(
        children: [
          MenuAction(
            title: context.l10n.clear,
            callback: () {
              for (final mention in messageMentions) {
                context.accountServer.markMentionRead(
                  mention.messageId,
                  mention.conversationId,
                );
              }
            },
          ),
        ],
      ),
      child: InteractiveDecoratedBox(
        onTap: () async {
          if (messageMentions.isEmpty) return;

          final mention = messageMentions.first;
          await context.jumpToMessageInChat(mention.messageId);
          await context.accountServer.markMentionRead(
            mention.messageId,
            mention.conversationId,
          );
        },
        child: SizedBox(
          height: 52,
          width: 40,
          child: Stack(
            children: [
              Positioned(
                top: 12,
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: context.messageBubbleColor(false),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.15),
                        offset: Offset(0, 2),
                        blurRadius: 10,
                      ),
                    ],
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '@',
                    style: TextStyle(
                      fontSize: 17,
                      height: 1,
                      color: context.theme.text,
                    ),
                  ),
                ),
              ),
              Container(
                width: 40,
                alignment: Alignment.topCenter,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    maxWidth: 40,
                    maxHeight: 20,
                    minHeight: 20,
                  ),
                  decoration: BoxDecoration(
                    color: context.theme.accent,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      const Spacer(),
                      Text(
                        messageMentions.length > 99
                            ? '99+'
                            : '${messageMentions.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
