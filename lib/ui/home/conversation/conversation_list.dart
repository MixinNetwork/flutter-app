import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide Key, User;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:vector_graphics/vector_graphics_compat.dart'
    show RenderingStrategy;

import '../../../blaze/vo/pin_message_minimal.dart';
import '../../../constants/resources.dart';
import '../../../db/dao/conversation_dao.dart';
import '../../../db/dao/user_dao.dart' show MentionUser;
import '../../../db/mixin_database.dart' show User;
import '../../../enum/message_category.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/message_optimize.dart';
import '../../../utils/reg_exp_utils.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/conversation/badges_widget.dart';
import '../../../widgets/deferred_mount.dart';
import '../../../widgets/high_light_text.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/message/item/pin_message.dart';
import '../../../widgets/message/item/system_message.dart';
import '../../../widgets/message_status_icon.dart';
import '../../../widgets/unread_text.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/mention_cache_provider.dart';
import '../../provider/minute_timer_provider.dart';
import '../../provider/slide_category_provider.dart';
import '../desktop_shell_layout.dart';
import '../notifier/conversation_list_controller.dart';
import 'audio_player_bar.dart';
import 'conversation_avatar_cache.dart';
import 'conversation_focus.dart';
import 'conversation_page.dart';
import 'menu_wrapper.dart';
import 'network_status.dart';

