import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rxdart/rxdart.dart' hide ThrottleExtensions;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../constants/resources.dart';
import '../../../db/database_event_bus.dart';
import '../../../db/mixin_database.dart';
import '../../../enum/message_category.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/system/text_input.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/conversation/badges_widget.dart';
import '../../../widgets/high_light_text.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/search_text_field.dart';
import '../../provider/conversation_provider.dart';
import '../bloc/blink_cubit.dart';
import '../bloc/conversation_list_bloc.dart';
import '../bloc/search_message_cubit.dart';
import '../chat/chat_page.dart';
import '../conversation/search_list.dart';

class SearchMessagePage extends HookConsumerWidget {
  const SearchMessagePage(this.conversationState, {super.key});

  final ConversationState conversationState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = useMemoized(
      () => [
        _Category(context.l10n.text, const [
          MessageCategory.plainText,
          MessageCategory.signalText,
          MessageCategory.encryptedText,
        ]),
        _Category(context.l10n.post, const [
          MessageCategory.plainPost,
          MessageCategory.signalPost,
          MessageCategory.encryptedPost,
        ]),
      ],
    );

    final selectedCategories = useState<List<String>?>(null);

    final focusNode = useFocusNode();
    final editingController = useMemoized(EmojiTextEditingController.new);
    final userMode = useState(false);
    final selectedUser = useState<User?>(null);

    final keywordStream = useValueNotifierConvertSteam(editingController);
    final keywordIsEmpty =
        useMemoizedStream(
          () => keywordStream.map((event) => event.text.isEmpty).distinct(),
        ).data ??
        editingController.text.isEmpty;

    useEffect(() {
      if (keywordIsEmpty) selectedCategories.value = null;
    }, [keywordIsEmpty]);

    useEffect(() {
      if (!context.textFieldAutoGainFocus) {
        focusNode.unfocus();
        return null;
      }
      focusNode.requestFocus();
    }, [userMode.value, selectedUser.value]);

    useEffect(() {
      SearchConversationKeywordCubit.updateSelectedUser(
        context,
        selectedUser.value?.userId,
      );
    }, [selectedUser.value]);

