import 'package:flutter/material.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/chat_page.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator_cubit.dart';
import 'package:flutter_app/utils/hook.dart';
import 'package:flutter_app/widgets/action_button.dart';
import 'package:flutter_app/widgets/back_button.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_app/db/extension/conversation.dart';
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
                  onTap: () {
                    BlocProvider.of<ConversationCubit>(context).emit(null);
                    context.read<ResponsiveNavigatorCubit>().clear();
                  },
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
    final conversation = useBlocState<ConversationCubit, ConversationItem?>(
        when: (state) => state != null)!;
    final isGroupConversation = conversation.isGroupConversation;

    final countStream = useMemoized(
      () => context
          .read<AccountServer>()
          .database
          .conversationDao
          .conversationParticipantsCount(conversation.conversationId)
          .watchSingle(),
      [conversation.conversationId],
    );

    final textStyle = TextStyle(
      color: BrightnessData.themeOf(context).secondaryText,
      fontSize: fontSize,
    );

    if (!isGroupConversation)
      return Text(
        Localization.of(context)
            .conversationID(conversation.ownerIdentityNumber),
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
      BlocConverter<ConversationCubit, ConversationItem?, String?>(
        converter: (state) => state?.groupName?.trim().isNotEmpty == true
            ? state?.groupName
            : state?.name,
        when: (a, b) => b != null,
        builder: (context, name) => Text(
          name!,
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
    this.size = 50,
  }) : super(key: key);

  final double size;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ConversationCubit, ConversationItem?>(
        buildWhen: (a, b) => b != null,
        builder: (context, conversation) => ConversationAvatarWidget(
          size: size,
          conversation: conversation!,
        ),
      );
}
