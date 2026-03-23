import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/system/text_input.dart';
import '../../../widgets/search_bar.dart';
import '../../provider/conversation_unseen_filter_enabled.dart';
import '../../provider/keyword_provider.dart';
import '../../provider/slide_category_provider.dart';
import '../providers/home_scope_providers.dart';
import 'conversation_list.dart';
import 'search_list.dart';

class ConversationPage extends HookConsumerWidget {
  const ConversationPage({
    required this.hasDrawer,
    super.key,
  });

  final bool hasDrawer;

  static const conversationItemHeight = 78.0;
  static const conversationItemAvatarSize = 50.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasKeyword = ref.watch(hasKeywordProvider);

    final textEditingController = useMemoized(EmojiTextEditingController.new);
    final focusNode = useFocusNode();

    final slideCategoryState = ref.watch(slideCategoryProvider);

    final filterUnseen = ref.watch(conversationUnseenFilterEnabledProvider);

    return Column(
      children: [
        SearchBar(
          textEditingController: textEditingController,
          focusNode: focusNode,
          hasDrawer: hasDrawer,
        ),
        if (!filterUnseen && !hasKeyword)
          Expanded(
            child: ConversationList(key: PageStorageKey(slideCategoryState)),
          ),
        if (filterUnseen || hasKeyword)
          Expanded(
            child: SearchList(
              filterUnseen: filterUnseen,
              textEditingController: textEditingController,
              focusNode: focusNode,
            ),
          ),
      ],
    );
  }
}