    return Scaffold(
      backgroundColor: context.theme.primary,
      appBar: MixinAppBar(
        title: Text(context.l10n.searchConversation),
        actions: [
          if (!Navigator.of(context).canPop())
            ActionButton(
              name: Resources.assetsImagesIcCloseSvg,
              color: context.theme.icon,
              onTap: () => context.read<ChatSideCubit>().onPopPage(),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            child: Row(
              children: [
                Expanded(
                  child: FocusableActionDetector(
                    autofocus: true,
                    shortcuts: {
                      if (keywordIsEmpty &&
                          (userMode.value || selectedUser.value != null))
                        const SingleActivator(LogicalKeyboardKey.backspace):
                            const _ResetModeIntent(),
                    },
                    actions: {
                      _ResetModeIntent: CallbackAction(
                        onInvoke: (Intent intent) {
                          if (selectedUser.value != null) {
                            return selectedUser.value = null;
                          }
                          if (userMode.value) return userMode.value = false;
                        },
                      ),
                    },
                    child: SearchTextField(
                      fontSize: 16,
                      focusNode: focusNode,
                      controller: editingController,
                      hintText: context.l10n.search,
                      showClear: userMode.value,
                      leading: userMode.value
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  context.l10n.fromWithColon,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: context.theme.text,
                                  ),
                                ),
                                if (selectedUser.value != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: AvatarWidget(
                                      size: 20,
                                      name: selectedUser.value?.fullName,
                                      avatarUrl: selectedUser.value?.avatarUrl,
                                      userId: selectedUser.value?.userId,
                                    ),
                                  ),
                              ],
                            )
                          : null,
                      onTapClear: () {
                        userMode.value = false;
                        selectedUser.value = null;
                      },
                      onChanged: (keyword) {
                        if (userMode.value && selectedUser.value == null) {
                          return;
                        }
                        SearchConversationKeywordCubit.updateKeyword(
                          context,
                          keyword,
                        );
                      },
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.centerLeft,
                  child: Builder(
                    builder: (context) {
                      if (userMode.value) return const SizedBox();
                      return SizedBox(
                        height: 36,
                        child: ActionButton(
                          name: Resources.assetsImagesUserSearchSvg,
                          color: context.theme.icon,
                          onTap: () {
                            editingController.text = '';
                            userMode.value = true;
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            alignment: Alignment.bottomCenter,
            duration: const Duration(milliseconds: 200),
            child: Builder(
              builder: (context) {
                if (keywordIsEmpty ||
                    (userMode.value && selectedUser.value == null)) {
                  return const SizedBox(height: 8);
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.only(left: 16),
                    height: 32,
                    alignment: Alignment.center,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return _CategoryItem(
                          name: category.name,
                          categories: category.categories,
                          selectedCategories: selectedCategories.value,
                          onSelected: (List<String> value) {
                            if (selectedCategories.value == value) {
                              selectedCategories.value = null;
                              return;
                            }
                            selectedCategories.value = value;
                          },
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(width: 8),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: userMode.value && selectedUser.value == null
                ? _SearchParticipantList(
                    editingController: editingController,
                    onSelected: (user) {
                      editingController.text = '';
                      selectedUser.value = user;
                    },
                    conversationId: conversationState.conversationId,
                    isBot: conversationState.isBot,
                  )
                : _SearchMessageList(
                    selectedUserId: selectedUser.value?.userId,
                    categories: selectedCategories.value,
                    conversationId: conversationState.conversationId,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchMessageList extends HookConsumerWidget {
  const _SearchMessageList({
    required this.conversationId,
    this.selectedUserId,
    this.categories,
  });

  final String? selectedUserId;
  final List<String>? categories;
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (_, initKeyword) = useMemoized(
      () => context.read<SearchConversationKeywordCubit>().state,
    );
    final keyword =
        useMemoizedStream(
          () => context
              .read<SearchConversationKeywordCubit>()
              .stream
              .map((event) => event.$2.trim())
              .debounceTime(const Duration(milliseconds: 150)),
        ).data ??
        initKeyword.trim();

    final searchMessageCubit = useBloc(
      () => SearchMessageCubit.conversation(
        database: context.database,
        keyword: keyword,
        limit: context.read<ConversationListBloc>().limit,
        categories: categories,
        userId: selectedUserId,
        conversationId: conversationId,
      ),
      keys: [keyword, categories, selectedUserId, conversationId],
    );

    final pageState = useBlocState<SearchMessageCubit, SearchMessageState>(
      bloc: searchMessageCubit,
    );

    return ScrollablePositionedList.builder(
      itemPositionsListener: searchMessageCubit.itemPositionsListener,
      itemCount: pageState.items.length,
      itemBuilder: (context, index) {
        final message = pageState.items[index];
        return SearchMessageItem(
          message: message,
          keyword: keyword,
          showSender: true,
          onTap: () {
            ConversationStateNotifier.selectConversation(
              context,
              message.conversationId,
              initIndexMessageId: message.messageId,
            );
            context.read<BlinkCubit>().blinkByMessageId(message.messageId);
            final chatSideCubit = context.read<ChatSideCubit>();
            if (chatSideCubit.state.routeMode) {
              chatSideCubit.clear();
            }
          },
        );
      },
    );
  }
}

class _SearchParticipantList extends HookConsumerWidget {
  const _SearchParticipantList({
    required this.onSelected,
    required this.editingController,
    required this.conversationId,
    required this.isBot,
  });

  final ValueChanged<User> onSelected;
  final TextEditingController editingController;
  final String conversationId;
  final bool isBot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keywordStream = useValueNotifierConvertSteam(editingController);

    final filteredUser =
        useMemoizedStream(
          () => keywordStream
              .throttleTime(const Duration(milliseconds: 100))
              .map((event) => event.text)
              .switchMap((value) {
                final userDao = context.database.userDao;

                if (isBot) {
                  return value.isEmpty
                      ? userDao.friends().watchWithStream(
                          eventStreams: [
                            DataBaseEventBus.instance.updateUserIdsStream,
                          ],
                          duration: kSlowThrottleDuration,
                        )
                      : userDao
                            .fuzzySearchBotGroupUser(
                              currentUserId:
                                  context
                                      .multiAuthChangeNotifier
                                      .current
                                      ?.userId ??
                                  '',
                              conversationId: conversationId,
                              keyword: value,
                            )
                            .watchWithStream(
                              eventStreams: [
                                DataBaseEventBus
                                    .instance
                                    .insertOrReplaceMessageIdsStream,
                                DataBaseEventBus.instance.deleteMessageIdStream,
                                DataBaseEventBus.instance.updateUserIdsStream,
                              ],
                              duration: kVerySlowThrottleDuration,
                            );
                }

                if (value.isEmpty) {
                  return userDao
                      .groupParticipants(conversationId)
                      .watchWithStream(
                        eventStreams: [
                          DataBaseEventBus.instance
                              .watchUpdateParticipantStream(
                                conversationIds: [conversationId],
                              ),
                        ],
                        duration: kSlowThrottleDuration,
                      );
                }
                return userDao
                    .fuzzySearchGroupUser(
                      context.account?.userId ?? '',
                      conversationId,
                      value,
                    )
                    .watchWithStream(
                      eventStreams: [
                        DataBaseEventBus.instance.watchUpdateParticipantStream(
                          conversationIds: [conversationId],
                        ),
                      ],
                      duration: kSlowThrottleDuration,
                    );
              }),
        ).data ??
        [];

    return ListView.builder(
      itemCount: filteredUser.length,
      itemBuilder: (context, index) {
        final user = filteredUser[index];
        return InteractiveDecoratedBox(
          onTap: () => onSelected(user),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                AvatarWidget(
                  userId: user.userId,
                  name: user.fullName,
                  avatarUrl: user.avatarUrl,
                  size: 38,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: CustomText(
                          user.fullName ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: context.theme.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      BadgesWidget(
                        verified: user.isVerified ?? false,
                        isBot: user.isBot,
                        membership: user.membership,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.name,
    required this.categories,
    required this.selectedCategories,
    required this.onSelected,
  });

  final String name;
  final List<String> categories;
  final List<String>? selectedCategories;
  final ValueChanged<List<String>> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = listEquals(categories, selectedCategories);
    return InteractiveDecoratedBox(
      onTap: () {
        onSelected(categories);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: ShapeDecoration(
          color: selected ? context.theme.accent : context.theme.listSelected,
          shape: const StadiumBorder(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 32,
        alignment: Alignment.center,
        child: Text(
          name,
          style: TextStyle(
            color: selected ? Colors.white : context.theme.text,
            fontSize: 16,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _Category extends Equatable {
  const _Category(this.name, this.categories);

  final String name;
  final List<String> categories;

  @override
  List<Object?> get props => [name, categories];
}

class _ResetModeIntent extends Intent {
  const _ResetModeIntent();
}
