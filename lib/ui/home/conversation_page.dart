import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:tuple/tuple.dart';

import '../../account/account_server.dart';
import '../../bloc/bloc_converter.dart';
import '../../bloc/keyword_cubit.dart';
import '../../bloc/minute_timer_cubit.dart';
import '../../bloc/paging/paging_bloc.dart';
import '../../constants/resources.dart';
import '../../db/extension/conversation.dart';
import '../../db/extension/message_category.dart';
import '../../db/mixin_database.dart';
import '../../enum/message_category.dart';
import '../../generated/l10n.dart';
import '../../utils/datetime_format_utils.dart';
import '../../utils/hook.dart';
import '../../utils/list_utils.dart';
import '../../utils/message_optimize.dart';
import '../../widgets/avatar_view/avatar_view.dart';
import '../../widgets/brightness_observer.dart';
import '../../widgets/dialog.dart';
import '../../widgets/high_light_text.dart';
import '../../widgets/interacter_decorated_box.dart';
import '../../widgets/menu.dart';
import '../../widgets/message/item/system_message.dart';
import '../../widgets/message/item/text/mention_builder.dart';
import '../../widgets/message_status_icon.dart';
import '../../widgets/radio.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/toast.dart';
import '../../widgets/unread_text.dart';
import 'bloc/conversation_cubit.dart';
import 'bloc/conversation_list_bloc.dart';
import 'bloc/multi_auth_cubit.dart';
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
      child: ColoredBox(
        color: BrightnessData.themeOf(context).background,
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
    final keyword =
        useBlocState<KeywordCubit, String>(bloc: context.read<KeywordCubit>());
    final accountServer = context.read<AccountServer>();

    final users = useStream<List<User>>(
            useMemoized(
                () => accountServer.database.userDao
                    .fuzzySearchUser(
                        id: accountServer.userId,
                        username: keyword,
                        identityNumber: keyword)
                    .watch(),
                [keyword]),
            initialData: []).data ??
        [];

    final messages = useStream<List<SearchMessageDetailItem>>(
            useMemoized(() async* {
              if (keyword.trim().isEmpty) {
                yield [];
              } else {
                yield* accountServer.database.messagesDao
                    .fuzzySearchMessage(query: keyword, limit: 4)
                    .watch();
              }
            }, [keyword]),
            initialData: []).data ??
        [];

    final conversations = useStream<List<SearchConversationItem>>(
            useMemoized(
                () => accountServer.database.conversationDao
                    .fuzzySearchConversation(keyword)
                    .watch(),
                [keyword]),
            initialData: []).data ??
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
              title: Localization.of(context).contact,
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
                    size: 50,
                    avatarUrl: user.avatarUrl,
                  ),
                  name: user.fullName ?? '?',
                  keyword: keyword,
                  onTap: () async {
                    context.read<ConversationCubit>().selectUser(
                          user.userId,
                          user.appId?.isEmpty ?? true,
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
              title: Localization.of(context).group,
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
                return _SearchItem(
                  avatar: ConversationAvatarWidget(
                    conversationId: conversation.conversationId,
                    fullName: conversationValidName(
                      conversation.groupName,
                      conversation.fullName,
                    ),
                    groupIconUrl: conversation.groupIconUrl,
                    avatarUrl: conversation.avatarUrl,
                    category: conversation.category,
                    size: 50,
                  ),
                  name: conversationValidName(
                    conversation.groupName,
                    conversation.fullName,
                  ),
                  keyword: keyword,
                  onTap: () async {
                    context
                        .read<ConversationCubit>()
                        .selectConversation(conversation.conversationId);

                    _clear(context);
                  },
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
              title: Localization.of(context).messages,
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
      context.read<ConversationCubit>().selectConversation(
            message.conversationId,
            message.messageId,
          );

      _clear(context);
    };

class SearchMessageItem extends StatelessWidget {
  const SearchMessageItem({
    Key? key,
    required this.message,
    required this.keyword,
    required this.onTap,
  }) : super(key: key);

  final SearchMessageDetailItem message;
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

    return _SearchItem(
      avatar: ConversationAvatarWidget(
        conversationId: message.conversationId,
        fullName: conversationValidName(
          message.groupName,
          message.userFullName,
        ),
        groupIconUrl: message.groupIconUrl,
        avatarUrl: message.userAvatarUrl,
        category: message.category,
        size: 50,
      ),
      name: conversationValidName(
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
        color: BrightnessData.themeOf(context).primary,
        alignment: Alignment.topCenter,
        child: Text(
          Localization.of(context).searchEmpty,
          style: TextStyle(
            fontSize: 14,
            color: BrightnessData.themeOf(context).secondaryText,
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
        queryCount: () => context
            .read<AccountServer>()
            .database
            .messagesDao
            .fuzzySearchMessageCount(keyword)
            .getSingle(),
        queryRange: (int limit, int offset) async {
          if (keyword.isEmpty) return [];
          return context
              .read<AccountServer>()
              .database
              .messagesDao
              .fuzzySearchMessage(query: keyword, limit: limit, offset: offset)
              .get();
        },
      ),
      keys: [keyword],
    );
    useEffect(
      () => context
          .read<AccountServer>()
          .database
          .messagesDao
          .searchMessageUpdateEvent
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
          if (message == null) return const SizedBox(height: 80);
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
          title: Localization.of(context).messages,
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
          height: 80,
          width: double.infinity,
          color: BrightnessData.themeOf(context).primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          child: Row(
            children: [
              SizedBox(
                height: 50,
                width: 50,
                child: avatar,
              ),
              const SizedBox(width: 10),
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
                              color: BrightnessData.themeOf(context).text,
                              fontSize: 16,
                            ),
                            highlightTextSpans: [
                              if (nameHighlight)
                                HighlightTextSpan(
                                  keyword,
                                  style: TextStyle(
                                    color:
                                        BrightnessData.themeOf(context).accent,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (date != null)
                          BlocConverter<MinuteTimerCubit, DateTime, String>(
                            converter: (_) => convertStringTime(date!),
                            builder: (context, text) => Text(
                              text,
                              style: TextStyle(
                                color: BrightnessData.themeOf(context)
                                    .secondaryText,
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
                              color:
                                  BrightnessData.themeOf(context).secondaryText,
                            ),
                          Expanded(
                            child: HighlightText(
                              description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: BrightnessData.themeOf(context).text,
                                fontSize: 14,
                              ),
                              highlightTextSpans: [
                                HighlightTextSpan(
                                  keyword,
                                  style: TextStyle(
                                    color:
                                        BrightnessData.themeOf(context).accent,
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
        color: BrightnessData.themeOf(context).primary,
        padding: const EdgeInsets.only(
          top: 16,
          bottom: 10,
          right: 20,
          left: 20,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: BrightnessData.themeOf(context).text,
              ),
            ),
            if (showMore)
              GestureDetector(
                onTap: onTap,
                child: Text(
                  more
                      ? Localization.of(context).more
                      : Localization.of(context).less,
                  style: TextStyle(
                    fontSize: 14,
                    color: BrightnessData.themeOf(context).accent,
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
    final dynamicColor = BrightnessData.dynamicColor(
      context,
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

    final navigationMode = useBlocStateConverter<ResponsiveNavigatorCubit,
        ResponsiveNavigatorState, bool>(
      converter: (state) => state.navigationMode,
    );

    final connectedState = useStream(
          context
              .read<AccountServer>()
              .blaze
              .connectedStateStreamController
              .stream
              .debounceTime(const Duration(milliseconds: 500)),
          initialData: true,
        ).data ??
        false;

    Widget child;
    if (pagingState.count <= 0) {
      child = const _Empty();
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
              conversation.conversationId == conversationId && !navigationMode;

          return ContextMenuPortalEntry(
            buildMenus: () => [
              if (conversation.pinTime != null)
                ContextMenu(
                  title: Localization.current.unPin,
                  onTap: () => runFutureWithToast(
                    context,
                    context
                        .read<AccountServer>()
                        .unpin(conversation.conversationId),
                  ),
                ),
              if (conversation.pinTime == null)
                ContextMenu(
                  title: Localization.current.pin,
                  onTap: () => runFutureWithToast(
                    context,
                    context
                        .read<AccountServer>()
                        .pin(conversation.conversationId),
                  ),
                ),
              if (conversation.isMute)
                ContextMenu(
                  title: Localization.current.unMute,
                  onTap: () async {
                    final isGroupConversation =
                        conversation.isGroupConversation;
                    return runFutureWithToast(
                      context,
                      context.read<AccountServer>().unMuteConversation(
                            conversationId: isGroupConversation
                                ? conversation.conversationId
                                : null,
                            userId: isGroupConversation
                                ? null
                                : conversation.ownerId,
                          ),
                    );
                  },
                )
              else
                ContextMenu(
                  title: Localization.current.muted,
                  onTap: () async {
                    final result = await showMixinDialog<int?>(
                        context: context, child: const MuteDialog());
                    if (result == null) return;

                    final isGroupConversation =
                        conversation.isGroupConversation;

                    return runFutureWithToast(
                      context,
                      context.read<AccountServer>().muteConversation(
                            result,
                            conversationId: isGroupConversation
                                ? conversation.conversationId
                                : null,
                            userId: isGroupConversation
                                ? null
                                : conversation.ownerId,
                          ),
                    );
                  },
                ),
              ContextMenu(
                title: Localization.current.deleteChat,
                isDestructiveAction: true,
                onTap: () async {
                  await context
                      .read<AccountServer>()
                      .database
                      .conversationDao
                      .deleteConversation(
                        conversation.conversationId,
                      );
                  if (context.read<ConversationCubit>().state?.conversationId ==
                      conversation.conversationId) {
                    context.read<ConversationCubit>().unselected();
                  }
                },
              ),
            ],
            child: _Item(
              selected: selected,
              conversation: conversation,
              onTap: () {
                context.read<ConversationCubit>().selectConversation(
                      conversation.conversationId,
                      conversation.lastReadMessageId,
                      (conversation.unseenMessageCount ?? 0) > 0,
                    );
              },
            ),
          );
        },
      );
    }

    return ColoredBox(
      color: BrightnessData.themeOf(context).primary,
      child: Column(
        children: [
          _NetworkNotConnect(visible: !connectedState),
          Expanded(
            child: child,
          ),
        ],
      ),
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
      title: Text(Localization.of(context).muteTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tuple2(Localization.of(context).mute1hour, 1 * 60 * 60),
            Tuple2(Localization.of(context).mute8hours, 8 * 60 * 60),
            Tuple2(Localization.of(context).mute1week, 7 * 24 * 60 * 60),
            Tuple2(Localization.of(context).mute1year, 365 * 24 * 60 * 60),
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
            child: Text(Localization.of(context).cancel)),
        MixinButton(
          onTap: () => Navigator.pop(context, result.value),
          child: Text(Localization.of(context).confirm),
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
    final messageColor = BrightnessData.themeOf(context).secondaryText;
    return InteractableDecoratedBox(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: DecoratedBox(
          decoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: BrightnessData.themeOf(context).listSelected,
                )
              : const BoxDecoration(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: ConversationAvatarWidget(
                    conversation: conversation,
                    size: 50,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
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
                                        color: BrightnessData.themeOf(context)
                                            .text,
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
                              converter: (_) => convertStringTime(
                                  conversation.lastMessageCreatedAt ??
                                      conversation.createdAt),
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
                        SizedBox(
                          height: 20,
                          child: Row(
                            children: [
                              Expanded(
                                child: _MessagePreview(
                                  messageColor: messageColor,
                                  conversation: conversation,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  if (conversation.mentionCount > 0)
                                    _UnreadText(
                                      conversation: conversation,
                                      data: '@',
                                    ),
                                  if ((conversation.unseenMessageCount ?? 0) >
                                      0)
                                    _UnreadText(
                                      conversation: conversation,
                                      data:
                                          '${min(conversation.unseenMessageCount ?? 0, 99)}',
                                    ),
                                  if ((conversation.unseenMessageCount ?? 0) <=
                                      0)
                                    _StatusRow(conversation: conversation),
                                ].joinList(const SizedBox(width: 8)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
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
          ),
        if (isBot)
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
  Widget build(BuildContext context) {
    final dynamicColor = BrightnessData.dynamicColor(
      context,
      const Color.fromRGBO(229, 231, 235, 1),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.4),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (conversation.isMute)
          SvgPicture.asset(
            Resources.assetsImagesMuteSvg,
            color: dynamicColor,
          ),
        if (conversation.pinTime != null)
          SvgPicture.asset(
            Resources.assetsImagesPinSvg,
            color: dynamicColor,
          ),
      ].joinList(const SizedBox(width: 4)),
    );
  }
}

class _UnreadText extends StatelessWidget {
  const _UnreadText({
    Key? key,
    required this.conversation,
    required this.data,
  }) : super(key: key);

  final ConversationItem conversation;
  final String data;

  @override
  Widget build(BuildContext context) => UnreadText(
        data: data,
        backgroundColor: conversation.pinTime?.isAfter(DateTime.now()) == true
            ? BrightnessData.themeOf(context).accent
            : BrightnessData.themeOf(context).secondaryText,
        textColor: conversation.pinTime != null
            ? BrightnessData.dynamicColor(
                context,
                const Color.fromRGBO(255, 255, 255, 1),
                darkColor: const Color.fromRGBO(255, 255, 255, 1),
              )
            : BrightnessData.themeOf(context).primary,
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
            senderIsCurrentUser:
                conversation.senderId == context.read<AccountServer>().userId,
            relationship: conversation.relationship,
            participantFullName: conversation.participantFullName,
            senderFullName: conversation.senderFullName,
            groupName: conversation.groupName,
          );
        }

        final mentionCache = context.read<MentionCache>();

        return messagePreviewOptimize(
          conversation.messageStatus,
          conversation.contentType,
          mentionCache.replaceMention(
            conversation.content,
            await mentionCache.checkMentionCache({conversation.content}),
          ),
          conversation.senderId == context.read<AccountServer>().userId,
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
    );

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

    final dynamicColor = BrightnessData.themeOf(context).secondaryText;

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
              text,
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
    if (context.read<MultiAuthCubit>().state.current?.account.userId ==
            conversation.senderId &&
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
        color: BrightnessData.themeOf(context).warning.withOpacity(0.2),
        child: Row(
          children: [
            ClipOval(
              child: Container(
                color: BrightnessData.themeOf(context).warning,
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
              Localization.of(context).networkConnectionFailed,
              style: TextStyle(
                color: BrightnessData.themeOf(context).text,
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