class ConversationList extends HookConsumerWidget {
  const ConversationList({required Key key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slideCategoryState =
        (key! as PageStorageKey<SlideCategoryState>).value;

    final conversationListController = context
        .read<ConversationListController>();
    final listState = useValueListenable(conversationListController);
    // Rows are cached by conversation: a list update returns the same widget
    // for rows whose conversation did not change, so Flutter skips them.
    final rowCache = useRef<Map<String, DeferredMount>>({});
    final indexes = useMemoized(() {
      final indexes = {
        for (final (index, item) in listState.items.indexed)
          item.conversationId: index,
      };
      rowCache.value.removeWhere((id, _) => !indexes.containsKey(id));
      return indexes;
    }, [listState.items]);

    final showsConversationSelection = !DesktopShellLayout.mainRouteModeOf(
      context,
    );

    final itemPositionsListener = conversationListController
        .itemPositionsListener(
          slideCategoryState,
        );
    final itemScrollController = conversationListController
        .itemScrollController(
          slideCategoryState,
        );

    if (itemPositionsListener == null || itemScrollController == null) {
      return const SizedBox();
    }

    Widget child;

    child = listState.count == 0
        ? listState.hasData
              ? Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(context.theme.accent),
                  ),
                )
              : const _Empty()
        : ScrollablePositionedList.builder(
            key: PageStorageKey(slideCategoryState),
            itemPositionsListener: itemPositionsListener,
            itemCount: listState.count,
            itemScrollController: itemScrollController,
            // A conversation with a new message moves to the top, and the
            // rows above its old index move down; the callback lets them keep
            // their elements instead of being built again.
            findChildIndexCallback: (key) =>
                key is ValueKey<String> ? indexes[key.value] : null,
            itemBuilder: (context, index) => conversationRow(
              rowCache.value,
              listState.items[index],
              avatarCache: conversationListController.avatarCache,
              showsSelection: showsConversationSelection,
            ),
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

/// The row of [conversation] from [cache], or a new one. A list update returns
/// the same widget for rows whose conversation did not change, so Flutter
/// skips them, and a new list mounts its rows over a few frames.
DeferredMount conversationRow(
  Map<String, DeferredMount> cache,
  ConversationItem conversation, {
  required ConversationAvatarCache avatarCache,
  required bool showsSelection,
}) {
  final cached = cache[conversation.conversationId];
  final cachedItem = cached?.child as _ConversationListItem?;
  if (cached != null &&
      cachedItem!.conversation == conversation &&
      cachedItem.showsSelection == showsSelection) {
    return cached;
  }
  return cache[conversation.conversationId] = DeferredMount(
    key: ValueKey(conversation.conversationId),
    placeholder: const SizedBox(
      height: ConversationPage.conversationItemHeight,
    ),
    child: _ConversationListItem(
      conversation: conversation,
      avatarCache: avatarCache,
      showsSelection: showsSelection,
    ),
  );
}

/// One row of the conversation list. It watches only its own avatar users and
/// whether it is the current conversation, so loading avatars while scrolling
/// or switching conversations rebuilds the affected rows, not the whole list.
class _ConversationListItem extends HookConsumerWidget {
  const _ConversationListItem({
    required this.conversation,
    required this.avatarCache,
    required this.showsSelection,
  });

  final ConversationItem conversation;
  final ConversationAvatarCache avatarCache;
  final bool showsSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationId = conversation.conversationId;
    final groupAvatarUsers = useListenableSelector(
      avatarCache,
      () => avatarCache.usersFor(conversationId),
    );
    // Select on conversationProvider itself: chaining select on
    // currentConversationIdProvider notified every row on any change.
    final current = ref.watch(
      conversationProvider.select(
        (state) => state?.conversationId == conversationId,
      ),
    );
    return ConversationMenuWrapper(
      conversation: conversation,
      removeChatFromCircle: true,
      child: ConversationItemWidget(
        selected: current && showsSelection,
        conversation: conversation,
        groupAvatarUsers: groupAvatarUsers,
        onTap: () {
          ConversationFocus.selectConversation(
            context,
            conversationId,
            conversation: conversation,
          );
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final dynamicColor = context.dynamicColor(
      const Color.fromRGBO(229, 233, 240, 1),
    );
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            Resources.assetsImagesEmptyFileSvg,
            renderingStrategy: RenderingStrategy.raster,
            height: 78,
            width: 58,
            colorFilter: ColorFilter.mode(dynamicColor, BlendMode.srcIn),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.noData,
            style: TextStyle(color: dynamicColor, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class ConversationItemWidget extends StatelessWidget {
  const ConversationItemWidget({
    required this.conversation,
    required this.onTap,
    super.key,
    this.selected = false,
    this.groupAvatarUsers,
  });

  final bool selected;
  final ConversationItem conversation;
  final VoidCallback onTap;
  final List<User>? groupAvatarUsers;

  @override
  Widget build(BuildContext context) {
    final messageColor = context.theme.secondaryText;
    return SizedBox(
      height: ConversationPage.conversationItemHeight,
      child: InteractiveDecoratedBox(
        onTap: onTap,
        decoration: BoxDecoration(color: context.theme.primary),
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
                    groupAvatarUsers: groupAvatarUsers,
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
                                          color: context.theme.text,
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
                                      isGroup: conversation.isGroupConversation,
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

class _ItemConversationSubtitle extends StatelessWidget {
  const _ItemConversationSubtitle({required this.conversation});

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
        if ((conversation.expireIn ?? 0) > 0)
          SvgPicture.asset(
            Resources.assetsImagesDisappearingMessageIndicatorSvg,
            renderingStrategy: RenderingStrategy.raster,
            colorFilter: ColorFilter.mode(
              context.theme.secondaryText,
              BlendMode.srcIn,
            ),
            width: 14,
            height: 14,
          ),
        if ((conversation.expireIn ?? 0) > 0) const SizedBox(width: 2),
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

class _MessageContent extends HookConsumerWidget {
  const _MessageContent({required this.conversation, required this.hasDraft});

  final ConversationItem conversation;
  final bool hasDraft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentionCache = ref.read(mentionCacheProvider);
    final keys = [
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
      conversation.draft,
      hasDraft,
    ];
    String? preview(Map<String, MentionUser> mentions) {
      if (hasDraft) return conversation.draft;
      final isGroup =
          conversation.category == ConversationCategory.group ||
          conversation.senderId != conversation.ownerId;
      if (conversation.contentType == MessageCategory.systemConversation) {
        return generateSystemText(
          actionName: conversation.actionName,
          participantUserId: conversation.participantUserId,
          senderId: conversation.senderId,
          currentUserId: context.accountServer.userId,
          participantFullName: conversation.participantFullName,
          senderFullName: conversation.senderFullName,
          expireIn: int.tryParse(conversation.content ?? '0'),
        );
      } else if (conversation.contentType.isPin) {
        final pinMessageMinimal = PinMessageMinimal.fromJsonString(
          conversation.content ?? '',
        );
        return context.l10n.chatPinMessage(
          conversation.senderFullName ?? '',
          pinMessageMinimal == null
              ? context.l10n.aMessage
              : cachePinPreviewText(
                  pinMessageMinimal: pinMessageMinimal,
                  mentionCache: mentionCache,
                ),
        );
      }
      return messagePreviewOptimize(
        conversation.messageStatus,
        conversation.contentType,
        mentionCache.replaceMention(conversation.content, mentions),
        conversation.senderId == context.accountServer.userId,
        isGroup,
        conversation.senderFullName,
      );
    }

    // The list controller fills the mention cache before it shows a list, so
    // the preview is final in the first frame. Only content that mentions
    // users looks them up again, for users not cached yet.
    final cachedText = useMemoized(
      () => preview(mentionCache.mentionCache(conversation.content)),
      keys,
    );
    final mayMention =
        !hasDraft && mentionNumberRegExp.hasMatch(conversation.content ?? '');

    final icon = useMemoized(
      () => messagePreviewIcon(
        conversation.messageStatus,
        conversation.contentType,
      ),
      [conversation.messageStatus, conversation.contentType],
    );

    if (conversation.contentType == null && !hasDraft) return const SizedBox();

    final dynamicColor = context.theme.secondaryText;
    Widget previewText(String text) => Expanded(
      child: CustomText(
        text.overflow,
        style: TextStyle(color: dynamicColor, fontSize: 14),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );

    return Row(
      children: [
        if (!hasDraft && icon != null)
          SvgPicture.asset(
            icon,
            renderingStrategy: RenderingStrategy.raster,
            colorFilter: ColorFilter.mode(dynamicColor, BlendMode.srcIn),
          ),
        if (hasDraft)
          Text(
            '${context.l10n.draft}:',
            style: TextStyle(color: context.theme.red, fontSize: 14),
          ),
        if (mayMention)
          _MentionedPreview(
            keys: keys,
            initialText: cachedText,
            load: () async => preview(
              await mentionCache.checkMentionCache({conversation.content}),
            ),
            builder: previewText,
          )
        else if (cachedText != null)
          previewText(cachedText),
      ].joinList(const SizedBox(width: 4)),
    );
  }
}

/// A preview that mentions users: shows the cached names first, then the names
/// of users that were not cached yet.
class _MentionedPreview extends HookWidget {
  const _MentionedPreview({
    required this.keys,
    required this.initialText,
    required this.load,
    required this.builder,
  });

  final List<Object?> keys;
  final String? initialText;
  final Future<String?> Function() load;
  final Widget Function(String text) builder;

  @override
  Widget build(BuildContext context) {
    final text = useMemoizedFuture(load, initialText, keys: keys).data;
    return text == null ? const SizedBox() : builder(text);
  }
}

class _MessageStatusIcon extends StatelessWidget {
  const _MessageStatusIcon({required this.conversation});

  final ConversationItem conversation;

  @override
  Widget build(BuildContext context) {
    if (context.account?.userId == conversation.senderId &&
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

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.conversation});

  final ConversationItem conversation;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      if (conversation.isMute)
        SvgPicture.asset(
          Resources.assetsImagesMuteSvg,
          renderingStrategy: RenderingStrategy.raster,
          colorFilter: ColorFilter.mode(
            context.theme.secondaryText,
            BlendMode.srcIn,
          ),
        ),
      if (conversation.pinTime != null)
        SvgPicture.asset(
          Resources.assetsImagesPinSvg,
          renderingStrategy: RenderingStrategy.raster,
          colorFilter: ColorFilter.mode(
            context.theme.secondaryText,
            BlendMode.srcIn,
          ),
        ),
    ].joinList(const SizedBox(width: 4)),
  );
}
