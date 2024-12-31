import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:rxdart/rxdart.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../blaze/vo/pin_message_minimal.dart';
import '../../../constants/resources.dart';
import '../../../db/dao/conversation_dao.dart';
import '../../../db/dao/message_dao.dart';
import '../../../db/database_event_bus.dart';
import '../../../db/extension/conversation.dart';
import '../../../db/mixin_database.dart';
import '../../../enum/message_category.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/logger.dart';
import '../../../utils/message_optimize.dart';
import '../../../utils/reg_exp_utils.dart';
import '../../../utils/uri_utils.dart';
import '../../../utils/web_view/web_view_interface.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/conversation/badges_widget.dart';
import '../../../widgets/high_light_text.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/message/item/pin_message.dart';
import '../../../widgets/message/item/system_message.dart';
import '../../../widgets/mixin_image.dart';
import '../../../widgets/toast.dart';
import '../../../widgets/user/user_dialog.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/conversation_unseen_filter_enabled.dart';
import '../../provider/keyword_provider.dart';
import '../../provider/mention_cache_provider.dart';
import '../../provider/minute_timer_provider.dart';
import '../../provider/search_mao_user_provider.dart';
import '../../provider/slide_category_provider.dart';
import '../bloc/conversation_list_bloc.dart';
import '../bloc/search_message_cubit.dart';
import 'conversation_page.dart';
import 'menu_wrapper.dart';
import 'unseen_conversation_list.dart';

const _defaultLimit = 3;

void _clear(BuildContext context) {
  context.providerContainer.read(keywordProvider.notifier).state = '';
  context.read<TextEditingController>().text = '';
  context.read<FocusNode>().unfocus();
}

class SearchList extends HookConsumerWidget {
  const SearchList({super.key, this.filterUnseen = false});

  final bool filterUnseen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyword = useMemoizedStream(
          () {
            final keywordCubit = ref.watch(keywordProvider.notifier);
            return keywordCubit.stream
                .startWith(keywordCubit.state)
                .map((event) => event.trim())
                .distinct()
                .debounceTime(const Duration(milliseconds: 150));
          },
        ).data ??
        '';

    final accountServer = context.accountServer;

    final slideCategoryState = ref.watch(slideCategoryStateProvider);

    final maoUser = ref.watch(searchMaoUserProvider(keyword)).valueOrNull;

    final users = useMemoizedStream(() {
          if (keyword.trim().isEmpty || filterUnseen) {
            return Stream.value(<User>[]);
          }
          return accountServer.database.userDao
              .fuzzySearchUser(
            id: accountServer.userId,
            username: keyword,
            identityNumber: keyword,
            category: slideCategoryState,
            isIncludeConversation: true,
          )
              .watchWithStream(
            eventStreams: [
              DataBaseEventBus.instance.updateConversationIdStream,
              DataBaseEventBus.instance.updateUserIdsStream,
            ],
            duration: kSlowThrottleDuration,
          );
        }, keys: [keyword, filterUnseen, slideCategoryState]).data ??
        [];

    final conversations = useMemoizedStream(() {
          if (keyword.trim().isEmpty) {
            return Stream.value(<SearchConversationItem>[]);
          }
          return accountServer.database.conversationDao
              .fuzzySearchConversation(
            keyword,
            32,
            filterUnseen: filterUnseen,
            category: slideCategoryState,
          )
              .watchWithStream(
            eventStreams: [
              DataBaseEventBus.instance.updateConversationIdStream,
              DataBaseEventBus.instance.updateUserIdsStream,
            ],
            duration: kSlowThrottleDuration,
          );
        }, keys: [keyword, filterUnseen, slideCategoryState]).data ??
        [];

    final messages = useMemoizedFuture<List<SearchMessageDetailItem>>(
            () => keyword.isEmpty
                ? Future.value(<SearchMessageDetailItem>[])
                : accountServer.database.fuzzySearchMessageByCategory(
                    keyword,
                    limit: 4,
                    unseenConversationOnly: filterUnseen,
                    category: slideCategoryState,
                  ),
            [],
            keys: [keyword, filterUnseen, slideCategoryState]).data ??
        [];

    final isMixinNumber =
        useMemoized(() => numberRegExp.hasMatch(keyword), [keyword]);
    final isUrl = useMemoized(() {
      final uri = Uri.tryParse(keyword);
      return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    }, [keyword]);

    final type = useState<_ShowMoreType?>(null);

    final resultIsEmpty = maoUser == null &&
        users.isEmpty &&
        conversations.isEmpty &&
        messages.isEmpty;

