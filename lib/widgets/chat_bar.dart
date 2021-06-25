import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../account/account_server.dart';
import '../constants/resources.dart';
import '../generated/l10n.dart';
import '../ui/home/bloc/conversation_cubit.dart';
import '../ui/home/chat_page.dart';
import '../ui/home/conversation_page.dart';
import '../ui/home/route/responsive_navigator_cubit.dart';
import '../utils/file.dart';
import '../utils/hook.dart';
import 'action_button.dart';
import 'avatar_view/avatar_view.dart';
import 'brightness_observer.dart';
import 'buttons.dart';
import 'input_container.dart';
import 'window/move_window.dart';

class ChatBar extends HookWidget {
  const ChatBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final actionColor = BrightnessData.themeOf(context).icon;
    final chatSideCubit = context.read<ChatSideCubit>();

    final hasSidePage =
        useBlocStateConverter<ChatSideCubit, ResponsiveNavigatorState, bool>(
      bloc: chatSideCubit,
      converter: (state) => state.pages.isNotEmpty,
    );

    final navigationMode = useBlocStateConverter<ResponsiveNavigatorCubit,
        ResponsiveNavigatorState, bool>(
      converter: (state) => state.navigationMode,
    );

    return MoveWindow(
      behavior: HitTestBehavior.opaque,
      child: Padding(
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
            const ConversationAvatar(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ConversationName(),
                  SizedBox(height: 4),
                  MoveWindowBarrier(
                    child: ConversationIDOrCount(),
                  ),
                ],
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
                    ..popWhere((page) =>
                        page.name == ChatSideCubit.searchMessageHistory)
                    ..pushPage(ChatSideCubit.searchMessageHistory);
                },
              ),
            ),
            const SizedBox(width: 14),
            MoveWindowBarrier(
              child: _FileButton(actionColor: actionColor),
            ),
            const SizedBox(width: 14),
            MoveWindowBarrier(
              child: ActionButton(
                name: Resources.assetsImagesIcScreenSvg,
                color: hasSidePage
                    ? BrightnessData.themeOf(context).accent
                    : actionColor,
                onTap: chatSideCubit.toggleInfoPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConversationIDOrCount extends HookWidget {
  const ConversationIDOrCount({
    Key? key,
    this.fontSize = 14,
  }) : super(key: key);

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final conversation = useBlocState<ConversationCubit, ConversationState?>(
        when: (state) => state?.isLoaded ?? false);

    final isGroup = conversation?.isGroup ?? false;

    final countStream = useMemoized(
      () {
        if (isGroup) {
          return context
              .read<AccountServer>()
              .database
              .conversationDao
              .conversationParticipantsCount(conversation!.conversationId)
              .watchSingle();
        }

        return const Stream<int>.empty();
      },
      [
        conversation?.conversationId,
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
        conversation?.identityNumber ?? '',
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
  }) : super(key: key);

  final double fontSize;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ConversationCubit, ConversationState?>(
        buildWhen: (previous, current) =>
            current != null && current != previous,
        builder: (context, conversation) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SelectableText(
                conversation?.name ?? '',
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
              verified: conversation?.isVerified ?? false,
              isBot: conversation?.isBot ?? false,
            ),
          ],
        ),
      );
}

class ConversationAvatar extends StatelessWidget {
  const ConversationAvatar({
    Key? key,
    this.size = 36,
  }) : super(key: key);

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
        size: Size.square(size),
        child: BlocBuilder<ConversationCubit, ConversationState?>(
          buildWhen: (a, b) => b?.isLoaded ?? false,
          builder: (context, state) {
            if (state?.conversation != null) {
              return ConversationAvatarWidget(
                size: size,
                conversation: state!.conversation,
              );
            }

            if (state?.user != null) {
              return AvatarWidget(
                size: size,
                userId: state!.user!.userId,
                avatarUrl: state.user!.avatarUrl,
                name: state.name!,
              );
            }

            return const SizedBox();
          },
        ),
      );
}

class _FileButton extends StatelessWidget {
  const _FileButton({
    Key? key,
    required this.actionColor,
  }) : super(key: key);

  final Color actionColor;

  @override
  Widget build(BuildContext context) => ActionButton(
        name: Resources.assetsImagesIcFileSvg,
        color: actionColor,
        onTap: () async {
          final file = await selectFile();
          if (file == null) return;

          await sendFile(context, file);
        },
      );
}
