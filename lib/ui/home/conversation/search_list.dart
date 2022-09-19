import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:rxdart/rxdart.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../bloc/bloc_converter.dart';
import '../../../bloc/keyword_cubit.dart';
import '../../../bloc/minute_timer_cubit.dart';
import '../../../bloc/paging/paging_bloc.dart';
import '../../../db/extension/conversation.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/message_optimize.dart';
import '../../../utils/reg_exp_utils.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/conversation/verified_or_bot_widget.dart';
import '../../../widgets/high_light_text.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/message/item/text/mention_builder.dart';
import '../../../widgets/toast.dart';
import '../../../widgets/user/user_dialog.dart';
import '../bloc/conversation_cubit.dart';
import '../bloc/conversation_filter_unseen_cubit.dart';
import '../bloc/conversation_list_bloc.dart';
import '../route/responsive_navigator_cubit.dart';
import 'conversation_list.dart';
import 'conversation_page.dart';
import 'menu_wrapper.dart';

const _defaultLimit = 3;

void _clear(BuildContext context) {
  context.read<KeywordCubit>().emit('');
  context.read<TextEditingController>().text = '';
  context.read<FocusNode>().unfocus();
}

class SearchList extends HookWidget {
  const SearchList({super.key, this.filterUnseen = false});

  final bool filterUnseen;

