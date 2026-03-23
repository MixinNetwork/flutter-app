import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../blaze/vo/pin_message_minimal.dart';
import '../../../constants/resources.dart';
import '../../../db/dao/conversation_dao.dart';
import '../../../db/dao/message_dao.dart';
import '../../../db/database.dart';
import '../../../db/database_event_bus.dart';
import '../../../db/extension/conversation.dart';
import '../../../db/mixin_database.dart';
import '../../../enum/message_category.dart';
import '../../../utils/extension/extension.dart';
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
import '../../provider/account_server_provider.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/conversation_unseen_filter_enabled.dart';
import '../../provider/database_provider.dart';
import '../../provider/keyword_provider.dart';
import '../../provider/mention_cache_provider.dart';
import '../../provider/minute_timer_provider.dart';
import '../../provider/search_mao_user_provider.dart';
import '../../provider/slide_category_provider.dart';
import '../../provider/ui_context_providers.dart';
import '../controllers/search_message_controller.dart';
import '../providers/home_scope_providers.dart';
import 'conversation_page.dart';
import 'menu_wrapper.dart';
import 'unseen_conversation_list.dart';

const _defaultLimit = 3;

class _SearchUsersArgs with EquatableMixin {
  const _SearchUsersArgs({
    required this.database,
    required this.currentUserId,
    required this.keyword,
    required this.filterUnseen,
    required this.slideCategoryState,
  });

  final Database database;
  final String currentUserId;
  final String keyword;
  final bool filterUnseen;
  final SlideCategoryState slideCategoryState;

  @override
  List<Object?> get props => [
    database,
    currentUserId,
    keyword,
    filterUnseen,
    slideCategoryState,
  ];
}

class _SearchConversationsArgs with EquatableMixin {
  const _SearchConversationsArgs({
    required this.database,
    required this.keyword,
    required this.filterUnseen,
    required this.slideCategoryState,
  });

  final Database database;
  final String keyword;
  final bool filterUnseen;
  final SlideCategoryState slideCategoryState;

  @override
  List<Object?> get props => [
    database,
    keyword,
    filterUnseen,
    slideCategoryState,
  ];
}

class _SearchMessagesArgs with EquatableMixin {
  const _SearchMessagesArgs({
    required this.database,
    required this.keyword,
    required this.filterUnseen,
    required this.slideCategoryState,
  });

  final Database database;
  final String keyword;
  final bool filterUnseen;
  final SlideCategoryState slideCategoryState;

  @override
  List<Object?> get props => [
    database,
    keyword,
    filterUnseen,
    slideCategoryState,
  ];
}

class _SearchConversationDescriptionArgs with EquatableMixin {
  const _SearchConversationDescriptionArgs({
    required this.conversation,
    required this.currentUserId,
  });

  final SearchConversationItem conversation;
  final String currentUserId;

  @override
  List<Object?> get props => [conversation, currentUserId];
}

class _SearchMessageDescriptionArgs with EquatableMixin {
  const _SearchMessageDescriptionArgs({
    required this.message,
    required this.currentUserId,
  });

  final SearchMessageDetailItem message;
  final String currentUserId;

  @override
  List<Object?> get props => [message, currentUserId];
}

final _searchUsersProvider = StreamProvider.autoDispose
    .family<List<User>, _SearchUsersArgs>((
      ref,
      args,
    ) {
      if (args.keyword.trim().isEmpty || args.filterUnseen) {
        return Stream.value(const <User>[]);
      }
      return args.database.userDao
          .fuzzySearchUser(
            id: args.currentUserId,
            username: args.keyword,
            identityNumber: args.keyword,
            category: args.slideCategoryState,
            isIncludeConversation: true,
          )
          .watchWithStream(
            eventStreams: [
              DataBaseEventBus.instance.updateConversationIdStream,
              DataBaseEventBus.instance.updateUserIdsStream,
            ],
            duration: kSlowThrottleDuration,
          );
    });

