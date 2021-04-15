import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/paging/paging_bloc.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/conversation_list_bloc.dart';
import 'package:flutter_app/ui/home/chat_page.dart';
import 'package:flutter_app/ui/home/conversation_page.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator_cubit.dart';
import 'package:flutter_app/utils/hook.dart';
import 'package:flutter_app/widgets/action_button.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/search_text_field.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class SearchMessagePage extends HookWidget {
  const SearchMessagePage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final keyword = useBlocState<SearchConversationKeywordCubit, String>();

    final conversationId =
        useBlocStateConverter<ConversationCubit, ConversationItem?, String?>(
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
          return await context
              .read<AccountServer>()
              .database
              .messagesDao
              .fuzzySearchMessageCountByConversationId(keyword, conversationId!)
              .getSingle();
        },
        queryRange: (int limit, int offset) async {
          if (keyword.trim().isEmpty) return [];
          return await context
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
    if (pageState.count <= 0)
      child = const SearchEmpty();
    else
      child = ScrollablePositionedList.builder(
        itemPositionsListener: searchMessageBloc.itemPositionsListener,
        itemCount: pageState.count,
        itemBuilder: (context, index) {
          final message = pageState.map[index];
          if (message == null) return const SizedBox(height: 80);
          return SearchMessageItem(
            message: message,
            keyword: keyword,
            onTap: () async {
              final conversation = await context
                  .read<AccountServer>()
                  .database
                  .conversationDao
                  .conversationItem(message.conversationId);

              final index = await context
                  .read<AccountServer>()
                  .database
                  .messagesDao
                  .messageIndex(message.conversationId, message.messageId)
                  .getSingleOrNull();
              context.read<ConversationCubit>().initIndex = index;
              context.read<ConversationCubit>().emit(conversation);
              ResponsiveNavigatorCubit.of(context)
                  .pushPage(ResponsiveNavigatorCubit.chatPage);
            },
          );
        },
      );

    return Scaffold(
      backgroundColor: BrightnessData.themeOf(context).primary,
      appBar: MixinAppBar(
        title: Text(Localization.of(context).searchMessageHistory),
        actions: [
          if (!Navigator.of(context).canPop())
            ActionButton(
              name: Resources.assetsImagesIcCloseSvg,
              onTap: () => Navigator.pop(context),
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
