import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../db/dao/conversation_dao.dart';
import '../../db/database_event_bus.dart';
import '../../utils/extension/extension.dart';
import '../../utils/rivepod.dart';
import 'conversation_provider.dart';
import 'database_provider.dart';
import 'slide_category_provider.dart';

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

class UnseenConversationsStateNotifier
    extends DistinctStateNotifier<List<ConversationItem>?> {
  UnseenConversationsStateNotifier(super.state);

  set _state(List<ConversationItem>? state) => super.state = state;
}

final unseenConversationsProvider = StateNotifierProvider.autoDispose<
  UnseenConversationsStateNotifier,
  List<ConversationItem>?
>((ref) {
  final database = ref.read(databaseProvider).requireValue;
  final slideCategoryState = ref.watch(slideCategoryStateProvider);
  final unseenConversationsStateNotifier = UnseenConversationsStateNotifier(
    null,
  );

  final updateEvent = Rx.merge([
    DataBaseEventBus.instance.updateConversationIdStream,
    DataBaseEventBus.instance.insertOrReplaceMessageIdsStream,
  ]);

  final Stream<List<ConversationItem>> unseenConversations;

  switch (slideCategoryState.type) {
    case SlideCategoryType.chats:
    case SlideCategoryType.contacts:
    case SlideCategoryType.groups:
    case SlideCategoryType.bots:
    case SlideCategoryType.strangers:
      unseenConversations = database.conversationDao
          .unseenConversationByCategory(slideCategoryState.type)
          .watchWithStream(
            eventStreams: [updateEvent],
            duration: kSlowThrottleDuration,
          );
    case SlideCategoryType.circle:
      unseenConversations = database.conversationDao
          .unseenConversationsByCircleId(slideCategoryState.id!)
          .watchWithStream(
            eventStreams: [updateEvent],
            duration: kSlowThrottleDuration,
          );
    case SlideCategoryType.setting:
      unseenConversations = const Stream.empty();
  }

  final subscription = unseenConversations.asyncListen((items) async {
    final newItems = List<ConversationItem>.of(items);

    final selectedConversationId = ref.read(currentConversationIdProvider);

    if (selectedConversationId != null &&
        !newItems.any(
          (item) => item.conversationId == selectedConversationId,
        )) {
      final selectedConversationItem =
          await database.conversationDao
              .conversationItem(selectedConversationId)
              .getSingleOrNull();
      if (selectedConversationItem != null) {
        newItems.add(selectedConversationItem);
      }
    }
    unseenConversationsStateNotifier._state = newItems..sortConversation();
  });

  ref.onDispose(subscription.cancel);

  return unseenConversationsStateNotifier;
});
