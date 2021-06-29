import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../account/account_server.dart';
import '../../../bloc/paging/paging_bloc.dart';
import '../../../constants/resources.dart';
import '../../../db/mixin_database.dart';
import '../../../generated/l10n.dart';
import '../../../utils/hook.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/brightness_observer.dart';
import '../../../widgets/search_text_field.dart';
import '../bloc/conversation_cubit.dart';
import '../bloc/conversation_list_bloc.dart';
import '../chat_page.dart';
import '../conversation_page.dart';

class SearchMessagePage extends HookWidget {
  const SearchMessagePage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final keyword = useBlocState<SearchConversationKeywordCubit, String>();

    final conversationId =
        useBlocStateConverter<ConversationCubit, ConversationState?, String?>(
      converter: (state) => state?.conversationId,
      when: (conversationId) => conversationId != null,
    );
    final searchMessageBloc =
        useBloc<AnonymousPagingBloc<SearchMessageDetailItem>>(
      () => AnonymousPagingBloc<SearchMessageDetailItem>(
        initState: const PagingState<SearchMessageDetailItem>(),
        limit: context.read<ConversationListBloc>().limit,
        queryCount: () async {
          if (keyword.trim().isEmpty) return 0;
          return context
              .read<AccountServer>()
              .database
              .messagesDao
              .fuzzySearchMessageCountByConversationId(keyword, conversationId!)
              .getSingle();
        },
        queryRange: (int limit, int offset) async {
          if (keyword.trim().isEmpty) return [];
          return context
              .read<AccountServer>()
              .database
              .messagesDao
              .fuzzySearchMessageByConversationId(
                  conversationId: conversationId!,
                  query: keyword,
                  limit: limit,
                  offset: offset)
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
      child = const SizedBox();
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

    return Scaffold(
      backgroundColor: BrightnessData.themeOf(context).primary,
      appBar: MixinAppBar(
        title: Text(Localization.of(context).searchMessageHistory),
        actions: [
          if (!Navigator.of(context).canPop())
            ActionButton(
              name: Resources.assetsImagesIcCloseSvg,
              onTap: () {
                context.read<SearchConversationKeywordCubit>().emit('');
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: SearchTextField(
              onChanged: (keyword) =>
                  context.read<SearchConversationKeywordCubit>().emit(keyword),
              fontSize: 16,
              controller: useTextEditingController(),
              hintText: Localization.of(context).search,
            ),
          ),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}
