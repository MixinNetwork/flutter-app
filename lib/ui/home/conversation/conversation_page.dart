import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../../../bloc/keyword_cubit.dart';
import '../../../utils/hook.dart';
import '../../../widgets/search_bar.dart';
import '../bloc/slide_category_cubit.dart';
import 'conversation_list.dart';
import 'search_list.dart';

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
              child: ConversationList(
                key: PageStorageKey(slideCategoryState),
              ),
            ),
          if (hasKeyword)
            const Expanded(
              child: SearchList(),
            ),
        ],
      ),
    );
  }
}