final _searchConversationsProvider = StreamProvider.autoDispose
    .family<List<SearchConversationItem>, _SearchConversationsArgs>((
      ref,
      args,
    ) {
      if (args.keyword.trim().isEmpty) {
        return Stream.value(const <SearchConversationItem>[]);
      }
      return args.database.conversationDao
          .fuzzySearchConversation(
            args.keyword,
            32,
            filterUnseen: args.filterUnseen,
            category: args.slideCategoryState,
          )
          .watchWithStream(
            eventStreams: [
              DataBaseEventBus.instance.updateConversationIdStream,
              DataBaseEventBus.instance.updateUserIdsStream,
            ],
            duration: kSlowThrottleDuration,
          );
    });

final _searchMessagesProvider = FutureProvider.autoDispose
    .family<List<SearchMessageDetailItem>, _SearchMessagesArgs>((
      ref,
      args,
    ) async {
      if (args.keyword.isEmpty) {
        return const <SearchMessageDetailItem>[];
      }
      return args.database.fuzzySearchMessageByCategory(
        args.keyword,
        limit: 4,
        unseenConversationOnly: args.filterUnseen,
        category: args.slideCategoryState,
      );
    });

final _searchConversationDescriptionProvider = FutureProvider.autoDispose
    .family<String?, _SearchConversationDescriptionArgs>((ref, args) async {
      final conversation = args.conversation;
      final l10n = ref.watch(localizationProvider);
      final mentionCache = ref.watch(mentionCacheProvider);

      if (conversation.contentType == MessageCategory.systemConversation) {
        return generateSystemText(
          actionName: conversation.actionName,
          participantUserId: conversation.participantUserId,
          senderId: conversation.senderId,
          currentUserId: args.currentUserId,
          participantFullName: conversation.participantFullName,
          senderFullName: conversation.senderFullName,
          expireIn: int.tryParse(conversation.content ?? '0'),
        );
      }

      if (conversation.contentType.isPin) {
        final pinMessageMinimal = PinMessageMinimal.fromJsonString(
          conversation.content ?? '',
        );
        if (pinMessageMinimal == null) {
          return l10n.chatPinMessage(
            conversation.senderFullName ?? '',
            l10n.aMessage ?? '',
          );
        }
        final preview = await generatePinPreviewText(
          pinMessageMinimal: pinMessageMinimal,
          mentionCache: mentionCache,
        );
        return l10n.chatPinMessage(conversation.senderFullName ?? '', preview);
      }

      return messagePreviewOptimize(
        conversation.messageStatus,
        conversation.contentType,
        mentionCache.replaceMention(
          conversation.content,
          await mentionCache.checkMentionCache({conversation.content}),
        ),
        conversation.senderId == args.currentUserId,
        conversation.isGroupConversation,
        conversation.senderFullName,
      );
    });

final _searchMessageDescriptionProvider = FutureProvider.autoDispose
    .family<String?, _SearchMessageDescriptionArgs>((ref, args) async {
      final mentionCache = ref.watch(mentionCacheProvider);
      final message = args.message;
      final isGroup =
          message.category == ConversationCategory.group ||
          message.senderId != message.ownerId;

      return messagePreviewOptimize(
        message.status,
        message.type,
        mentionCache.replaceMention(
          message.content,
          await mentionCache.checkMentionCache({message.content}),
        ),
        message.senderId == args.currentUserId,
        isGroup,
        message.senderFullName,
      );
    });

void _clear(
  WidgetRef ref,
  TextEditingController textEditingController,
  FocusNode focusNode,
) {
  ref.read(keywordProvider.notifier).clear();
  textEditingController.text = '';
  focusNode.unfocus();
}

class SearchList extends HookConsumerWidget {
  const SearchList({
    required this.textEditingController,
    required this.focusNode,
    super.key,
    this.filterUnseen = false,
  });

  final bool filterUnseen;
  final TextEditingController textEditingController;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final keyword = ref.watch(debouncedKeywordProvider).value ?? '';
    final slideCategoryState = ref.watch(slideCategoryProvider);
    final database = ref.read(databaseProvider).requireValue;
    final accountServer = ref.read(accountServerProvider).requireValue;

