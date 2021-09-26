import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:tuple/tuple.dart';

import '../../blaze/vo/pin_message_minimal.dart';
import '../../bloc/bloc_converter.dart';
import '../../bloc/keyword_cubit.dart';
import '../../bloc/minute_timer_cubit.dart';
import '../../bloc/paging/paging_bloc.dart';
import '../../constants/resources.dart';
import '../../db/extension/conversation.dart';
import '../../db/mixin_database.dart';
import '../../enum/message_category.dart';
import '../../generated/l10n.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/message_optimize.dart';
import '../../widgets/avatar_view/avatar_view.dart';
import '../../widgets/dialog.dart';
import '../../widgets/high_light_text.dart';
import '../../widgets/interactive_decorated_box.dart';
import '../../widgets/menu.dart';
import '../../widgets/message/item/pin_message.dart';
import '../../widgets/message/item/system_message.dart';
import '../../widgets/message/item/text/mention_builder.dart';
import '../../widgets/message_status_icon.dart';
import '../../widgets/radio.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/toast.dart';
import '../../widgets/unread_text.dart';
import 'bloc/conversation_cubit.dart';
import 'bloc/conversation_list_bloc.dart';
import 'bloc/slide_category_cubit.dart';
import 'route/responsive_navigator_cubit.dart';

const _defaultLimit = 3;

void _clear(BuildContext context) {
  context.read<KeywordCubit>().emit('');
  context.read<TextEditingController>().text = '';
  context.read<FocusNode>().unfocus();
}

class ConversationPage extends HookWidget {
  const ConversationPage({Key? key}) : super(key: key);

  static const conversationItemHeight = 78.0;
  static const conversationItemAvatarSize = 50.0;

  @override
  Widget build(BuildContext context) {
    final hasKeyword =
        useBlocState<KeywordCubit, String>(bloc: context.read<KeywordCubit>())
            .trim()
            .isNotEmpty;

    final textEditingController = useTextEditingController();
    final focusNode = useFocusNode();

    final slideCategoryState =
        useBlocState<SlideCategoryCubit, SlideCategoryState>(
      when: (state) => state.type != SlideCategoryType.setting,
      keys: [key],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TextEditingController>.value(
          value: textEditingController,
        ),
        ChangeNotifierProvider<FocusNode>.value(
          value: focusNode,
        ),
      ],
      child: Column(
        children: [
          const SearchBar(),
          if (!hasKeyword)
            Expanded(
              child: _List(
                key: PageStorageKey(slideCategoryState),
              ),
            ),
          if (hasKeyword)
            const Expanded(
              child: _SearchList(),
            ),
        ],
      ),
    );
  }
}

enum _ShowMoreType {
  contact,
  conversation,
  message,
}

class _SearchList extends HookWidget {
  const _SearchList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final keyword = useMemoizedStream(
          () => context.read<KeywordCubit>().stream.throttleTime(
                const Duration(milliseconds: 100),
                trailing: true,
                leading: false,
              ),
          initialData: context.read<KeywordCubit>().state,
        ).data ??
        '';

    final accountServer = context.accountServer;

    final users = useMemoizedStream(() {
          if (keyword.trim().isEmpty) return Stream.value(<User>[]);
          return accountServer.database.userDao
              .fuzzySearchUser(
                  id: accountServer.userId,
                  username: keyword,
                  identityNumber: keyword)
              .watch();
        }, keys: [keyword]).data ??
        [];

    final messages = useMemoizedStream(() {
          if (keyword.trim().isEmpty) {
            return Stream.value(<SearchMessageDetailItem>[]);
          } else {
            return accountServer.database.messageDao
                .fuzzySearchMessage(query: keyword, limit: 4)
                .watch();
          }
        }, keys: [keyword]).data ??
        [];

    final conversations = useMemoizedStream(() {
          if (keyword.trim().isEmpty) {
            return Stream.value(<SearchConversationItem>[]);
          }
          return accountServer.database.conversationDao
              .fuzzySearchConversation(keyword)
              .watch();
        }, keys: [keyword]).data ??
        [];

    final type = useState<_ShowMoreType?>(null);

    if (users.isEmpty && conversations.isEmpty && messages.isEmpty) {
      return const SearchEmpty();
    }

