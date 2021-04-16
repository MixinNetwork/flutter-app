import 'package:flutter/material.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/chat_page.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator_cubit.dart';
import 'package:flutter_app/utils/hook.dart';
import 'package:flutter_app/widgets/action_button.dart';
import 'package:flutter_app/widgets/back_button.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'avatar_view/avatar_view.dart';

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

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 14, bottom: 14),
      child: Row(children: [
        Builder(
          builder: (context) => navigationMode
              ? MixinBackButton(
                  color: actionColor,
                  onTap: () => context.read<ConversationCubit>().unselected(),
                )
              : const SizedBox(width: 16),
        ),
        Expanded(
          flex: 1,
          child: Row(
            children: [
              const ConversationAvatar(),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ConversationName(),
                  const ConversationIDOrCount(),
                ],
              ),
            ],
          ),
        ),
        ActionButton(
          name: Resources.assetsImagesIcSearchSvg,
          color: actionColor,
          onTap: () => context
              .read<ChatSideCubit>()
              .pushPage(ChatSideCubit.searchMessageHistory),
        ),
        const SizedBox(width: 14),
        ActionButton(
          name: Resources.assetsImagesIcScreenSvg,
          color: hasSidePage
              ? BrightnessData.themeOf(context).accent
              : actionColor,
          onTap: chatSideCubit.toggleInfoPage,
        ),
      ]),
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

    final countStream = useMemoized(
      () => context
          .read<AccountServer>()
          .database
          .conversationDao
          .conversationParticipantsCount(conversation!.conversationId)
          .watchSingle(),
      [conversation?.conversationId],
    );

    final textStyle = TextStyle(
      color: BrightnessData.themeOf(context).secondaryText,
      fontSize: fontSize,
    );

    final isGroup = conversation?.isGroup ?? false;

    if (!isGroup)
      return Text(
        conversation?.identityNumber ?? '',
        style: textStyle,
      );

    return StreamBuilder<int>(
      stream: countStream,
      builder: (context, snapshot) => Text(
        Localization.of(context)
            .conversationParticipantsCount(snapshot.data ?? 0),
        style: textStyle,
      ),
    );
  }
}

class ConversationName extends StatelessWidget {
  const ConversationName({
    Key? key,
    this.fontSize = 20,
  }) : super(key: key);

  final double fontSize;

  @override
  Widget build(BuildContext context) =>
      BlocConverter<ConversationCubit, ConversationState?, String?>(
        converter: (state) => state?.name,
        when: (a, b) => b != null,
        builder: (context, name) => Text(
          name ?? '',
          style: TextStyle(
            color: BrightnessData.themeOf(context).text,
            fontSize: fontSize,
          ),
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
            if (state?.conversation != null)
              return ConversationAvatarWidget(
                size: size,
                conversation: state!.conversation!,
              );

            if (state?.user != null)
              return AvatarWidget(
                size: size,
                userId: state!.userId!,
                avatarUrl: state.user!.avatarUrl,
                name: state.name!,
              );

            return const SizedBox();
          },
        ),
      );
}
