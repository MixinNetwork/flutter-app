import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../blaze/vo/pin_message_minimal.dart';
import '../../../bloc/bloc_converter.dart';
import '../../../bloc/minute_timer_cubit.dart';
import '../../../bloc/paging/paging_bloc.dart';
import '../../../constants/resources.dart';
import '../../../db/mixin_database.dart';
import '../../../enum/message_category.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/message_optimize.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/conversation/verified_or_bot_widget.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/message/item/pin_message.dart';
import '../../../widgets/message/item/system_message.dart';
import '../../../widgets/message/item/text/mention_builder.dart';
import '../../../widgets/message_status_icon.dart';
import '../../../widgets/unread_text.dart';
import '../bloc/conversation_cubit.dart';
import '../bloc/conversation_list_bloc.dart';
import '../bloc/slide_category_cubit.dart';
import '../route/responsive_navigator_cubit.dart';
import 'conversation_page.dart';
import 'menu_wrapper.dart';
import 'network_status.dart';

class ConversationList extends HookWidget {
  const ConversationList({
    required Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final slideCategoryState =
        (key! as PageStorageKey<SlideCategoryState>).value;

    final conversationListBloc = context.read<ConversationListBloc>();
    final pagingState =
        useBlocState<ConversationListBloc, PagingState<ConversationItem>>(
      bloc: conversationListBloc,
    );
    final conversationId =
        useBlocStateConverter<ConversationCubit, ConversationState?, String?>(
      converter: (state) => state?.conversationId,
    );

    final routeMode = useBlocStateConverter<ResponsiveNavigatorCubit,
        ResponsiveNavigatorState, bool>(
      converter: (state) => state.routeMode,
    );

    Widget child;
    child = pagingState.count == 0
        ? pagingState.hasData
            ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(context.theme.accent),
                ),
              )
            : const _Empty()
        : ScrollablePositionedList.builder(
            key: PageStorageKey(slideCategoryState),
            itemPositionsListener:
                conversationListBloc.itemPositionsListener(slideCategoryState),
            itemCount: pagingState.count,
            itemScrollController:
                conversationListBloc.itemScrollController(slideCategoryState),
            itemBuilder: (context, index) {
              final conversation = pagingState.map[index];
              if (conversation == null) return const SizedBox(height: 80);
              final selected =
                  conversation.conversationId == conversationId && !routeMode;
              return ConversationMenuWrapper(
                conversation: conversation,
                removeChatFromCircle: true,
                child: _Item(
                  selected: selected,
                  conversation: conversation,
                  onTap: () {
                    ConversationCubit.selectConversation(
                        context, conversation.conversationId,
                        conversation: conversation);
                  },
                ),
              );
            },
          );