    final maoUser = ref.watch(searchMaoUserProvider(keyword)).value;
    final usersArgs = _SearchUsersArgs(
      database: database,
      currentUserId: accountServer.userId,
      keyword: keyword,
      filterUnseen: filterUnseen,
      slideCategoryState: slideCategoryState,
    );
    final conversationsArgs = _SearchConversationsArgs(
      database: database,
      keyword: keyword,
      filterUnseen: filterUnseen,
      slideCategoryState: slideCategoryState,
    );
    final messagesArgs = _SearchMessagesArgs(
      database: database,
      keyword: keyword,
      filterUnseen: filterUnseen,
      slideCategoryState: slideCategoryState,
    );

    final users = ref.watch(_searchUsersProvider(usersArgs)).value ?? const [];
    final conversations =
        ref.watch(_searchConversationsProvider(conversationsArgs)).value ??
        const [];
    final messages =
        ref.watch(_searchMessagesProvider(messagesArgs)).value ?? const [];

    final isMixinNumber = useMemoized(() => numberRegExp.hasMatch(keyword), [
      keyword,
    ]);
    final isUrl = useMemoized(() {
      final uri = Uri.tryParse(keyword);
      return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    }, [keyword]);

    final type = useState<_ShowMoreType?>(null);

    final resultIsEmpty =
        maoUser == null &&
        users.isEmpty &&
        conversations.isEmpty &&
        messages.isEmpty;

    if (keyword.isEmpty && filterUnseen) {
      return const UnseenConversationList();
    }

    if (resultIsEmpty && (!isMixinNumber && !isUrl)) {
      return SearchEmptyWidget(
        onClear: () => _clear(ref, textEditingController, focusNode),
      );
    }

