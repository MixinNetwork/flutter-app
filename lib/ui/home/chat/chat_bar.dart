import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/resources.dart';
import '../../../db/database_event_bus.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/logger.dart';
import '../../../utils/web_view/web_view_interface.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/conversation/verified_or_bot_widget.dart';
import '../../../widgets/high_light_text.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/window/move_window.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/message_selection_provider.dart';
import '../../provider/navigation/abstract_responsive_navigator.dart';
import '../../provider/navigation/responsive_navigator_provider.dart';
import 'chat_page.dart';

class ChatBar extends HookConsumerWidget {
  const ChatBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionColor = context.theme.icon;
    final chatSideCubit = context.read<ChatSideCubit>();

    final chatSideRouteMode =
        useBlocStateConverter<ChatSideCubit, ResponsiveNavigatorState, bool>(
      bloc: chatSideCubit,
      converter: (state) => state.routeMode,
    );

    final routeMode = ref.watch(navigatorRouteModeProvider);

    final conversation = ref.watch(conversationProvider);

    final inMultiSelectMode = ref.watch(hasSelectedMessageProvider);

    MoveWindowBarrier toggleInfoPageWrapper({
      required Widget child,
      HitTestBehavior behavior = HitTestBehavior.opaque,
      bool longPressToShareLog = false,
    }) =>
        MoveWindowBarrier(
          child: InteractiveDecoratedBox(
            onTap: () {
              if (inMultiSelectMode) {
                return;
              }
              chatSideCubit.toggleInfoPage();
            },
            onLongPress: longPressToShareLog
                ? (details) {
                    if (conversation == null) return;

                    if ((conversation.isGroup ?? true) ||
                        (conversation.isBot ?? true)) {
                      return;
                    }
                    showShareLogDialog(context,
                        conversationName: conversation.name ?? '');
                  }
                : null,
            behavior: behavior,
            child: child,
          ),
        );

    if (conversation == null) return const SizedBox();

    return Row(
      children: [
        Consumer(
          builder: (_, ref, __) => routeMode
              ? MoveWindowBarrier(
                  child: MixinBackButton(
                    color: actionColor,
                    onTap: () =>
                        ref.read(conversationProvider.notifier).unselected(),
                  ),
                )
              : const SizedBox(width: 16),
        ),
        toggleInfoPageWrapper(
          longPressToShareLog: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConversationAvatar(
                conversationState: conversation,
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IgnorePointer(
                child: ConversationName(
                  conversationState: conversation,
                ),
              ),
              const SizedBox(height: 4),
              IgnorePointer(
                child: ConversationIDOrCount(
                  conversationState: conversation,
                ),
              ),
            ]
                .map((e) => toggleInfoPageWrapper(
                      child: e,
                      behavior: HitTestBehavior.deferToChild,
                    ))
                .toList(),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.centerLeft,
          child: MoveWindowBarrier(
            child: _BotIcon(conversation: conversation),
          ),
        ),
        if (inMultiSelectMode)
          MoveWindowBarrier(
            child: TextButton(
              onPressed: () =>
                  ref.read(messageSelectionProvider).clearSelection(),
              child: Text(context.l10n.cancel),
            ),
          )
        else ...[
          MoveWindowBarrier(
            child: ActionButton(
              name: Resources.assetsImagesIcSearchSvg,
              color: actionColor,
              onTap: () {
                final cubit = context.read<ChatSideCubit>();
                if (cubit.state.pages.lastOrNull?.name ==
                    ChatSideCubit.searchMessageHistory) {
                  return cubit.pop();
                }
                cubit.replace(ChatSideCubit.searchMessageHistory);
              },
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.centerLeft,
            child: MoveWindowBarrier(
              child: chatSideRouteMode
                  ? const SizedBox()
                  : ActionButton(
                      name: Resources.assetsImagesIcScreenSvg,
                      color: actionColor,
                      onTap: chatSideCubit.toggleInfoPage,
                    ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ],
    );
  }
}

class ConversationIDOrCount extends HookConsumerWidget {
  const ConversationIDOrCount({
    required this.conversationState,
    super.key,
    this.fontSize = 14,
  });

  final double fontSize;
  final ConversationState? conversationState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGroup = conversationState?.isGroup ?? false;

    final countStream = useMemoized(
      () {
        if (isGroup) {
          return context.database.participantDao
              .conversationParticipantsCount(conversationState!.conversationId)
              .watchSingleWithStream(
            eventStreams: [
              DataBaseEventBus.instance.watchUpdateParticipantStream(
                  conversationIds: [conversationState!.conversationId])
            ],
            duration: kVerySlowThrottleDuration,
          );
        }

        return const Stream<int>.empty();
      },
      [
        conversationState?.conversationId,
        isGroup,
      ],
    );

    final textStyle = TextStyle(
      color: context.theme.secondaryText,
      fontSize: fontSize,
      height: 1,
    );

    if (!isGroup) {
      return SelectableText(
        conversationState?.identityNumber ?? '',
        style: textStyle,
      );
    }

    return StreamBuilder<int>(
      stream: countStream,
      builder: (context, snapshot) {
        final count = snapshot.data;
        return SelectableText(
          count != null ? context.l10n.participantsCount(count) : '',
          style: textStyle,
        );
      },
    );
  }
}

class ConversationName extends StatelessWidget {
  const ConversationName({
    required this.conversationState,
    super.key,
    this.fontSize = 16,
    this.overflow = true,
  });

  final double fontSize;
  final ConversationState conversationState;
  final bool overflow;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SelectionArea(
              child: CustomText(
                (overflow
                        ? conversationState.name?.overflow
                        : conversationState.name) ??
                    '',
                style: TextStyle(
                  color: context.theme.text,
                  fontSize: fontSize,
                  height: 1,
                  overflow: overflow ? TextOverflow.ellipsis : null,
                ),
                textAlign: TextAlign.center,
                maxLines: overflow ? 1 : null,
              ),
            ),
          ),
          VerifiedOrBotWidget(
            verified: conversationState.isVerified,
            isBot: conversationState.isBot ?? false,
          ),
        ],
      );
}

class ConversationAvatar extends StatelessWidget {
  const ConversationAvatar({
    required this.conversationState,
    super.key,
    this.size = 36,
  });

  final double size;
  final ConversationState? conversationState;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
        size: Size.square(size),
        child: Builder(
          builder: (context) {
            if (conversationState?.user != null) {
              return AvatarWidget(
                size: size,
                userId: conversationState?.user?.userId,
                avatarUrl: conversationState?.user?.avatarUrl,
                name: conversationState?.name,
              );
            }

            if (conversationState?.conversation != null) {
              return ConversationAvatarWidget(
                size: size,
                conversation: conversationState!.conversation,
              );
            }

            return const SizedBox();
          },
        ),
      );
}

class _BotIcon extends HookConsumerWidget {
  const _BotIcon({required this.conversation});

  final ConversationState conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (conversation.isBot != true) {
      return const SizedBox();
    }

    return ActionButton(
      name: Resources.assetsImagesBotSvg,
      color: context.theme.icon,
      onTap: () {
        MixinWebView.instance.openBotWebViewWindow(
          context,
          conversation.app!,
          conversationId: conversation.conversationId,
        );
      },
    );
  }
}