    if (keyword.isEmpty && filterUnseen) {
      return const UnseenConversationList();
    }

    if (resultIsEmpty && (!isMixinNumber && !isUrl)) {
      return const SearchEmptyWidget();
    }

    if (type.value == _ShowMoreType.message) {
      return _SearchMessageList(
        keyword: keyword,
        onTap: () => type.value = null,
        filterUnseen: filterUnseen,
        categoryState: slideCategoryState,
      );
    }
    return CustomScrollView(
      slivers: [
        if (maoUser != null)
          SliverToBoxAdapter(
            child: _SearchMaoUserWidget(
              maoUser: maoUser,
              keyword: keyword,
            ),
          ),
        if (users.isEmpty && isUrl)
          SliverToBoxAdapter(
            child: SearchItem(
              name: context.l10n.openLink(keyword),
              keyword: keyword,
              maxLines: true,
              onTap: () => openUriWithWebView(context, keyword),
            ),
          ),
        if (users.isEmpty && isMixinNumber)
          SliverToBoxAdapter(
            child: SearchItem(
              name: context.l10n.searchPlaceholderNumber + keyword,
              keyword: keyword,
              maxLines: true,
              onTap: () async {
                showToastLoading();

                String? userId;

                try {
                  final mixinResponse = await context
                      .accountServer.client.userApi
                      .search(keyword);
                  await context.database.userDao
                      .insertSdkUser(mixinResponse.data);
                  userId = mixinResponse.data.userId;
                } catch (error) {
                  showToastFailed(ToastError(context.l10n.userNotFound));
                }

                Toast.dismiss();

                if (userId != null) await showUserDialog(context, userId);
              },
            ),
          ),
        if (users.isNotEmpty)
          SliverToBoxAdapter(
            child: _SearchHeader(
              title: context.l10n.contact,
              showMore: users.length > _defaultLimit,
              more: type.value != _ShowMoreType.contact,
              onTap: () {
                type.value = type.value != _ShowMoreType.contact
                    ? _ShowMoreType.contact
                    : null;
              },
            ),
          ),
        if (users.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final user = users[index];
                return SearchItem(
                  avatar: AvatarWidget(
                    name: user.fullName,
                    userId: user.userId,
                    size: ConversationPage.conversationItemAvatarSize,
                    avatarUrl: user.avatarUrl,
                  ),
                  name: user.fullName ?? '?',
                  description: context.l10n.contactMixinId(user.identityNumber),
                  trailing: BadgesWidget(
                    verified: user.isVerified,
                    isBot: user.appId != null,
                    membership: user.membership,
                  ),
                  keyword: keyword,
                  onTap: () async {
                    await ConversationStateNotifier.selectUser(
                      context,
                      user.userId,
                      user: user,
                    );
                    _clear(context);
                  },
                );
              },
              childCount: type.value == _ShowMoreType.contact
                  ? users.length
                  : min(users.length, _defaultLimit),
            ),
          ),
        if (users.isNotEmpty)
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
        if (conversations.isNotEmpty)
          SliverToBoxAdapter(
            child: _SearchHeader(
              title: context.l10n.conversation,
              showMore: conversations.length > _defaultLimit,
              more: type.value != _ShowMoreType.conversation,
              onTap: () {
                type.value = type.value != _ShowMoreType.conversation
                    ? _ShowMoreType.conversation
                    : null;
              },
            ),
          ),
        if (conversations.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final conversation = conversations[index];
                return HookConsumer(builder: (context, ref, _) {
                  final description = useMemoizedFuture(() async {
                    final mentionCache = ref.read(mentionCacheProvider);

                    if (conversation.contentType ==
                        MessageCategory.systemConversation) {
                      return generateSystemText(
                        actionName: conversation.actionName,
                        participantUserId: conversation.participantUserId,
                        senderId: conversation.senderId,
                        currentUserId: context.accountServer.userId,
                        participantFullName: conversation.participantFullName,
                        senderFullName: conversation.senderFullName,
                        expireIn: int.tryParse(conversation.content ?? '0'),
                      );
                    }

                    if (conversation.contentType.isPin) {
                      final pinMessageMinimal =
                          PinMessageMinimal.fromJsonString(
                              conversation.content ?? '');
                      if (pinMessageMinimal == null) {
                        return context.l10n.chatPinMessage(
                            conversation.senderFullName ?? '',
                            context.l10n.aMessage);
                      }
                      final preview = await generatePinPreviewText(
                        pinMessageMinimal: pinMessageMinimal,
                        mentionCache: ref.read(mentionCacheProvider),
                      );
                      return context.l10n.chatPinMessage(
                          conversation.senderFullName ?? '', preview);
                    }

                    return messagePreviewOptimize(
                        conversation.messageStatus,
                        conversation.contentType,
                        mentionCache.replaceMention(
                          conversation.content,
                          await mentionCache
                              .checkMentionCache({conversation.content}),
                        ),
                        conversation.senderId == context.accountServer.userId,
                        conversation.isGroupConversation,
                        conversation.senderFullName);
                  }, null, keys: [
                    conversation.actionName,
                    conversation.participantUserId,
                    context.accountServer.userId,
                    conversation.participantFullName,
                    conversation.messageStatus,
                    conversation.contentType,
                    conversation.content,
                    conversation.senderId,
                    conversation.isGroupConversation,
                    conversation.senderFullName
                  ]).data;

                  return ConversationMenuWrapper(
                    searchConversation: conversation,
                    child: SearchItem(
                      avatar: ConversationAvatarWidget(
                        conversationId: conversation.conversationId,
                        fullName: conversation.validName,
                        groupIconUrl: conversation.groupIconUrl,
                        avatarUrl: conversation.avatarUrl,
                        category: conversation.category,
                        size: ConversationPage.conversationItemAvatarSize,
                        userId: conversation.ownerId,
                      ),
                      name: conversation.validName,
                      description: description,
                      trailing: BadgesWidget(
                        verified: conversation.isVerified,
                        isBot: conversation.appId != null,
                        membership: conversation.membership,
                      ),
                      keyword: keyword,
                      onTap: () async {
                        await ConversationStateNotifier.selectConversation(
                          context,
                          conversation.conversationId,
                        );

                        _clear(context);
                      },
                    ),
                  );
                });
              },
              childCount: type.value == _ShowMoreType.conversation
                  ? conversations.length
                  : min(conversations.length, _defaultLimit),
            ),
          ),
        if (conversations.isNotEmpty)
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
        if (messages.isNotEmpty)
          SliverToBoxAdapter(
            child: _SearchHeader(
              title: context.l10n.messages,
              showMore: messages.length > _defaultLimit,
              more: type.value != _ShowMoreType.message,
              onTap: () {
                type.value = type.value != _ShowMoreType.message
                    ? _ShowMoreType.message
                    : null;
              },
            ),
          ),
        if (messages.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final message = messages[index];
                return SearchMessageItem(
                  message: message,
                  keyword: keyword,
                  onTap: _searchMessageItemOnTap(context, message),
                );
              },
              childCount: type.value == _ShowMoreType.message
                  ? messages.length
                  : min(messages.length, _defaultLimit),
            ),
          ),
        if (messages.isNotEmpty)
          const SliverToBoxAdapter(child: SizedBox(height: 10))
      ],
    );
  }
}

