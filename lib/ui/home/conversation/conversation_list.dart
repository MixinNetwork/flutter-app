import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide Key, User;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../blaze/vo/pin_message_minimal.dart';
import '../../../constants/resources.dart';
import '../../../db/dao/conversation_dao.dart';
import '../../../enum/message_category.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/message_optimize.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/conversation/badges_widget.dart';
import '../../../widgets/high_light_text.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/message/item/pin_message.dart';
import '../../../widgets/message/item/system_message.dart';
import '../../../widgets/message_status_icon.dart';
import '../../../widgets/unread_text.dart';
import '../../provider/account_server_provider.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/mention_cache_provider.dart';
import '../../provider/minute_timer_provider.dart';
import '../../provider/multi_auth_provider.dart';
import '../../provider/responsive_navigator_provider.dart';
import '../../provider/slide_category_provider.dart';
import '../../provider/ui_context_providers.dart';
import '../providers/home_scope_providers.dart';
import 'audio_player_bar.dart';
import 'conversation_page.dart';
import 'menu_wrapper.dart';
import 'network_status.dart';

final _conversationPreviewTextProvider = FutureProvider.autoDispose
    .family<String?, ConversationItem>((ref, conversation) async {
      final hasDraft =
          conversation.status != ConversationStatus.quit &&
          (conversation.draft?.isNotEmpty ?? false);
      if (hasDraft) return conversation.draft;

      final isGroup =
          conversation.category == ConversationCategory.group ||
          conversation.senderId != conversation.ownerId;

      final mentionCache = ref.read(mentionCacheProvider);

      if (conversation.contentType == MessageCategory.systemConversation) {
        return generateSystemText(
          actionName: conversation.actionName,
          participantUserId: conversation.participantUserId,
          senderId: conversation.senderId,
          currentUserId: ref.read(accountServerProvider).value?.userId ?? '',
          participantFullName: conversation.participantFullName,
          senderFullName: conversation.senderFullName,
          expireIn: int.tryParse(conversation.content ?? '0'),
        );
      }
      if (conversation.contentType.isPin) {
        final pinMessageMinimal = PinMessageMinimal.fromJsonString(
          conversation.content ?? '',
        );
        final localization = ref.read(localizationProvider);
        if (pinMessageMinimal == null) {
          return localization.chatPinMessage(
            conversation.senderFullName ?? '',
            localization.aMessage,
          );
        }
        final preview = await generatePinPreviewText(
          pinMessageMinimal: pinMessageMinimal,
          mentionCache: mentionCache,
        );
        return localization.chatPinMessage(
          conversation.senderFullName ?? '',
          preview,
        );
      }

      return messagePreviewOptimize(
        conversation.messageStatus,
        conversation.contentType,
        mentionCache.replaceMention(
          conversation.content,
          await mentionCache.checkMentionCache({conversation.content}),
        ),
        conversation.senderId == ref.read(accountServerProvider).value?.userId,
        isGroup,
        conversation.senderFullName,
      );
    });

class ConversationList extends ConsumerWidget {
  const ConversationList({required Key key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final slideCategoryState =
        (key! as PageStorageKey<SlideCategoryState>).value;

    final conversationListBloc = ref.read(
      conversationListControllerProvider.notifier,
    );
    final pagingState = ref.watch(conversationListControllerProvider);
    final conversationId = ref.watch(currentConversationIdProvider);

    final routeMode = ref.watch(navigatorRouteModeProvider);

    final itemPositionsListener = conversationListBloc.itemPositionsListener(
      slideCategoryState,
    );
    final itemScrollController = conversationListBloc.itemScrollController(
      slideCategoryState,
    );

    if (itemPositionsListener == null || itemScrollController == null) {
      return const SizedBox();
    }

    Widget child;

    child = pagingState.count == 0
        ? pagingState.hasData
              ? Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(theme.accent),
                  ),
                )
              : const _Empty()
        : ScrollablePositionedList.builder(
            key: PageStorageKey(slideCategoryState),
            itemPositionsListener: itemPositionsListener,
            itemCount: pagingState.count,
            itemScrollController: itemScrollController,
            itemBuilder: (context, index) {
              final conversation = pagingState.map[index];
              if (conversation == null) return const SizedBox(height: 80);
              final selected =
                  conversation.conversationId == conversationId && !routeMode;
              return ConversationMenuWrapper(
                conversation: conversation,
                removeChatFromCircle: true,
                child: ConversationItemWidget(
                  selected: selected,
                  conversation: conversation,
                  onTap: () {
                    ConversationStateNotifier.selectConversation(
                      ref.container,
                      context,
                      conversation.conversationId,
                      conversation: conversation,
                    );
                  },
                ),
              );
            },
          );

    return Column(
      children: [
        const NetworkStatus(),
        Expanded(child: child),
        const AnimatedSize(
          duration: Duration(milliseconds: 200),
          child: AudioPlayerBar(),
        ),
      ],
    );
  }
}