    if (type.value == _ShowMoreType.message) {
      return _SearchMessageList(
        keyword: keyword,
        onTap: () => type.value = null,
      );
    }
    return CustomScrollView(
      slivers: [
        if (users.isNotEmpty)
          SliverToBoxAdapter(
            child: _SearchHeader(
              title: context.l10n.contact,
              showMore: users.length > _defaultLimit,
              more: type.value != _ShowMoreType.contact,
              onTap: () {
                if (type.value != _ShowMoreType.contact) {
                  type.value = _ShowMoreType.contact;
                } else {
                  type.value = null;
                }
              },
            ),
          ),
        if (users.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final user = users[index];
                return _SearchItem(
                  avatar: AvatarWidget(
                    name: user.fullName ?? '?',
                    userId: user.userId,
                    size: ConversationPage.conversationItemAvatarSize,
                    avatarUrl: user.avatarUrl,
                  ),
                  name: user.fullName ?? '?',
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
              title: context.l10n.conversations,
              showMore: conversations.length > _defaultLimit,
              more: type.value != _ShowMoreType.conversation,
              onTap: () {
                if (type.value != _ShowMoreType.conversation) {
                  type.value = _ShowMoreType.conversation;
                } else {
                  type.value = null;
                }
              },
            ),
          ),
        if (conversations.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final conversation = conversations[index];
                return _ConversationMenuWrapper(
                  searchConversation: conversation,
                  child: _SearchItem(
                    avatar: ConversationAvatarWidget(
                      conversationId: conversation.conversationId,
                      fullName: conversationValidName(
                        conversation.groupName,
                        conversation.fullName,
                      ),
                      groupIconUrl: conversation.groupIconUrl,
                      avatarUrl: conversation.avatarUrl,
                      category: conversation.category,
                      size: ConversationPage.conversationItemAvatarSize,
                    ),
                    name: conversationValidName(
                      conversation.groupName,
                      conversation.fullName,
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
                if (type.value != _ShowMoreType.message) {
                  type.value = _ShowMoreType.message;
                } else {
                  type.value = null;
                }
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

Future Function() _searchMessageItemOnTap(
        BuildContext context, SearchMessageDetailItem message) =>
    () async {
      await ConversationCubit.selectConversation(
        context,
        message.conversationId,
        initIndexMessageId: message.messageId,
      );

      _clear(context);
    };

class SearchMessageItem extends StatelessWidget {
  const SearchMessageItem({
    Key? key,
    required this.message,
    required this.keyword,
    required this.onTap,
    this.showSender = false,
  }) : super(key: key);

  final SearchMessageDetailItem message;
  final bool showSender;
  final String keyword;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    String? icon;
    late String description;
    if (message.type == MessageCategory.signalData ||
        message.type == MessageCategory.plainData) {
      icon = Resources.assetsImagesFileSvg;
      description = message.mediaName!;
    } else if (message.type == MessageCategory.signalContact ||
        message.type == MessageCategory.plainContact) {
      icon = Resources.assetsImagesContactSvg;
      description = message.mediaName!;
    } else {
      // todo content should not be null.
      description = message.content ?? '';
    }

    final avatar = showSender
        ? AvatarWidget(
            userId: message.userId,
            avatarUrl: message.userAvatarUrl,
            size: ConversationPage.conversationItemAvatarSize,
            name: message.userFullName ?? '',
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
          );
    return _SearchItem(
      avatar: avatar,
      name: showSender
          ? message.userFullName ?? ''
          : conversationValidName(
              message.groupName,
              message.userFullName,
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

class SearchEmpty extends StatelessWidget {
  const SearchEmpty({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 43,
          vertical: 86,
        ),
        width: double.infinity,
        alignment: Alignment.topCenter,
        child: Text(
          context.l10n.searchEmpty,
          style: TextStyle(
            fontSize: 14,
            color: context.theme.secondaryText,
          ),
        ),
      );
}

class _SearchMessageList extends HookWidget {
  const _SearchMessageList({
    Key? key,
    required this.keyword,
    required this.onTap,
  }) : super(key: key);

  final String keyword;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final searchMessageBloc =
        useBloc<AnonymousPagingBloc<SearchMessageDetailItem>>(
      () => AnonymousPagingBloc<SearchMessageDetailItem>(
        initState: const PagingState<SearchMessageDetailItem>(),
        limit: context.read<ConversationListBloc>().limit,
        queryCount: () => context.database.messageDao
            .fuzzySearchMessageCount(keyword)
            .getSingle(),
        queryRange: (int limit, int offset) async {
          if (keyword.isEmpty) return [];
          return context.database.messageDao
              .fuzzySearchMessage(query: keyword, limit: limit, offset: offset)
              .get();
        },
      ),
      keys: [keyword],
    );
    useEffect(
      () => context.database.messageDao.searchMessageUpdateEvent
          .listen((event) => searchMessageBloc.add(PagingUpdateEvent()))
          .cancel,
      [keyword],
    );
    final pageState = useBlocState<PagingBloc<SearchMessageDetailItem>,
        PagingState<SearchMessageDetailItem>>(bloc: searchMessageBloc);

    late Widget child;
    if (pageState.count <= 0) {
      child = const SearchEmpty();
    } else {
      child = ScrollablePositionedList.builder(
        itemPositionsListener: searchMessageBloc.itemPositionsListener,
        itemCount: pageState.count,
        itemBuilder: (context, index) {
          final message = pageState.map[index];
          if (message == null) {
            return const SizedBox(
              height: ConversationPage.conversationItemHeight,
            );
          }
          return SearchMessageItem(
            message: message,
            keyword: keyword,
            onTap: _searchMessageItemOnTap(context, message),
          );
        },
      );
    }

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

class _SearchItem extends StatelessWidget {
  const _SearchItem({
    Key? key,
    required this.avatar,
    required this.name,
    required this.keyword,
    this.nameHighlight = true,
    required this.onTap,
    this.description,
    this.descriptionIcon,
    this.date,
  }) : super(key: key);

  final Widget avatar;
  final String name;
  final String keyword;
  final bool nameHighlight;
  final VoidCallback onTap;
  final String? description;
  final String? descriptionIcon;
  final DateTime? date;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 72,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          child: Row(
            children: [
              SizedBox(
                height: ConversationPage.conversationItemAvatarSize,
                width: ConversationPage.conversationItemAvatarSize,
                child: avatar,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: HighlightText(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                            SvgPicture.asset(
                              descriptionIcon!,
                              color: context.theme.secondaryText,
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
      );
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    Key? key,
    required this.title,
    required this.showMore,
    required this.onTap,
    required this.more,
  }) : super(key: key);

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
          Resources.assetsImagesConversationEmptySvg,
          height: 78,
          width: 58,
          color: dynamicColor,
        ),
        const SizedBox(height: 24),
        Text(
          Localization.current.noData,
          style: TextStyle(
            color: dynamicColor,
            fontSize: 14,
          ),
        ),
      ]),
    );
  }
}

class _List extends HookWidget {
  const _List({
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

    final connectedState = useStream(
          context.accountServer.blaze.connectedStateStreamController.stream
              .distinct(),
          initialData: true,
        ).data ??
        false;

    Widget child;
    if (pagingState.count == 0) {
      if (pagingState.hasData) {
        child = Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(
              context.theme.accent,
            ),
          ),
        );
      } else {
        child = const _Empty();
      }
    } else {
      child = ScrollablePositionedList.builder(
        key: PageStorageKey(slideCategoryState),
        itemPositionsListener:
            conversationListBloc.itemPositionsListener(slideCategoryState),
        itemCount: pagingState.count,
        itemBuilder: (context, index) {
          final conversation = pagingState.map[index];
          if (conversation == null) return const SizedBox(height: 80);
          final selected =
              conversation.conversationId == conversationId && !routeMode;

          return _ConversationMenuWrapper(
            conversation: conversation,
            child: _Item(
              selected: selected,
              conversation: conversation,
              onTap: () {
                ConversationCubit.selectConversation(
                  context,
                  conversation.conversationId,
                  conversation: conversation,
                );
              },
            ),
          );
        },
      );
    }

    return Column(
      children: [
        _NetworkNotConnect(visible: !connectedState),
        Expanded(
          child: child,
        ),
      ],
    );
  }
}

class _ConversationMenuWrapper extends StatelessWidget {
  const _ConversationMenuWrapper({
    Key? key,
    this.conversation,
    this.searchConversation,
    required this.child,
  }) : super(key: key);

  final ConversationItem? conversation;
  final SearchConversationItem? searchConversation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(conversation != null || searchConversation != null);

    final conversationId =
        conversation?.conversationId ?? searchConversation!.conversationId;
    final ownerId = conversation?.ownerId ?? searchConversation!.ownerId;
    final pinTime = conversation?.pinTime ?? searchConversation?.pinTime;
    final isMute = conversation?.isMute ?? searchConversation!.isMute;
    final isGroupConversation = conversation?.isGroupConversation ??
        searchConversation!.isGroupConversation;

    return ContextMenuPortalEntry(
      buildMenus: () => [
        if (pinTime != null)
          ContextMenu(
            title: Localization.current.unPin,
            onTap: () => runFutureWithToast(
              context,
              context.accountServer.unpin(conversationId),
            ),
          ),
        if (pinTime == null)
          ContextMenu(
            title: Localization.current.pin,
            onTap: () => runFutureWithToast(
              context,
              context.accountServer.pin(conversationId),
            ),
          ),
        if (isMute)
          ContextMenu(
            title: Localization.current.unMute,
            onTap: () async {
              await runFutureWithToast(
                context,
                context.accountServer.unMuteConversation(
                  conversationId: isGroupConversation ? conversationId : null,
                  userId: isGroupConversation ? null : ownerId,
                ),
              );
              return;
            },
          )
        else
          ContextMenu(
            title: Localization.current.muted,
            onTap: () async {
              final result = await showMixinDialog<int?>(
                  context: context, child: const MuteDialog());
              if (result == null) return;
              await runFutureWithToast(
                context,
                context.accountServer.muteConversation(
                  result,
                  conversationId: isGroupConversation ? conversationId : null,
                  userId: isGroupConversation ? null : ownerId,
                ),
              );
              return;
            },
          ),
        ContextMenu(
          title: Localization.current.deleteChat,
          isDestructiveAction: true,
          onTap: () async {
            await context.database.conversationDao
                .deleteConversation(conversationId);
            await context.database.pinMessageDao
                .deleteByConversationId(conversationId);
            if (context.read<ConversationCubit>().state?.conversationId ==
                conversationId) {
              context.read<ConversationCubit>().unselected();
            }
          },
        ),
      ],
      child: child,
    );
  }
}

class MuteDialog extends HookWidget {
  const MuteDialog({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final result = useState<int?>(null);
    return AlertDialogLayout(
      title: Text(context.l10n.muteTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tuple2(context.l10n.mute1hour, 1 * 60 * 60),
            Tuple2(context.l10n.mute8hours, 8 * 60 * 60),
            Tuple2(context.l10n.mute1week, 7 * 24 * 60 * 60),
            Tuple2(context.l10n.mute1year, 365 * 24 * 60 * 60),
          ]
              .map(
                (e) => RadioItem<int>(
                  title: Text(e.item1),
                  groupValue: result.value,
                  value: e.item2,
                  onChanged: (int? value) => result.value = value,
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        MixinButton(
            backgroundTransparent: true,
            onTap: () => Navigator.pop(context),
            child: Text(context.l10n.cancel)),
        MixinButton(
          onTap: () => Navigator.pop(context, result.value),
          child: Text(context.l10n.confirm),
        ),
      ],
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
                    borderRadius: BorderRadius.circular(8),
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

class VerifiedOrBotWidget extends StatelessWidget {
  const VerifiedOrBotWidget({
    Key? key,
    required this.verified,
    required this.isBot,
  }) : super(key: key);
  final bool? verified;
  final bool isBot;

  @override
  Widget build(BuildContext context) {
    final _verified = verified ?? false;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_verified || isBot) const SizedBox(width: 4),
        if (_verified)
          SvgPicture.asset(
            Resources.assetsImagesVerifiedSvg,
            width: 12,
            height: 12,
          )
        else if (isBot)
          SvgPicture.asset(
            Resources.assetsImagesBotFillSvg,
            width: 12,
            height: 12,
          ),
        if (_verified || isBot) const SizedBox(width: 4),
      ],
    );
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
            participantIsCurrentUser:
                conversation.participantUserId == context.accountServer.userId,
            relationship: conversation.relationship,
            participantFullName: conversation.participantFullName,
            senderFullName: conversation.senderFullName,
            groupName: conversation.groupName,
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
                height: 1,
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
        !conversation.contentType.isGroupCall) {
      return MessageStatusIcon(
        status: conversation.messageStatus,
      );
    }
    return const SizedBox();
  }
}

class _NetworkNotConnect extends StatelessWidget {
  const _NetworkNotConnect({
    Key? key,
    required this.visible,
  }) : super(key: key);

  final bool visible;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (visible) {
      child = Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
        color: context.theme.warning.withOpacity(0.2),
        child: Row(
          children: [
            ClipOval(
              child: Container(
                color: context.theme.warning,
                width: 20,
                height: 20,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 2,
                  height: 10,
                  child: SvgPicture.asset(
                    Resources.assetsImagesExclamationMarkSvg,
                    color: Colors.white,
                    width: 2,
                    height: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              context.l10n.networkConnectionFailed,
              style: TextStyle(
                color: context.theme.text,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    } else {
      child = const SizedBox();
    }

    return AnimatedSize(
      alignment: Alignment.topCenter,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 200),
      child: child,
    );
  }
}
