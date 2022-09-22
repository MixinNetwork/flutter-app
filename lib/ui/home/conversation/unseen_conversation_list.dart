import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:markdown_widget/scrollable_positioned_list/src/scrollable_positioned_list.dart';

import '../../../db/mixin_database.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../bloc/conversation_cubit.dart';
import '../bloc/slide_category_cubit.dart';
import '../route/responsive_navigator_cubit.dart';
import 'conversation_list.dart';
import 'menu_wrapper.dart';
import 'search_list.dart';

extension _ConversationItemSort on List<ConversationItem> {
  void sortConversation() => sort((a, b) {
        // pinTime
        if (a.pinTime != null) {
          if (b.pinTime != null) {
            return b.pinTime!.compareTo(a.pinTime!);
          } else {
            return -1;
          }
        } else if (b.pinTime != null) {
          return 1;
        }

        // lastMessageCreatedAt
        if (a.lastMessageCreatedAt != null) {
          if (b.lastMessageCreatedAt != null) {
            return b.lastMessageCreatedAt!.compareTo(a.lastMessageCreatedAt!);
          } else {
            return -1;
          }
        } else if (b.lastMessageCreatedAt != null) {
          return 1;
        }

        // createdAt
        return b.createdAt.compareTo(a.createdAt);
      });
}

class UnseenConversationList extends HookWidget {
  const UnseenConversationList({super.key});

  @override
  Widget build(BuildContext context) {
    final unreadConversations = useState(<ConversationItem>[]);

    final currentConversationId =
        useBlocStateConverter<ConversationCubit, ConversationState?, String?>(
      converter: (state) => state?.conversationId,
    );

    final selectedConversation = useRef<String?>(null);

    final slideCategoryState =
        useBlocState<SlideCategoryCubit, SlideCategoryState>();

    useEffect(() {
      final Stream<List<ConversationItem>> unseenConversations;
      switch (slideCategoryState.type) {
        case SlideCategoryType.chats:
        case SlideCategoryType.contacts:
        case SlideCategoryType.groups:
        case SlideCategoryType.bots:
        case SlideCategoryType.strangers:
          unseenConversations = context.accountServer.database.conversationDao
              .unseenConversationByCategory(slideCategoryState.type)
              .watchThrottle(kSlowThrottleDuration);
          break;
        case SlideCategoryType.circle:
          unseenConversations = context.database.conversationDao
              .unseenConversationsByCircleId(slideCategoryState.id!)
              .watchThrottle(kSlowThrottleDuration);
          break;
        case SlideCategoryType.setting:
          unseenConversations = const Stream.empty();
          break;
      }

      final subscription = unseenConversations.asyncListen((items) async {
        final newItems = List<ConversationItem>.of(items);

        final selectedConversationId = selectedConversation.value;
        if (selectedConversationId != null &&
            !newItems
                .any((item) => item.conversationId == selectedConversationId)) {
          final selectedConversationItem = await context
              .accountServer.database.conversationDao
              .conversationItem(selectedConversationId)
              .getSingleOrNull();
          if (selectedConversationItem != null) {
            newItems.add(selectedConversationItem);
          }
        }
        unreadConversations.value = newItems..sortConversation();
      });
      return subscription.cancel;
    }, [slideCategoryState]);

    final conversationItems = unreadConversations.value;

    final routeMode = useBlocStateConverter<ResponsiveNavigatorCubit,
        ResponsiveNavigatorState, bool>(
      converter: (state) => state.routeMode,
    );

    if (conversationItems.isEmpty) {
      return const SearchEmptyWidget();
    }
    return ScrollablePositionedList.builder(
      itemBuilder: (context, index) {
        final conversation = conversationItems[index];
        return ConversationMenuWrapper(
          conversation: conversation,
          removeChatFromCircle: true,
          child: ConversationItemWidget(
            conversation: conversation,
            selected: conversation.conversationId == currentConversationId &&
                !routeMode,
            onTap: () {
              selectedConversation.value = conversation.conversationId;
              ConversationCubit.selectConversation(
                  context, conversation.conversationId,
                  conversation: conversation);
            },
          ),
        );
      },
      itemCount: conversationItems.length,
    );
  }
}
