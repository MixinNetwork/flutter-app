import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/resources.dart';
import '../../../db/database_event_bus.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/logger.dart';
import '../../../utils/web_view/web_view_interface.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/conversation/badges_widget.dart';
import '../../../widgets/high_light_text.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/window/move_window.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/database_provider.dart';
import '../../provider/message_selection_provider.dart';
import '../../provider/responsive_navigator_provider.dart';
import '../../provider/ui_context_providers.dart';
import '../providers/home_scope_providers.dart';
import 'chat_page.dart';

class ChatBar extends HookConsumerWidget {
  const ChatBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final l10n = ref.watch(localizationProvider);
    final actionColor = theme.icon;
    final chatSideCubit = ref.read(chatSideControllerProvider.notifier);
    final chatSideRouteMode = ref.watch(
      chatSideControllerProvider.select((state) => state.routeMode),
    );

    final routeMode = ref.watch(navigatorRouteModeProvider);

    final conversation = ref.watch(conversationProvider);

    final inMultiSelectMode = ref.watch(hasSelectedMessageProvider);

    MoveWindowBarrier toggleInfoPageWrapper({
      required Widget child,
      HitTestBehavior behavior = HitTestBehavior.opaque,
      bool longPressToShareLog = false,
    }) => MoveWindowBarrier(
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

                if ((conversation.isGroup ?? true) || (conversation.isBot)) {
                  return;
                }
                showShareLogDialog(
                  context,
                  conversationName: conversation.name ?? '',
                );
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
          builder: (_, ref, _) => routeMode
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
              ConversationAvatar(conversationState: conversation),
              const SizedBox(width: 10),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                [
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
                    .map(
                      (e) => toggleInfoPageWrapper(
                        child: e,
                        behavior: HitTestBehavior.deferToChild,
                      ),
                    )
                    .toList(),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.centerLeft,
          child: MoveWindowBarrier(child: _BotIcon(conversation: conversation)),
        ),
        if (inMultiSelectMode)
          MoveWindowBarrier(
            child: TextButton(
              onPressed: () =>
                  ref.read(messageSelectionProvider.notifier).clearSelection(),
              child: Text(l10n.cancel),
            ),
          )
        else ...[
          MoveWindowBarrier(
            child: ActionButton(
              name: Resources.assetsImagesIcSearchSvg,
              color: actionColor,
              onTap: () {
                final cubit = ref.read(chatSideControllerProvider.notifier);
                if (cubit.state.pages.lastOrNull?.name ==
                    ChatSideController.searchMessageHistory) {
                  return cubit.pop();
                }
                cubit.replace(ChatSideController.searchMessageHistory);
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
    final theme = ref.watch(brightnessThemeDataProvider);
    final l10n = ref.watch(localizationProvider);
    final isGroup = conversationState?.isGroup ?? false;
    final database = ref.read(databaseProvider).requireValue;

    final countStream = useMemoized(() {
      if (isGroup) {
        return database.participantDao
            .conversationParticipantsCount(conversationState!.conversationId)
            .watchSingleWithStream(
              eventStreams: [
                DataBaseEventBus.instance.watchUpdateParticipantStream(
                  conversationIds: [conversationState!.conversationId],
                ),
              ],
              duration: kVerySlowThrottleDuration,
            );
      }

      return const Stream<int>.empty();
    }, [conversationState?.conversationId, isGroup, database]);

    final textStyle = TextStyle(
      color: theme.secondaryText,
      fontSize: fontSize,
      height: 1,
    );

    if (!isGroup) {
      return CustomSelectableText(
        conversationState?.identityNumber ?? '',
        style: textStyle,
      );
    }

    return StreamBuilder<int>(
      stream: countStream,
      builder: (context, snapshot) {
        final count = snapshot.data;
        return CustomSelectableText(
          count != null ? l10n.participantsCount(count) : '',
          style: textStyle,
        );
      },
    );
  }
}

class ConversationName extends ConsumerWidget {
  const ConversationName({
    required this.conversationState,
    super.key,
    this.fontSize = 16,
  });

  final double fontSize;
  final ConversationState conversationState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: CustomSelectableArea(
            child: CustomText(
              conversationState.name?.overflow ?? '',
              style: TextStyle(
                color: theme.text,
                fontSize: fontSize,
                height: 1,
                overflow: TextOverflow.ellipsis,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ),
        BadgesWidget(
          verified: conversationState.isVerified,
          isBot: conversationState.isBot,
          membership: conversationState.membership,
        ),
      ],
    );
  }
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
    final theme = ref.watch(brightnessThemeDataProvider);
    if (!conversation.isBot) {
      return const SizedBox();
    }

    return ActionButton(
      name: Resources.assetsImagesBotSvg,
      color: theme.icon,
      onTap: () {
        MixinWebView.instance.openBotWebViewWindow(
          context,
          ref.container,
          conversation.app!,
          conversationId: conversation.conversationId,
        );
      },
    );
  }
}