  @override
  Widget build(BuildContext context) {
    final keyword = useMemoizedStream(
          () {
            final keywordCubit = context.read<KeywordCubit>();
            return Stream.value(keywordCubit.state)
                .merge(keywordCubit.stream)
                .map((event) => event.trim())
                .distinct()
                .throttleTime(
                  const Duration(milliseconds: 150),
                  trailing: true,
                  leading: false,
                );
          },
          initialData: null,
        ).data ??
        '';

    final messageKeyword = useMemoizedStream(
          () {
            final keywordCubit = context.read<KeywordCubit>();
            return Stream.value(keywordCubit.state)
                .merge(keywordCubit.stream)
                .map((event) => event.trim())
                .distinct()
                .debounceTime(const Duration(milliseconds: 150));
          },
          initialData: null,
        ).data ??
        '';

    final accountServer = context.accountServer;

    final users = useMemoizedStream(() {
          if (keyword.trim().isEmpty || filterUnseen) {
            return Stream.value(<User>[]);
          }
          return accountServer.database.userDao
              .fuzzySearchUser(
                  id: accountServer.userId,
                  username: keyword,
                  identityNumber: keyword)
              .watchThrottle(kSlowThrottleDuration);
        }, keys: [keyword, filterUnseen]).data ??
        [];

    final conversations = useMemoizedStream(() {
          if (keyword.trim().isEmpty) {
            return Stream.value(<SearchConversationItem>[]);
          }
          return accountServer.database.conversationDao
              .fuzzySearchConversation(keyword, 32, filterUnseen: filterUnseen)
              .watchThrottle(kSlowThrottleDuration);
        }, keys: [keyword, filterUnseen]).data ??
        [];

    final messages = useMemoizedStream(
            () => messageKeyword.isEmpty
                ? Stream.value(<SearchMessageDetailItem>[])
                : accountServer.database.messageDao
                    .fuzzySearchMessage(
                        query: messageKeyword,
                        limit: 4,
                        unseenConversationOnly: filterUnseen)
                    .watchThrottle(kSlowThrottleDuration),
            keys: [messageKeyword, filterUnseen]).data ??
        [];

    final shouldTips =
        useMemoized(() => numberRegExp.hasMatch(keyword), [keyword]);

    final type = useState<_ShowMoreType?>(null);

    final resultIsEmpty =
        users.isEmpty && conversations.isEmpty && messages.isEmpty;

    if (keyword.isEmpty && filterUnseen) {
      return const _UnseenConversationList();
    }

    if (resultIsEmpty && !shouldTips) {
      return const _SearchEmpty();
    }

    if (type.value == _ShowMoreType.message) {
      return _SearchMessageList(
        keyword: keyword,
        onTap: () => type.value = null,
        filterUnseen: filterUnseen,
      );
    }
    return CustomScrollView(
      slivers: [
        if (users.isEmpty && shouldTips)
          SliverToBoxAdapter(
            child: SearchItem(
              name: context.l10n.searchPlaceholderNumber + keyword,
              keyword: keyword,
              maxLines: true,
              onTap: () async {
                showToastLoading(context);

                String? userId;

                try {
                  final mixinResponse = await context
                      .accountServer.client.userApi
                      .search(keyword);
                  await context.database.userDao
                      .insertSdkUser(mixinResponse.data);
                  userId = mixinResponse.data.userId;
                } catch (error) {
                  await showToastFailed(
                      context, ToastError(context.l10n.userNotFound));
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
                  trailing: VerifiedOrBotWidget(
                    verified: user.isVerified,
                    isBot: user.appId != null,
                  ),
                  keyword: keyword,
                  onTap: () async {
                    await ConversationCubit.selectUser(
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
                    trailing: VerifiedOrBotWidget(
                      verified: conversation.isVerified,
                      isBot: conversation.appId != null,
                    ),
                    keyword: keyword,
                    onTap: () async {
                      await ConversationCubit.selectConversation(
                        context,
                        conversation.conversationId,
                      );

                      _clear(context);
                    },
                  ),
                );
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

class SearchItem extends StatelessWidget {
  const SearchItem(
      {super.key,
      this.avatar,
      required this.name,
      required this.keyword,
      this.nameHighlight = true,
      required this.onTap,
      this.description,
      this.descriptionIcon,
      this.date,
      this.trailing,
      this.selected,
      this.maxLines = false});

  final Widget? avatar;
  final Widget? trailing;
  final String name;
  final String keyword;
  final bool nameHighlight;
  final VoidCallback onTap;
  final String? description;
  final String? descriptionIcon;
  final DateTime? date;
  final bool? selected;
  final bool maxLines;

  @override
  Widget build(BuildContext context) {
    final selectedDecoration = BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      color: context.theme.listSelected,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InteractiveDecoratedBox(
        decoration:
            selected == true ? selectedDecoration : const BoxDecoration(),
        hoveringDecoration: selectedDecoration,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 12,
          ),
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
                                child: HighlightText(
                                  name,
                                  maxLines: maxLines ? null : 1,
                                  overflow:
                                      maxLines ? null : TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.theme.text,
                                    fontSize: 16,
                                  ),
                                  highlightTextSpans: [
                                    if (nameHighlight)
                                      HighlightTextSpan(
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
                          BlocConverter<MinuteTimerCubit, DateTime, String>(
                            converter: (_) => date!.format,
                            builder: (context, text) => Text(
                              text,
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
                          if (descriptionIcon != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: SvgPicture.asset(
                                descriptionIcon!,
                                color: context.theme.secondaryText,
                              ),
                            ),
                          Expanded(
                            child: HighlightText(
                              description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.theme.secondaryText,
                                fontSize: 14,
                              ),
                              highlightTextSpans: [
                                HighlightTextSpan(
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchMessageList extends HookWidget {
  const _SearchMessageList({
    required this.keyword,
    required this.onTap,
    required this.filterUnseen,
  });

  final String keyword;
  final VoidCallback onTap;
  final bool filterUnseen;

  @override
  Widget build(BuildContext context) {
    final searchMessageBloc =
        useBloc<AnonymousPagingBloc<SearchMessageDetailItem>>(
      () => AnonymousPagingBloc<SearchMessageDetailItem>(
        initState: const PagingState<SearchMessageDetailItem>(),
        limit: context.read<ConversationListBloc>().limit,
        queryCount: () => context.database.messageDao
            .fuzzySearchMessageCount(
              keyword,
              unseenConversationOnly: filterUnseen,
            )
            .getSingle(),
        queryRange: (int limit, int offset) async {
          if (keyword.isEmpty) return [];
          return context.database.messageDao
              .fuzzySearchMessage(
                query: keyword,
                limit: limit,
                offset: offset,
                unseenConversationOnly: filterUnseen,
              )
              .get();
        },
      ),
      keys: [keyword, filterUnseen],
    );
    useEffect(
      () => context.database.messageDao.searchMessageUpdateEvent
          .listen((event) => searchMessageBloc.add(PagingUpdateEvent()))
          .cancel,
      [keyword],
    );
    final pageState = useBlocState<PagingBloc<SearchMessageDetailItem>,
        PagingState<SearchMessageDetailItem>>(bloc: searchMessageBloc);

    final child = !pageState.initialized
        ? Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(context.theme.accent),
            ),
          )
        : pageState.count <= 0
            ? const _SearchEmpty()
            : ScrollablePositionedList.builder(
                itemPositionsListener: searchMessageBloc.itemPositionsListener,
                itemCount: pageState.count,
                itemBuilder: (context, index) {
                  final message = pageState.map[index];
                  if (message == null) {
                    return const SizedBox(
                        height: ConversationPage.conversationItemHeight);
                  }
                  return SearchMessageItem(
                      message: message,
                      keyword: keyword,
                      onTap: _searchMessageItemOnTap(context, message));
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
      await ConversationCubit.selectConversation(
        context,
        message.conversationId,
        initIndexMessageId: message.messageId,
        keyword: context.read<KeywordCubit>().state,
      );

      _clear(context);
    };

class SearchMessageItem extends HookWidget {
  const SearchMessageItem({
    super.key,
    required this.message,
    required this.keyword,
    required this.onTap,
    this.showSender = false,
  });

  final SearchMessageDetailItem message;
  final bool showSender;
  final String keyword;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isGroup = useMemoized(
        () =>
            message.category == ConversationCategory.group ||
            message.userId != message.conversationOwnerId,
        [message.category, message.userId, message.conversationOwnerId]);

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
      final mentionCache = context.read<MentionCache>();

      return messagePreviewOptimize(
          message.status,
          message.type,
          mentionCache.replaceMention(
            message.content,
            await mentionCache.checkMentionCache({message.content}),
          ),
          message.userId == context.accountServer.userId,
          isGroup,
          message.userFullName);
    }, null, keys: [
      message.status,
      message.type,
      message.content,
      isGroup,
      message.userId,
      message.userFullName
    ]).data;

    final avatar = showSender
        ? AvatarWidget(
            userId: message.userId,
            avatarUrl: message.userAvatarUrl,
            size: ConversationPage.conversationItemAvatarSize,
            name: message.userFullName,
          )
        : ConversationAvatarWidget(
            conversationId: message.conversationId,
            fullName: conversationValidName(
              message.groupName,
              message.userFullName,
            ),
            groupIconUrl: message.groupIconUrl,
            avatarUrl: message.userAvatarUrl,
            category: message.category,
            size: ConversationPage.conversationItemAvatarSize,
            userId: message.userId,
          );
    return SearchItem(
      avatar: avatar,
      name: showSender
          ? message.userFullName ?? ''
          : conversationValidName(
              message.groupName,
              message.userFullName,
            ),
      trailing: VerifiedOrBotWidget(
        verified: message.verified,
        isBot: message.appId != null,
      ),
      nameHighlight: false,
      keyword: keyword,
      descriptionIcon: icon,
      description: description,
      date: message.createdAt,
      onTap: onTap,
    );
  }
}

class _SearchEmpty extends StatelessWidget {
  const _SearchEmpty();

  @override
  Widget build(BuildContext context) => Container(
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
                context.read<ConversationFilterUnseenCubit>().reset();
              },
            ),
          ],
        ),
      );
}

class _UnseenConversationList extends HookWidget {
  const _UnseenConversationList();

  @override
  Widget build(BuildContext context) {
    final unreadConversations = useState(<ConversationItem>[]);

    final currentConversationId =
        useBlocStateConverter<ConversationCubit, ConversationState?, String?>(
      converter: (state) => state?.conversationId,
    );

    useEffect(() {
      final subscription = context.accountServer.database.conversationDao
          .filterConversationByUnseen()
          .watchThrottle(kSlowThrottleDuration)
          .asyncListen((items) async {
        final oldItems = unreadConversations.value;

        final newItems = List<ConversationItem>.from(items);
        final newItemIdsSet = items.map((e) => e.conversationId).toSet();

        for (final oldItem in oldItems) {
          if (!newItemIdsSet.contains(oldItem.conversationId)) {
            final item = await context.database.conversationDao
                .conversationItem(oldItem.conversationId)
                .getSingleOrNull();
            assert(item != null, 'Conversation not found');
            if (item != null) {
              newItems.add(item);
            }
          }
        }
        unreadConversations.value = newItems;
      });
      return subscription.cancel;
    }, const []);

    final conversationItems = unreadConversations.value;

    final routeMode = useBlocStateConverter<ResponsiveNavigatorCubit,
        ResponsiveNavigatorState, bool>(
      converter: (state) => state.routeMode,
    );

    final itemScrollController = useMemoized(ItemScrollController.new);
    final itemPositionsListener = useMemoized(ItemPositionsListener.create);

    useEffect(() {
      final index = conversationItems.indexWhere(
        (element) => element.conversationId == currentConversationId,
      );
      if (index == -1) {
        return;
      }

      // use 0.9 instead 1 to ensure that the next conversation is visible if we forward.
      // in forward navigation, if alignment is 1, ScrollablePositionedList will only
      // show current conversation at the end, not the next one.
      const trailingEdge = 0.9;

      for (final position in itemPositionsListener.itemPositions.value) {
        if (position.index == index) {
          if (position.itemLeadingEdge > 0 &&
              position.itemTrailingEdge < trailingEdge) {
            // in viewport, do not need scroll.
            // https://github.com/google/flutter.widgets/issues/276
            return;
          }
          break;
        }
      }
      itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 200),
      );
    }, [conversationItems, currentConversationId]);

    if (conversationItems.isEmpty) {
      return const _SearchEmpty();
    }
    return ScrollablePositionedList.builder(
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      itemBuilder: (context, index) {
        final conversation = conversationItems[index];
        return ConversationMenuWrapper(
          conversation: conversation,
          removeChatFromCircle: true,
          child: ConversationItemWidget(
            conversation: conversation,
            selected: conversation.conversationId == currentConversationId &&
                !routeMode,
            onTap: () {
              _clear(context);
              ConversationCubit.selectConversation(
                  context, conversation.conversationId,
                  conversation: conversation);
            },
          ),
        );
      },
      itemCount: conversationItems.length,
    );
  }
}
