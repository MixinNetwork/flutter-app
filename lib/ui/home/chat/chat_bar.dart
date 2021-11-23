import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../constants/resources.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/webview.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/window/move_window.dart';
import '../bloc/conversation_cubit.dart';
import '../conversation_page.dart';
import '../route/responsive_navigator_cubit.dart';
import 'chat_page.dart';

class ChatBar extends HookWidget {
  const ChatBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final actionColor = context.theme.icon;
    final chatSideCubit = context.read<ChatSideCubit>();

    final chatSideRouteMode =
        useBlocStateConverter<ChatSideCubit, ResponsiveNavigatorState, bool>(
      bloc: chatSideCubit,
      converter: (state) => state.routeMode,
    );

    final routeMode = useBlocStateConverter<ResponsiveNavigatorCubit,
        ResponsiveNavigatorState, bool>(
      converter: (state) => state.routeMode,
    );

    final conversation = useBlocState<ConversationCubit, ConversationState?>(
      when: (state) => state?.isLoaded == true,
    )!;

    MoveWindowBarrier toggleInfoPageWrapper({
      required Widget child,
      behavior = HitTestBehavior.opaque,
    }) =>
        MoveWindowBarrier(
          child: InteractiveDecoratedBox(
            onTap: chatSideCubit.toggleInfoPage,
            child: child,
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 14, bottom: 14),
      child: Row(
        children: [
          Builder(
            builder: (context) => routeMode
                ? MoveWindowBarrier(
                    child: MixinBackButton(
                      color: actionColor,
                      onTap: () =>
                          context.read<ConversationCubit>().unselected(),
                    ),
                  )
                : const SizedBox(width: 16),
          ),
          toggleInfoPageWrapper(
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
        ],
      ),
    );
  }
}

class ConversationIDOrCount extends HookWidget {
  const ConversationIDOrCount({
    Key? key,
    this.fontSize = 14,
    required this.conversationState,
  }) : super(key: key);

  final double fontSize;
  final ConversationState? conversationState;

  @override
  Widget build(BuildContext context) {
    final isGroup = conversationState?.isGroup ?? false;

    final countStream = useMemoized(
      () {
        if (isGroup) {
          return context.database.participantDao
              .conversationParticipantsCount(conversationState!.conversationId)
              .watchSingleThrottle();
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
          count != null
              ? context.l10n.conversationParticipantsCount(count)
              : '',
          style: textStyle,
        );
      },
    );
  }
}

class ConversationName extends StatelessWidget {
  const ConversationName({
    Key? key,
    this.fontSize = 16,
    required this.conversationState,
    this.overflow = true,
  }) : super(key: key);

  final double fontSize;
  final ConversationState conversationState;
  final bool overflow;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SelectableText(
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
          VerifiedOrBotWidget(
            verified: conversationState.isVerified,
            isBot: conversationState.isBot ?? false,
          ),
        ],
      );
}

class ConversationAvatar extends StatelessWidget {
  const ConversationAvatar({
    Key? key,
    this.size = 36,
    required this.conversationState,
  }) : super(key: key);

  final double size;
  final ConversationState? conversationState;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
        size: Size.square(size),
        child: Builder(
          builder: (context) {
            if (conversationState?.conversation != null) {
              return ConversationAvatarWidget(
                size: size,
                conversation: conversationState!.conversation,
              );
            }

            if (conversationState?.user != null) {
              return AvatarWidget(
                size: size,
                userId: conversationState!.user!.userId,
                avatarUrl: conversationState!.user!.avatarUrl,
                name: conversationState!.name!,
              );
            }

            return const SizedBox();
          },
        ),
      );
}

class _BotIcon extends HookWidget {
  const _BotIcon({Key? key, required this.conversation}) : super(key: key);

  final ConversationState conversation;

  @override
  Widget build(BuildContext context) {
    if (conversation.isBot != true) {
      return const SizedBox();
    }

    final child = ActionButton(
      name: Resources.assetsImagesBotSvg,
      color: context.theme.icon,
      onTap: () {
        if (!kIsSupportWebView) {
          return;
        }
        openBotWebViewWindow(
          context,
          conversation.app!,
          conversationId: conversation.conversationId,
        );
      },
    );

    if (kIsSupportWebView) {
      return child;
    }
    return Tooltip(message: context.l10n.comingSoon, child: child);
  }
}