    if (type.value == _ShowMoreType.message) {
      return _SearchMessageList(
        keyword: keyword,
        onTap: () => type.value = null,
        filterUnseen: filterUnseen,
        categoryState: slideCategoryState,
        textEditingController: textEditingController,
        focusNode: focusNode,
      );
    }
    return CustomScrollView(
      slivers: [
        if (maoUser != null)
          SliverToBoxAdapter(
            child: _SearchMaoUserWidget(
              maoUser: maoUser,
              keyword: keyword,
              textEditingController: textEditingController,
              focusNode: focusNode,
            ),
          ),
        if (users.isEmpty && isUrl)
          SliverToBoxAdapter(
            child: SearchItemWidget(
              name: l10n.openLink(keyword),
              keyword: keyword,
              maxLines: true,
              onTap: () => openUriWithWebView(
                context,
                keyword,
                container: ref.container,
              ),
            ),
          ),
        if (users.isEmpty && isMixinNumber)
          SliverToBoxAdapter(
            child: SearchItemWidget(
              name: l10n.searchPlaceholderNumber + keyword,
              keyword: keyword,
              maxLines: true,
              onTap: () async {
                showToastLoading();

                String? userId;

                try {
                  final mixinResponse = await accountServer.client.userApi
                      .search(keyword);
                  await accountServer.upsertSdkUser(mixinResponse.data);
                  userId = mixinResponse.data.userId;
                } catch (error) {
                  showToastFailed(ToastError(l10n.userNotFound));
                }

                Toast.dismiss();

                if (userId != null) {
                  await showUserDialog(context, ref.container, userId);
                }
              },
            ),
          ),
        if (users.isNotEmpty)
          SliverToBoxAdapter(
            child: _SearchHeader(
              title: l10n.contact,
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
              (context, index) {
                final user = users[index];
                return SearchItemWidget(
                  avatar: AvatarWidget(
                    name: user.fullName,
                    userId: user.userId,
                    size: ConversationPage.conversationItemAvatarSize,
                    avatarUrl: user.avatarUrl,
                  ),
                  name: user.fullName ?? '?',
                  description: l10n.contactMixinId(user.identityNumber),
                  trailing: BadgesWidget(
                    verified: user.isVerified ?? false,
                    isBot: user.appId != null,
                    membership: user.membership,
                  ),
                  keyword: keyword,
                  onTap: () async {
                    await ConversationStateNotifier.selectUser(
                      ref.container,
                      context,
                      user.userId,
                      user: user,
                    );
                    _clear(ref, textEditingController, focusNode);
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
              title: l10n.conversation,
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
              (context, index) {
                final conversation = conversations[index];
                return _SearchConversationItem(
                  conversation: conversation,
                  keyword: keyword,
                  textEditingController: textEditingController,
                  focusNode: focusNode,
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
              title: l10n.messages,
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
              (context, index) {
                final message = messages[index];
                return SearchMessageItem(
                  message: message,
                  keyword: keyword,
                  onTap: _searchMessageItemOnTap(
                    ref,
                    context,
                    message,
                    textEditingController,
                    focusNode,
                  ),
                );
              },
              childCount: type.value == _ShowMoreType.message
                  ? messages.length
                  : min(messages.length, _defaultLimit),
            ),
          ),
        if (messages.isNotEmpty)
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
      ],
    );
  }
}

const _maoIcon =
    'https://kernel.mixin.dev/objects/fe75a8e48aeffb486df622c91bebfe4056ada7009f3151fb49e2a18340bbd615/icon';

class _SearchMaoUserWidget extends ConsumerWidget {
  const _SearchMaoUserWidget({
    required this.maoUser,
    required this.keyword,
    required this.textEditingController,
    required this.focusNode,
  });

  final MaoUser maoUser;
  final String keyword;
  final TextEditingController textEditingController;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final accountServer = ref.read(accountServerProvider).requireValue;
    final defaultInscriptionImage = SvgPicture.asset(
      Resources.assetsImagesInscriptionPlaceholderSvg,
      width: 14,
      height: 14,
    );
    Widget? openButton;
    if (maoUser.user.isBot) {
      openButton = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.accent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 12),
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        onPressed: () async {
          final app = await accountServer.findOrSyncApp(maoUser.user.appId!);
          if (app == null) {
            e('app not found: ${maoUser.user.appId}');
            showToastFailed(null);
            return;
          }
          await MixinWebView.instance.openBotWebViewWindow(
            context,
            ref.container,
            app,
          );
        },
        child: Text(l10n.open),
      );
    }
    return SearchItemWidget(
      avatar: AvatarWidget(
        name: maoUser.user.fullName,
        userId: maoUser.user.userId,
        size: ConversationPage.conversationItemAvatarSize,
        avatarUrl: maoUser.user.avatarUrl,
      ),
      name: maoUser.user.fullName ?? '?',
      description: maoUser.mao,
      trailing: BadgesWidget(
        verified: maoUser.user.isVerified ?? false,
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
        if (maoUser.user.userId == accountServer.userId) {
          _clear(ref, textEditingController, focusNode);
          await showUserDialog(context, ref.container, maoUser.user.userId);
          return;
        }
        await ConversationStateNotifier.selectUser(
          ref.container,
          context,
          maoUser.user.userId,
          user: maoUser.user,
        );
        _clear(ref, textEditingController, focusNode);
      },
    );
  }
}

class SearchItemWidget extends ConsumerWidget {
  const SearchItemWidget({
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
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final selectedDecoration = BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      color: theme.listSelected,
    );
    return Padding(
      padding: margin,
      child: InteractiveDecoratedBox(
        decoration: selected == true
            ? selectedDecoration
            : const BoxDecoration(),
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
                                  overflow: maxLines
                                      ? null
                                      : TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.text,
                                    fontSize: nameFontSize,
                                  ),
                                  textMatchers: [
                                    EmojiTextMatcher(),
                                    if (keyword.trim().isNotEmpty)
                                      MultiKeyWordTextMatcher.createKeywordMatcher(
                                        keyword: keyword,
                                        style: TextStyle(
                                          color: theme.accent,
                                        ),
                                        caseSensitive: false,
                                      ),
                                  ].whereType<TextMatcher>().toList(),
                                ),
                              ),
                              ?trailing,
                            ],
                          ),
                        ),
                        if (date != null)
                          Consumer(
                            builder: (context, ref, _) => Text(
                              ref.watch(formattedDateTimeProvider(date!)),
                              style: TextStyle(
                                color: theme.secondaryText,
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
                                  theme.secondaryText,
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
                                color: theme.secondaryText,
                                fontSize: 14,
                              ),
                              textMatchers: [
                                EmojiTextMatcher(),
                                if (keyword.trim().isNotEmpty)
                                  MultiKeyWordTextMatcher.createKeywordMatcher(
                                    keyword: keyword,
                                    style: TextStyle(
                                      color: theme.accent,
                                    ),
                                    caseSensitive: false,
                                  ),
                              ].whereType<TextMatcher>().toList(),
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
    required this.textEditingController,
    required this.focusNode,
  });

  final String keyword;
  final VoidCallback onTap;
  final bool filterUnseen;
  final SlideCategoryState categoryState;
  final TextEditingController textEditingController;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final args = SlideCategorySearchMessageArgs(
      database: ref.read(databaseProvider).requireValue,
      category: categoryState,
      keyword: keyword,
      limit: ref.read(conversationListControllerProvider.notifier).limit,
    );
    final searchMessageNotifier = ref.watch(
      slideCategorySearchMessageStateProvider(args).notifier,
    );
    final pageState = ref.watch(slideCategorySearchMessageStateProvider(args));

    final child = pageState.initializing
        ? Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(theme.accent),
            ),
          )
        : pageState.items.isEmpty
        ? SearchEmptyWidget(
            onClear: () => _clear(ref, textEditingController, focusNode),
          )
        : ScrollablePositionedList.builder(
            itemPositionsListener: searchMessageNotifier.itemPositionsListener,
            itemCount: pageState.items.length,
            itemBuilder: (context, index) {
              final message = pageState.items[index];
              return SearchMessageItem(
                message: message,
                keyword: keyword,
                onTap: _searchMessageItemOnTap(
                  ref,
                  context,
                  message,
                  textEditingController,
                  focusNode,
                ),
              );
            },
          );

    return Column(
      children: [
        _SearchHeader(
          title: l10n.messages,
          showMore: true,
          more: false,
          onTap: onTap,
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _SearchHeader extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 10, right: 20, left: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: theme.text,
            ),
          ),
          if (showMore)
            GestureDetector(
              onTap: onTap,
              child: Text(
                more ? l10n.more : l10n.less,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _ShowMoreType { contact, conversation, message }

Future Function() _searchMessageItemOnTap(
  WidgetRef ref,
  BuildContext context,
  SearchMessageDetailItem message,
  TextEditingController textEditingController,
  FocusNode focusNode,
) => () async {
  await ConversationStateNotifier.selectConversation(
    ref.container,
    context,
    message.conversationId,
    initIndexMessageId: message.messageId,
    keyword: ref.read(trimmedKeywordProvider),
  );

  _clear(ref, textEditingController, focusNode);
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
    final icon = messagePreviewIcon(message.status, message.type);
    final description = ref
        .watch(
          _searchMessageDescriptionProvider(
            _SearchMessageDescriptionArgs(
              message: message,
              currentUserId: ref
                  .read(accountServerProvider)
                  .requireValue
                  .userId,
            ),
          ),
        )
        .value;

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
    return SearchItemWidget(
      avatar: avatar,
      name: showSender
          ? message.senderFullName ?? ''
          : conversationValidName(message.groupName, message.ownerFullName),
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

class _SearchConversationItem extends ConsumerWidget {
  const _SearchConversationItem({
    required this.conversation,
    required this.keyword,
    required this.textEditingController,
    required this.focusNode,
  });

  final SearchConversationItem conversation;
  final String keyword;
  final TextEditingController textEditingController;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final description = ref
        .watch(
          _searchConversationDescriptionProvider(
            _SearchConversationDescriptionArgs(
              conversation: conversation,
              currentUserId: ref
                  .read(accountServerProvider)
                  .requireValue
                  .userId,
            ),
          ),
        )
        .value;

    return ConversationMenuWrapper(
      searchConversation: conversation,
      child: SearchItemWidget(
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
            ref.container,
            context,
            conversation.conversationId,
          );
          _clear(ref, textEditingController, focusNode);
        },
      ),
    );
  }
}

class SearchEmptyWidget extends HookConsumerWidget {
  const SearchEmptyWidget({
    required this.onClear,
    super.key,
  });

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 43, vertical: 86),
      width: double.infinity,
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          Text(
            l10n.searchEmpty,
            style: TextStyle(
              fontSize: 14,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            child: Text(
              l10n.clearFilter,
              style: TextStyle(
                fontSize: 14,
                color: theme.accent,
              ),
            ),
            onPressed: () {
              onClear();
              ref
                  .read(conversationUnseenFilterEnabledProvider.notifier)
                  .reset();
            },
          ),
        ],
      ),
    );
  }
}
