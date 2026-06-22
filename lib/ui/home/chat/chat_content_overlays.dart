import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../../account/scam_warning_key_value.dart';
import '../../../account/show_pin_message_key_value.dart';
import '../../../constants/resources.dart';
import '../../../db/database_event_bus.dart';
import '../../../db/mixin_database.dart' hide Offset;
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/animated_visibility.dart';
import '../../../widgets/high_light_text.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/menu.dart';
import '../../../widgets/message/message_bubble.dart';
import '../../../widgets/pin_bubble.dart';
import '../../provider/conversation_provider.dart';
import '../conversation_info_destination.dart';
import '../hook/pin_message.dart';
import '../notifier/chat_side_notifier.dart';
import 'chat_history_viewport.dart';
import 'message_jump.dart';

class ChatContentOverlays extends StatelessWidget {
  const ChatContentOverlays({super.key});

  @override
  Widget build(BuildContext context) => const Stack(
    children: [
      RepaintBoundary(child: ChatHistoryViewport()),
      Positioned(left: 6, right: 6, bottom: 6, child: _BottomBanner()),
      Positioned(
        bottom: 16,
        right: 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_JumpMentionButton(), JumpCurrentButton()],
        ),
      ),
      _PinMessagesBanner(),
    ],
  );
}

class _BottomBanner extends HookConsumerWidget {
  const _BottomBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (userId, isScam) = ref.watch(
      conversationProvider.select(
        (value) => (value?.userId, (value?.user?.isScam ?? 0) > 0),
      ),
    );

    final showScamWarning =
        useMemoizedStream(
          () {
            if (userId == null || !isScam) return Stream.value(false);
            return ScamWarningKeyValue.instance.watch(userId);
          },
          initialData: false,
          keys: [userId],
        ).data ??
        false;

    return AnimatedVisibility(
      visible: showScamWarning,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          color: context.messageBubbleColor(false),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.15),
              offset: Offset(0, 2),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 16,
                top: 8,
                bottom: 8,
              ),
              child: SvgPicture.asset(
                Resources.assetsImagesTriangleWarningSvg,
                colorFilter: ColorFilter.mode(
                  context.theme.red,
                  BlendMode.srcIn,
                ),
                width: 26,
                height: 26,
              ),
            ),
            Expanded(
              child: Text(
                context.l10n.scamWarning,
                style: TextStyle(color: context.theme.text, fontSize: 14),
              ),
            ),
            ActionButton(
              name: Resources.assetsImagesIcCloseSvg,
              color: context.theme.icon,
              size: 20,
              onTap: () {
                if (userId == null) return;
                ScamWarningKeyValue.instance.dismiss(userId);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PinMessagesBanner extends HookConsumerWidget {
  const _PinMessagesBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPinMessageIds = context.watchCurrentPinMessageIds;
    final lastMessage = context.lastMessage;

    final showLastPinMessage = lastMessage?.isNotEmpty ?? false;

    return Positioned(
      top: 12,
      right: 16,
      left: 10,
      height: 64,
      child: AnimatedVisibility(
        visible: showLastPinMessage || currentPinMessageIds.isNotEmpty,
        child: Row(
          children: [
            Expanded(
              child: AnimatedVisibility(
                visible: showLastPinMessage,
                child: PinMessageBubble(
                  child: Row(
                    children: [
                      ActionButton(
                        name: Resources.assetsImagesIcCloseSvg,
                        color: context.theme.icon,
                        size: 20,
                        onTap: () {
                          final conversationId = ref.read(
                            currentConversationIdProvider,
                          );
                          if (conversationId == null) return;
                          ShowPinMessageKeyValue.instance.dismiss(
                            conversationId,
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: InteractiveDecoratedBox(
                          cursor: SystemMouseCursors.click,
                          onTap: () {
                            final messageId = currentPinMessageIds.firstOrNull;
                            if (messageId == null) return;
                            unawaited(context.jumpToMessageInChat(messageId));
                          },
                          child: CustomText(
                            (lastMessage ?? '').overflow,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedVisibility(
              visible: currentPinMessageIds.isNotEmpty,
              child: InteractiveDecoratedBox(
                onTap: () {
                  context.read<ChatSideNotifier>().toggleDestination(
                    ConversationInfoDestination.pinMessages,
                  );
                },
                child: Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.messageBubbleColor(false),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.15),
                        offset: Offset(0, 2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    Resources.assetsImagesChatPinSvg,
                    width: 34,
                    height: 34,
                    colorFilter: ColorFilter.mode(
                      context.theme.text,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JumpMentionButton extends HookConsumerWidget {
  const _JumpMentionButton();

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
                      // Use column + spacer to vertical center the text.
                      // since the width is not fixed, we can't use center widget.
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