const _maoIcon =
    'https://kernel.mixin.dev/objects/fe75a8e48aeffb486df622c91bebfe4056ada7009f3151fb49e2a18340bbd615/icon';

class _SearchMaoUserWidget extends StatelessWidget {
  const _SearchMaoUserWidget({
    required this.maoUser,
    required this.keyword,
  });

  final MaoUser maoUser;
  final String keyword;

  @override
  Widget build(BuildContext context) {
    final defaultInscriptionImage = SvgPicture.asset(
      Resources.assetsImagesInscriptionPlaceholderSvg,
      width: 14,
      height: 14,
    );
    Widget? openButton;
    if (maoUser.user.isBot) {
      openButton = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: context.theme.accent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 12),
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        onPressed: () async {
          final app =
              await context.accountServer.findOrSyncApp(maoUser.user.appId!);
          if (app == null) {
            e('app not found: ${maoUser.user.appId}');
            showToastFailed(null);
            return;
          }
          await MixinWebView.instance.openBotWebViewWindow(context, app);
        },
        child: Text(context.l10n.open),
      );
    }
    return SearchItem(
      avatar: AvatarWidget(
        name: maoUser.user.fullName,
        userId: maoUser.user.userId,
        size: ConversationPage.conversationItemAvatarSize,
        avatarUrl: maoUser.user.avatarUrl,
      ),
      name: maoUser.user.fullName ?? '?',
      description: maoUser.mao,
      trailing: BadgesWidget(
        verified: maoUser.user.isVerified,
        isBot: maoUser.user.appId != null,
        membership: maoUser.user.membership,
      ),
      contentTrailing: openButton,
      descriptionIconWidget: ClipOval(
        child: MixinImage.network(
          _maoIcon,
          width: 14,
          height: 14,
          errorBuilder: (context, error, stackTrace) {
            e('load mao icon error: $error, $stackTrace');
            return defaultInscriptionImage;
          },
          placeholder: () => defaultInscriptionImage,
        ),
      ),
      keyword: keyword,
      onTap: () async {
        if (maoUser.user.userId == context.accountServer.userId) {
          _clear(context);
          await showUserDialog(context, maoUser.user.userId);
          return;
        }
        await ConversationStateNotifier.selectUser(
          context,
          maoUser.user.userId,
          user: maoUser.user,
        );
        _clear(context);
      },
    );
  }
}