class _Empty extends ConsumerWidget {
  const _Empty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dynamicColor = ref.watch(
      dynamicColorProvider((
        color: const Color.fromRGBO(229, 233, 240, 1),
        darkColor: null,
      )),
    );
    final l10n = ref.watch(localizationProvider);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            Resources.assetsImagesEmptyFileSvg,
            height: 78,
            width: 58,
            colorFilter: ColorFilter.mode(dynamicColor, BlendMode.srcIn),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noData,
            style: TextStyle(color: dynamicColor, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class ConversationItemWidget extends ConsumerWidget {
  const ConversationItemWidget({
    required this.conversation,
    required this.onTap,
    super.key,
    this.selected = false,
  });

  final bool selected;
  final ConversationItem conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final l10n = ref.watch(localizationProvider);
    final messageColor = theme.secondaryText;
    return SizedBox(
      height: ConversationPage.conversationItemHeight,
      child: InteractiveDecoratedBox(
        onTap: onTap,
        decoration: BoxDecoration(color: theme.primary),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DecoratedBox(
            decoration: selected
                ? BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    color: theme.listSelected,
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
                                      child: CustomText(
                                        conversation.validName,
                                        style: TextStyle(
                                          color: theme.text,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    BadgesWidget(
                                      verified: conversation.ownerVerified,
                                      isBot: conversation.isBotConversation,
                                      membership: conversation.membership,
                                    ),
                                  ],
                                ),
                              ),
                              Consumer(
                                builder: (context, ref, _) {
                                  final text = ref.watch(
                                    formattedDateTimeProvider(
                                      conversation.lastMessageCreatedAt ??
                                          conversation.createdAt,
                                    ),
                                  );
                                  return Text(
                                    text,
                                    style: TextStyle(
                                      color: messageColor,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          _ItemConversationSubtitle(conversation: conversation),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemConversationSubtitle extends ConsumerWidget {
  const _ItemConversationSubtitle({required this.conversation});

  final ConversationItem conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          Expanded(
            child: _MessagePreview(
              messageColor: theme.secondaryText,
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
                  backgroundColor: theme.accent,
                ),
              if ((conversation.unseenMessageCount ?? 0) > 0)
                UnreadText(
                  data: '${conversation.unseenMessageCount}',
                  textColor: const Color.fromRGBO(255, 255, 255, 1),
                  backgroundColor: conversation.isMute
                      ? theme.secondaryText
                      : theme.accent,
                ),
              if ((conversation.unseenMessageCount ?? 0) <= 0)
                _StatusRow(conversation: conversation),
            ].joinList(const SizedBox(width: 8)),
          ),
        ],
      ),
    );
  }
}

class _MessagePreview extends StatelessWidget {
  const _MessagePreview({
    required this.messageColor,
    required this.conversation,
  });

  final Color messageColor;
  final ConversationItem conversation;

  @override
  Widget build(BuildContext context) {
    final quited = conversation.status == ConversationStatus.quit;
    final hasDraft = !quited && (conversation.draft?.isNotEmpty ?? false);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!hasDraft) _MessageStatusIcon(conversation: conversation),
        if (!hasDraft) const SizedBox(width: 2),
        Expanded(
          child: _MessageContent(
            conversation: conversation,
            hasDraft: hasDraft,
          ),
        ),
      ],
    );
  }
}

class _MessageContent extends ConsumerWidget {
  const _MessageContent({required this.conversation, required this.hasDraft});

  final ConversationItem conversation;
  final bool hasDraft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final l10n = ref.watch(localizationProvider);
    final text = ref
        .watch(_conversationPreviewTextProvider(conversation))
        .value;

    final icon = messagePreviewIcon(
      conversation.messageStatus,
      conversation.contentType,
    );

    if (conversation.contentType == null && !hasDraft) return const SizedBox();

    final dynamicColor = theme.secondaryText;

    return Row(
      children: [
        if (!hasDraft && icon != null)
          SvgPicture.asset(
            icon,
            colorFilter: ColorFilter.mode(dynamicColor, BlendMode.srcIn),
          ),
        if (hasDraft)
          Text(
            '${l10n.draft}:',
            style: TextStyle(color: theme.red, fontSize: 14),
          ),
        if (text != null)
          Expanded(
            child: CustomText(
              text.overflow,
              style: TextStyle(color: dynamicColor, fontSize: 14),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
      ].joinList(const SizedBox(width: 4)),
    );
  }
}

class _MessageStatusIcon extends ConsumerWidget {
  const _MessageStatusIcon({required this.conversation});

  final ConversationItem conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selfUserId = ref.watch(authAccountProvider)?.userId;
    if (selfUserId == conversation.senderId &&
        conversation.contentType != MessageCategory.systemConversation &&
        conversation.contentType != MessageCategory.systemAccountSnapshot &&
        !conversation.contentType.isCallMessage &&
        !conversation.contentType.isRecall &&
        !conversation.contentType.isGroupCall &&
        !conversation.contentType.isPin) {
      return MessageStatusIcon(status: conversation.messageStatus);
    }
    return const SizedBox();
  }
}

class _StatusRow extends ConsumerWidget {
  const _StatusRow({required this.conversation});

  final ConversationItem conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (conversation.isMute)
          SvgPicture.asset(
            Resources.assetsImagesMuteSvg,
            colorFilter: ColorFilter.mode(theme.secondaryText, BlendMode.srcIn),
          ),
        if (conversation.pinTime != null)
          SvgPicture.asset(
            Resources.assetsImagesPinSvg,
            colorFilter: ColorFilter.mode(theme.secondaryText, BlendMode.srcIn),
          ),
      ].joinList(const SizedBox(width: 4)),
    );
  }
}
