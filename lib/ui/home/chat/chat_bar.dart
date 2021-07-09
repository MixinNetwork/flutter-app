import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../account/account_server.dart';
import '../../../constants/resources.dart';
import '../../../generated/l10n.dart';
import '../../../utils/hook.dart';
import '../../../utils/string_extension.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/brightness_observer.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/interacter_decorated_box.dart';
import '../../../widgets/window/move_window.dart';
import '../bloc/conversation_cubit.dart';
import '../chat_page.dart';
import '../conversation_page.dart';
import '../route/responsive_navigator_cubit.dart';

class ChatBar extends HookWidget {
  const ChatBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final actionColor = BrightnessData.themeOf(context).icon;
    final chatSideCubit = context.read<ChatSideCubit>();

    final navigationMode = useBlocStateConverter<ResponsiveNavigatorCubit,
        ResponsiveNavigatorState, bool>(
      converter: (state) => state.navigationMode,
    );

    final conversation = useBlocState<ConversationCubit, ConversationState?>(
      when: (state) => state?.isLoaded == true,
    )!;

    MoveWindowBarrier toggleInfoPageWrapper({
      required Widget child,
      behavior = HitTestBehavior.opaque,
    }) =>
        MoveWindowBarrier(
          child: InteractableDecoratedBox(
            onTap: chatSideCubit.toggleInfoPage,
            child: child,
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 14, bottom: 14),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Builder(
            builder: (context) => navigationMode
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
              mainAxisSize: MainAxisSize.max,
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
          MoveWindowBarrier(
            child: ActionButton(
              name: Resources.assetsImagesIcSearchSvg,
              color: actionColor,
              onTap: () {
                final cubit = context.read<ChatSideCubit>();
                if (cubit.state.pages.isNotEmpty &&
                    cubit.state.pages.last.name ==
                        ChatSideCubit.searchMessageHistory) {
                  return;
                }
                cubit
                  ..popWhere(
                      (page) => page.name == ChatSideCubit.searchMessageHistory)
                  ..pushPage(ChatSideCubit.searchMessageHistory);
              },
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
          return context
              .read<AccountServer>()
              .database
              .participantDao
              .conversationParticipantsCount(conversationState!.conversationId)
              .watchSingle();
        }

        return const Stream<int>.empty();
      },
      [
        conversationState?.conversationId,
        isGroup,
      ],
    );

    final textStyle = TextStyle(
      color: BrightnessData.themeOf(context).secondaryText,
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
              ? Localization.of(context).conversationParticipantsCount(count)
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
  }) : super(key: key);

  final double fontSize;
  final ConversationState conversationState;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SelectableText(
              conversationState.name?.overflow ?? '',
              style: TextStyle(
                color: BrightnessData.themeOf(context).text,
                fontSize: fontSize,
                height: 1,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
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