class SearchItem extends StatelessWidget {
  const SearchItem({
    required this.name,
    required this.keyword,
    required this.onTap,
    super.key,
    this.avatar,
    this.nameHighlight = true,
    this.description,
    this.descriptionIcon,
    this.date,
    this.trailing,
    this.selected,
    this.maxLines = false,
    this.margin = const EdgeInsets.symmetric(horizontal: 6),
    this.padding = const EdgeInsets.symmetric(
      horizontal: 6,
      vertical: 12,
    ),
    this.nameFontSize = 16,
    this.descriptionIconWidget,
    this.contentTrailing,
  });

  final Widget? avatar;
  final Widget? trailing;
  final String name;
  final String keyword;
  final bool nameHighlight;
  final VoidCallback onTap;
  final String? description;
  final String? descriptionIcon;
  final Widget? descriptionIconWidget;
  final DateTime? date;
  final bool? selected;
  final bool maxLines;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double nameFontSize;
  final Widget? contentTrailing;

  @override
  Widget build(BuildContext context) {
    final selectedDecoration = BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      color: context.theme.listSelected,
    );
    return Padding(
      padding: margin,
      child: InteractiveDecoratedBox(
        decoration:
            selected == true ? selectedDecoration : const BoxDecoration(),
        hoveringDecoration: selectedDecoration,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: padding,
          child: Row(
            children: [
              if (avatar != null)
                SizedBox(
                  height: ConversationPage.conversationItemAvatarSize,
                  width: ConversationPage.conversationItemAvatarSize,
                  child: avatar,
                ),
              if (avatar != null) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: CustomText(
                                  name,
                                  maxLines: maxLines ? null : 1,
                                  overflow:
                                      maxLines ? null : TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.theme.text,
                                    fontSize: nameFontSize,
                                  ),
                                  textMatchers: [
                                    EmojiTextMatcher(),
                                    KeyWordTextMatcher(
                                      keyword,
                                      style: TextStyle(
                                        color: context.theme.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (trailing != null) trailing!,
                            ],
                          ),
                        ),
                        if (date != null)
                          Consumer(
                            builder: (context, ref, _) => Text(
                              ref.watch(formattedDateTimeProvider(date!)),
                              style: TextStyle(
                                color: context.theme.secondaryText,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (description != null)
                      Row(
                        children: [
                          if (descriptionIconWidget != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: descriptionIconWidget,
                            ),
                          if (descriptionIcon != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: SvgPicture.asset(
                                descriptionIcon!,
                                colorFilter: ColorFilter.mode(
                                  context.theme.secondaryText,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          Expanded(
                            child: CustomText(
                              description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.theme.secondaryText,
                                fontSize: 14,
                              ),
                              textMatchers: [
                                EmojiTextMatcher(),
                                KeyWordTextMatcher(
                                  keyword,
                                  style: TextStyle(
                                    color: context.theme.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (contentTrailing != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: contentTrailing,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchMessageList extends HookConsumerWidget {
  const _SearchMessageList({
    required this.keyword,
    required this.onTap,
    required this.filterUnseen,
    required this.categoryState,
  });

  final String keyword;
  final VoidCallback onTap;
  final bool filterUnseen;
  final SlideCategoryState categoryState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchMessageCubit = useBloc(
      () => SearchMessageCubit.slideCategory(
        database: context.database,
        category: categoryState,
        keyword: keyword,
        limit: context.read<ConversationListBloc>().limit,
      ),
      keys: [keyword, categoryState],
    );

    final pageState = useBlocState<SearchMessageCubit, SearchMessageState>(
        bloc: searchMessageCubit);

    final child = pageState.initializing
        ? Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(context.theme.accent),
            ),
          )
        : pageState.items.isEmpty
            ? const SearchEmptyWidget()
            : ScrollablePositionedList.builder(
                itemPositionsListener: searchMessageCubit.itemPositionsListener,
                itemCount: pageState.items.length,
                itemBuilder: (context, index) {
                  final message = pageState.items[index];
                  return SearchMessageItem(
                    message: message,
                    keyword: keyword,
                    onTap: _searchMessageItemOnTap(context, message),
                  );
                });

    return Column(
      children: [
        _SearchHeader(
          title: context.l10n.messages,
          showMore: true,
          more: false,
          onTap: onTap,
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.title,
    required this.showMore,
    required this.onTap,
    required this.more,
  });

  final String title;
  final bool showMore;
  final VoidCallback onTap;
  final bool more;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(
          top: 16,
          bottom: 10,
          right: 20,
          left: 12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: context.theme.text,
              ),
            ),
            if (showMore)
              GestureDetector(
                onTap: onTap,
                child: Text(
                  more ? context.l10n.more : context.l10n.less,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.theme.accent,
                  ),
                ),
              ),
          ],
        ),
      );
}

enum _ShowMoreType {
  contact,
  conversation,
  message,
}

Future Function() _searchMessageItemOnTap(
        BuildContext context, SearchMessageDetailItem message) =>
    () async {
      await ConversationStateNotifier.selectConversation(
        context,
        message.conversationId,
        initIndexMessageId: message.messageId,
        keyword: context.providerContainer.read(trimmedKeywordProvider),
      );

      _clear(context);
    };

class SearchMessageItem extends HookConsumerWidget {
  const SearchMessageItem({
    required this.message,
    required this.keyword,
    required this.onTap,
    super.key,
    this.showSender = false,
  });

  final SearchMessageDetailItem message;
  final bool showSender;
  final String keyword;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGroup = useMemoized(
        () =>
            message.category == ConversationCategory.group ||
            message.senderId != message.ownerId,
        [message.category, message.senderId, message.ownerId]);

    final icon = useMemoized(
        () => messagePreviewIcon(
              message.status,
              message.type,
            ),
        [
          message.status,
          message.type,
        ]);

    final description = useMemoizedFuture(() async {
      final mentionCache = ref.read(mentionCacheProvider);

      return messagePreviewOptimize(
          message.status,
          message.type,
          mentionCache.replaceMention(
            message.content,
            await mentionCache.checkMentionCache({message.content}),
          ),
          message.senderId == context.accountServer.userId,
          isGroup,
          message.senderFullName);
    }, null, keys: [
      message.status,
      message.type,
      message.content,
      isGroup,
      message.senderId,
      message.senderFullName
    ]).data;

    final avatar = showSender
        ? AvatarWidget(
            userId: message.senderId,
            avatarUrl: message.senderAvatarUrl,
            size: ConversationPage.conversationItemAvatarSize,
            name: message.senderFullName,
          )
        : ConversationAvatarWidget(
            conversationId: message.conversationId,
            fullName: conversationValidName(
              message.groupName,
              message.ownerFullName,
            ),
            groupIconUrl: message.groupIconUrl,
            avatarUrl: message.ownerAvatarUrl,
            category: message.category,
            size: ConversationPage.conversationItemAvatarSize,
            userId: message.ownerId,
          );
    return SearchItem(
      avatar: avatar,
      name: showSender
          ? message.senderFullName ?? ''
          : conversationValidName(
              message.groupName,
              message.ownerFullName,
            ),
      trailing: showSender || message.category == ConversationCategory.contact
          ? BadgesWidget(
              verified: message.verified,
              isBot: message.appId != null,
              membership: message.membership,
            )
          : null,
      nameHighlight: false,
      keyword: keyword,
      descriptionIcon: icon,
      description: description,
      date: message.createdAt,
      onTap: onTap,
    );
  }
}

class SearchEmptyWidget extends HookConsumerWidget {
  const SearchEmptyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 43,
          vertical: 86,
        ),
        width: double.infinity,
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            Text(
              context.l10n.searchEmpty,
              style: TextStyle(
                fontSize: 14,
                color: context.theme.secondaryText,
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              child: Text(
                context.l10n.clearFilter,
                style: TextStyle(
                  fontSize: 14,
                  color: context.theme.accent,
                ),
              ),
              onPressed: () {
                _clear(context);
                ref
                    .read(conversationUnseenFilterEnabledProvider.notifier)
                    .reset();
              },
            ),
          ],
        ),
      );
}
