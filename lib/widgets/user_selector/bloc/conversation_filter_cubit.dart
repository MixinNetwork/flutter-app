import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../account/account_server.dart';
import '../../../db/dao/conversation_dao.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/sort.dart';

part 'conversation_filter_state.dart';

class ConversationFilterCubit extends Cubit<ConversationFilterState> {
  ConversationFilterCubit(
    this.accountServer,
    this.onlyContact,
    this.filteredIds,
    this.afterInit,
  ) : super(const ConversationFilterState()) {
    _init();
  }

  final AccountServer accountServer;
  final bool onlyContact;
  final Function(ConversationFilterState) afterInit;
  final Iterable<String> filteredIds;

  late List<ConversationItem> conversations;
  late List<User> friends;
  late List<User> bots;

  Future<void> _init() async {
    var contactConversationIds = <String>{};
    var botConversationIds = <String>{};
    if (onlyContact) {
      conversations = [];
    } else {
      conversations = await accountServer.database.conversationDao
          .conversationItems()
          .get();
      contactConversationIds = conversations
          .where(
            (element) =>
                element.isContactConversation && element.ownerId != null,
          )
          .map((e) => e.ownerId)
          .nonNulls
          .toSet();
      botConversationIds = conversations
          .where((element) => element.isBotConversation)
          .map((e) => e.appId)
          .nonNulls
          .toSet();
    }

    friends = <User>[];
    bots = <User>[];

    final Iterable<User> users = await accountServer.database.userDao
        .notInFriends([
          ...contactConversationIds,
          ...botConversationIds,
        ])
        .get();
    users.where((element) => !filteredIds.contains(element.userId)).forEach((
      e,
    ) {
      if (e.isBot) {
        bots.add(e);
      } else {
        friends.add(e);
      }
    });

    _filterList();
    afterInit(state);
  }

  set keyword(String keyword) {
    emit(state.copyWith(keyword: keyword));
    _filterList();
  }

  void _filterList() {
    if (state.keyword?.isEmpty ?? true) {
      return emit(
        state.copyWith(
          recentConversations: conversations,
          friends: friends,
          bots: bots,
          keyword: state.keyword,
        ),
      );
    }
    final keyword = state.keyword!.toLowerCase();

    final recentConversations =
        conversations
            .where(
              (element) => element.isGroupConversation
                  ? element.groupName != null &&
                        element.groupName!.toLowerCase().contains(keyword)
                  : element.name!.toLowerCase().contains(keyword) ||
                        element.ownerIdentityNumber.toLowerCase().startsWith(
                          keyword,
                        ),
            )
            .toList()
          ..sort(
            compareValuesBy((e) {
              if (e.isGroupConversation) {
                return e.groupName!.toLowerCase().indexOf(keyword);
              }
              final indexOf = e.name?.toLowerCase().indexOf(keyword) ?? -1;
              if (indexOf != -1) return indexOf;
              return e.ownerIdentityNumber.indexOf(keyword);
            }),
          );

    bool where(User element) =>
        (element.fullName != null &&
            element.fullName!.toLowerCase().contains(keyword)) ||
        element.identityNumber.contains(keyword);
    final sort = compareValuesBy((User e) {
      final indexOf = e.fullName?.toLowerCase().indexOf(keyword) ?? -1;
      if (indexOf != -1) return indexOf;
      return e.identityNumber.indexOf(keyword);
    });

    final filterFriends = friends.where(where).toList()..sort(sort);
    final filterBots = bots.where(where).toList()..sort(sort);

    emit(
      state.copyWith(
        recentConversations: recentConversations,
        friends: filterFriends,
        bots: filterBots,
        keyword: state.keyword,
      ),
    );
  }
}
