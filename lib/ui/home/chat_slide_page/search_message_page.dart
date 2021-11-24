import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rxdart/rxdart.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../bloc/paging/paging_bloc.dart';
import '../../../constants/resources.dart';
import '../../../db/mixin_database.dart';
import '../../../enum/message_category.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/search_text_field.dart';
import '../bloc/conversation_cubit.dart';
import '../bloc/conversation_list_bloc.dart';
import '../chat/chat_page.dart';
import '../conversation_page.dart';

class SearchMessagePage extends HookWidget {
  const SearchMessagePage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = useMemoized(() => [
          _Category(
            context.l10n.text,
            const [
              MessageCategory.plainText,
              MessageCategory.signalText,
              MessageCategory.encryptedText,
            ],
          ),
          _Category(
            context.l10n.post,
            const [
              MessageCategory.plainPost,
              MessageCategory.signalPost,
              MessageCategory.encryptedPost,
            ],
          ),
        ]);

    final selectedCategories = useState<List<String>?>(null);

    final isGroup = useMemoized(
        () => context.read<ConversationCubit>().state?.isGroup ?? false);

    final focusNode = useFocusNode();
    final editingController = useTextEditingController();
    final userMode = useState(false);
    final selectedUser = useState<User?>(null);

    final keywordStream = useValueNotifierConvertSteam(editingController);
    final keywordIsEmpty = useMemoizedStream(
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
        title: Text(context.l10n.searchMessageHistory),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
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
                      _ResetModeIntent:
                          CallbackAction(onInvoke: (Intent intent) {
                        if (selectedUser.value != null) {
                          return selectedUser.value = null;
                        }
                        if (userMode.value) return userMode.value = false;
                      }),
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
                                      name: selectedUser.value!.fullName ?? '',
                                      avatarUrl: selectedUser.value!.avatarUrl,
                                      userId: selectedUser.value!.userId,
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
                      if (!isGroup || userMode.value) return const SizedBox();
                      return SizedBox(
                        height: 36,
                        child: ActionButton(
                          name: Resources.assetsImagesContactSvg,
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
            child: Builder(builder: (context) {
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
            }),
          ),
          Expanded(
            child: userMode.value && selectedUser.value == null
                ? _SearchParticipantList(
                    editingController: editingController,
                    onSelected: (user) {
                      editingController.text = '';
                      selectedUser.value = user;
                    },
                  )
                : _SearchMessageList(
                    selectedUserId: selectedUser.value?.userId,
                    categories: selectedCategories.value,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchMessageList extends HookWidget {
  const _SearchMessageList({
    Key? key,
    this.selectedUserId,
    this.categories,
  }) : super(key: key);

  final String? selectedUserId;
  final List<String>? categories;

  @override
  Widget build(BuildContext context) {
    final initKeyword =
        useMemoized(() => context.read<SearchConversationKeywordCubit>().state);
    final keyword = useMemoizedStream(
          () => context
              .read<SearchConversationKeywordCubit>()
              .stream
              .map((event) => event.item2)
              .throttleTime(const Duration(milliseconds: 400), trailing: true),
        ).data ??
        initKeyword.item2;

    final conversationId = useMemoized(() {
      final conversationId =
          context.read<ConversationCubit>().state?.conversationId;
      assert(conversationId != null);
      return conversationId!;
    });

    final searchMessageBloc =
        useBloc<AnonymousPagingBloc<SearchMessageDetailItem>>(
      () => AnonymousPagingBloc<SearchMessageDetailItem>(
        initState: const PagingState<SearchMessageDetailItem>(),
        limit: context.read<ConversationListBloc>().limit,
        queryCount: () async {
          if (keyword.trim().isEmpty) {
            if (selectedUserId != null) {
              return context.database.messageDao
                  .messageCountByConversationAndUser(
                    conversationId,
                    selectedUserId!,
                    categories,
                  )
                  .getSingle();
            } else {
              return 0;
            }
          }

          return context.database.messageDao
              .fuzzySearchMessageCount(
                keyword,
                conversationId: conversationId,
                userId: selectedUserId,
                categories: categories,
              )
              .getSingle();
        },
        queryRange: (int limit, int offset) async {
          if (keyword.trim().isEmpty) {
            if (selectedUserId != null) {
              return context.database.messageDao
                  .messageByConversationAndUser(
                    conversationId: conversationId,
                    userId: selectedUserId!,
                    limit: limit,
                    offset: offset,
                  )
                  .get();
            } else {
              return [];
            }
          }

          return context.database.messageDao
              .fuzzySearchMessage(
                conversationId: conversationId,
                userId: selectedUserId,
                query: keyword,
                limit: limit,
                offset: offset,
                categories: categories,
              )
              .get();
        },
      ),
      keys: [keyword, categories],
    );

    useEffect(
      () => context.database.messageDao.searchMessageUpdateEvent
          .listen((event) => searchMessageBloc.add(PagingUpdateEvent()))
          .cancel,
      [keyword, categories],
    );

    final pageState = useBlocState<PagingBloc<SearchMessageDetailItem>,
        PagingState<SearchMessageDetailItem>>(bloc: searchMessageBloc);

    return ScrollablePositionedList.builder(
      itemPositionsListener: searchMessageBloc.itemPositionsListener,
      itemCount: pageState.count,
      itemBuilder: (context, index) {
        final message = pageState.map[index];
        if (message == null) return const SizedBox(height: 80);
        return SearchMessageItem(
          message: message,
          keyword: keyword,
          showSender: true,
          onTap: () async => ConversationCubit.selectConversation(
            context,
            message.conversationId,
            initIndexMessageId: message.messageId,
          ),
        );
      },
    );
  }
}

class _SearchParticipantList extends HookWidget {
  const _SearchParticipantList({
    Key? key,
    required this.onSelected,
    required this.editingController,
  }) : super(key: key);

  final ValueChanged<User> onSelected;
  final TextEditingController editingController;

  @override
  Widget build(BuildContext context) {
    final keywordStream = useValueNotifierConvertSteam(editingController);

    final filteredUser = useMemoizedStream(() => keywordStream
                .throttleTime(const Duration(milliseconds: 100), trailing: true)
                .map((event) => event.text)
                .switchMap((value) {
              final conversationId =
                  context.read<ConversationCubit>().state?.conversationId;
              if (conversationId == null) return Stream.value(<User>[]);
              final userDao = context.database.userDao;

              if (value.isEmpty) {
                return userDao
                    .groupParticipants(conversationId: conversationId)
                    .watchThrottle(kSlowThrottleDuration);
              }
              return userDao
                  .fuzzySearchGroupUser(
                    currentUserId: context.multiAuthState.currentUserId ?? '',
                    conversationId: conversationId,
                    keyword: value,
                  )
                  .watchThrottle(kSlowThrottleDuration);
            })).data ??
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
                  name: user.fullName ?? '',
                  avatarUrl: user.avatarUrl,
                  size: 38,
                ),
                const SizedBox(width: 16),
                Text(
                  user.fullName ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: context.theme.text,
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
    Key? key,
    required this.name,
    required this.categories,
    required this.selectedCategories,
    required this.onSelected,
  }) : super(key: key);

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