    return Column(
      children: [
        const NetworkStatus(),
        Expanded(
          child: child,
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dynamicColor = context.dynamicColor(
      const Color.fromRGBO(229, 233, 240, 1),
    );
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SvgPicture.asset(
          Resources.assetsImagesEmptyFileSvg,
          height: 78,
          width: 58,
          color: dynamicColor,
        ),
        const SizedBox(height: 24),
        Text(
          context.l10n.noData,
          style: TextStyle(
            color: dynamicColor,
            fontSize: 14,
          ),
        ),
      ]),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    Key? key,
    this.selected = false,
    required this.conversation,
    required this.onTap,
  }) : super(key: key);

  final bool selected;
  final ConversationItem conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final messageColor = context.theme.secondaryText;
    return SizedBox(
      height: ConversationPage.conversationItemHeight,
      child: InteractiveDecoratedBox(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DecoratedBox(
            decoration: selected
                ? BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    color: context.theme.listSelected,
                  )
                : const BoxDecoration(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  ConversationAvatarWidget(
                    conversation: conversation,
                    size: ConversationPage.conversationItemAvatarSize,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        conversation.validName,
                                        style: TextStyle(
                                          color: context.theme.text,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    VerifiedOrBotWidget(
                                      verified: conversation.ownerVerified,
                                      isBot: conversation.isBotConversation,
                                    ),
                                  ],
                                ),
                              ),
                              BlocConverter<MinuteTimerCubit, DateTime, String>(
                                converter: (_) =>
                                    (conversation.lastMessageCreatedAt ??
                                            conversation.createdAt)
                                        .format,
                                builder: (context, text) => Text(
                                  text,
                                  style: TextStyle(
                                    color: messageColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          _ItemConversationSubtitle(conversation: conversation),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemConversationSubtitle extends StatelessWidget {
  const _ItemConversationSubtitle({
    Key? key,
    required this.conversation,
  }) : super(key: key);

  final ConversationItem conversation;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 20,
        child: Row(
          children: [
            Expanded(
              child: _MessagePreview(
                messageColor: context.theme.secondaryText,
                conversation: conversation,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (conversation.mentionCount > 0)
                  UnreadText(
                    data: '@',
                    textColor: const Color.fromRGBO(255, 255, 255, 1),
                    backgroundColor: context.theme.accent,
                  ),
                if ((conversation.unseenMessageCount ?? 0) > 0)
                  UnreadText(
                    data: '${conversation.unseenMessageCount}',
                    textColor: const Color.fromRGBO(255, 255, 255, 1),
                    backgroundColor: conversation.isMute
                        ? context.theme.secondaryText
                        : context.theme.accent,
                  ),
                if ((conversation.unseenMessageCount ?? 0) <= 0)
                  _StatusRow(conversation: conversation),
              ].joinList(const SizedBox(width: 8)),
            ),
          ],
        ),
      );
}

class _MessagePreview extends StatelessWidget {
  const _MessagePreview({
    Key? key,
    required this.messageColor,
    required this.conversation,
  }) : super(key: key);

  final Color messageColor;
  final ConversationItem conversation;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MessageStatusIcon(conversation: conversation),
          const SizedBox(width: 2),
          Expanded(
            child: _MessageContent(conversation: conversation),
          ),
        ],
      );
}

class _MessageContent extends HookWidget {
  const _MessageContent({
    Key? key,
    required this.conversation,
  }) : super(key: key);
  final ConversationItem conversation;

  @override
  Widget build(BuildContext context) {
    final text = useMemoizedFuture(
      () async {
        final isGroup = conversation.category == ConversationCategory.group ||
            conversation.senderId != conversation.ownerId;
        if (conversation.contentType == MessageCategory.systemConversation) {
          return generateSystemText(
            actionName: conversation.actionName,
            participantUserId: conversation.participantUserId,
            senderId: conversation.senderId,
            currentUserId: context.accountServer.userId,
            participantFullName: conversation.participantFullName,
            senderFullName: conversation.senderFullName,
            groupName: conversation.groupName,
            expireIn: int.tryParse(conversation.content ?? '0'),
          );
        } else if (conversation.contentType.isPin) {
          final pinMessageMinimal =
              PinMessageMinimal.fromJsonString(conversation.content ?? '');
          if (pinMessageMinimal == null) {
            return context.l10n.pinned(
                conversation.senderFullName ?? '', context.l10n.aMessage);
          }
          final preview = await generatePinPreviewText(
            pinMessageMinimal: pinMessageMinimal,
            mentionCache: context.read<MentionCache>(),
          );
          return context.l10n
              .pinned(conversation.senderFullName ?? '', preview);
        }

        final mentionCache = context.read<MentionCache>();

        return messagePreviewOptimize(
          conversation.messageStatus,
          conversation.contentType,
          mentionCache.replaceMention(
            conversation.content,
            await mentionCache.checkMentionCache({conversation.content}),
          ),
          conversation.senderId == context.accountServer.userId,
          isGroup,
          conversation.senderFullName,
        );
      },
      null,
      keys: [
        conversation.actionName,
        conversation.messageStatus,
        conversation.contentType,
        conversation.content,
        conversation.senderId,
        conversation.ownerId,
        conversation.relationship,
        conversation.participantFullName,
        conversation.senderFullName,
        conversation.groupName,
      ],
    ).data;

    final icon = useMemoized(
        () => messagePreviewIcon(
              conversation.messageStatus,
              conversation.contentType,
            ),
        [
          conversation.messageStatus,
          conversation.contentType,
        ]);

    if (conversation.contentType == null) return const SizedBox();

    final dynamicColor = context.theme.secondaryText;

    return Row(
      children: [
        if (icon != null)
          SvgPicture.asset(
            icon,
            color: dynamicColor,
          ),
        if (text != null)
          Expanded(
            child: Text(
              text.overflow,
              style: TextStyle(
                color: dynamicColor,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
      ].joinList(const SizedBox(width: 4)),
    );
  }
}

class _MessageStatusIcon extends StatelessWidget {
  const _MessageStatusIcon({
    Key? key,
    required this.conversation,
  }) : super(key: key);

  final ConversationItem conversation;

  @override
  Widget build(BuildContext context) {
    if (context.multiAuthState.currentUserId == conversation.senderId &&
        conversation.contentType != MessageCategory.systemConversation &&
        conversation.contentType != MessageCategory.systemAccountSnapshot &&
        !conversation.contentType.isCallMessage &&
        !conversation.contentType.isRecall &&
        !conversation.contentType.isGroupCall &&
        !conversation.contentType.isPin) {
      return MessageStatusIcon(
        status: conversation.messageStatus,
      );
    }
    return const SizedBox();
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    Key? key,
    required this.conversation,
  }) : super(key: key);
  final ConversationItem conversation;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (conversation.isMute)
            SvgPicture.asset(
              Resources.assetsImagesMuteSvg,
              color: context.theme.secondaryText,
            ),
          if (conversation.pinTime != null)
            SvgPicture.asset(
              Resources.assetsImagesPinSvg,
              color: context.theme.secondaryText,
            ),
        ].joinList(const SizedBox(width: 4)),
      );
}
