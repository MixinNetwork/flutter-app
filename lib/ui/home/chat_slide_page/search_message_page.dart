import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rxdart/rxdart.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../bloc/paging/paging_bloc.dart';
import '../../../constants/resources.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/search_text_field.dart';
import '../bloc/conversation_cubit.dart';
import '../bloc/conversation_list_bloc.dart';
import '../bloc/participants_cubit.dart';
import '../chat/chat_page.dart';
import '../conversation_page.dart';

class SearchMessagePage extends HookWidget {
  const SearchMessagePage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                                if (selectedUser.value?.fullName != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      selectedUser.value!.fullName!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: context.theme.accent,
                                      ),
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
  }) : super(key: key);
  final String? selectedUserId;

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
          if (selectedUserId != null) {
            if (keyword.trim().isEmpty) {
              return context.database.messageDao
                  .messageCountByConversationIdAndUserId(
                      conversationId, selectedUserId!)
                  .getSingle();
            }
            return context.database.messageDao
                .fuzzySearchMessageCountByConversationIdAndUserId(
                    keyword, conversationId, selectedUserId!)
                .getSingle();
          }

          if (keyword.trim().isEmpty) return 0;
          return context.database.messageDao
              .fuzzySearchMessageCountByConversationId(keyword, conversationId)
              .getSingle();
        },
        queryRange: (int limit, int offset) async {
          if (selectedUserId != null) {
            if (keyword.trim().isEmpty) {
              return context.database.messageDao
                  .messageByConversationIdAndUserId(
                      conversationId: conversationId,
                      userId: selectedUserId!,
                      limit: limit,
                      offset: offset)
                  .get();
            }
            return context.database.messageDao
                .fuzzySearchMessageByConversationIdAndUserId(
                    conversationId: conversationId,
                    userId: selectedUserId!,
                    query: keyword,
                    limit: limit,
                    offset: offset)
                .get();
          }
          if (keyword.trim().isEmpty) return [];
          return context.database.messageDao
              .fuzzySearchMessageByConversationId(
                  conversationId: conversationId,
                  query: keyword,
                  limit: limit,
                  offset: offset)
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

    return ScrollablePositionedList.builder(
      itemPositionsListener: searchMessageBloc.itemPositionsListener,
      itemCount: pageState.count,
      padding: const EdgeInsets.only(top: 8),
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
    final keyword = useMemoizedStream(
          () => keywordStream
              .throttleTime(const Duration(milliseconds: 100), trailing: true)
              .map((event) => event.text)
              .distinct(),
        ).data ??
        editingController.text;

    final filteredUser =
        useBlocStateConverter<ParticipantsCubit, List<User>, List<User>>(
            converter: (state) {
              if (keyword.isEmpty) return state;
              return state
                  .where((e) =>
                      e.fullName
                          ?.toLowerCase()
                          .contains(keyword.trim().toLowerCase()) ??
                      false)
                  .toList();
            },
            keys: [keyword]);

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
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

class _ResetModeIntent extends Intent {
  const _ResetModeIntent();
}
