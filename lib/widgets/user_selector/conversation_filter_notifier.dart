import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../account/account_server.dart';
import '../../../db/dao/conversation_dao.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/sort.dart';

class ConversationFilterNotifier
    extends ValueNotifier<ConversationFilterState> {
  ConversationFilterNotifier(
    this.accountServer,
    this.onlyContact,
    this.filteredIds,
    this.afterInit,
  ) : super(const ConversationFilterState()) {
    unawaited(_init());
  }

  final AccountServer accountServer;
  final bool onlyContact;
  final Function(ConversationFilterState) afterInit;
  final Iterable<String> filteredIds;

  var _conversations = <ConversationItem>[];
  var _friends = <User>[];
  var _bots = <User>[];
  var _disposed = false;

  Future<void> _init() async {
    var contactConversationIds = <String>{};
    var botConversationIds = <String>{};
    if (onlyContact) {
      _conversations = [];
    } else {
      _conversations = await accountServer.database.conversationDao
          .conversationItems()
          .get();
      contactConversationIds = _conversations
          .where(
            (element) =>
                element.isContactConversation && element.ownerId != null,
          )
          .map((e) => e.ownerId)
          .nonNulls
          .toSet();
      botConversationIds = _conversations
          .where((element) => element.isBotConversation)
          .map((e) => e.appId)
          .nonNulls
          .toSet();
    }

    _friends = <User>[];
    _bots = <User>[];

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
        _bots.add(e);
      } else {
        _friends.add(e);
      }
    });

    if (_disposed) return;
    _filterList();
    if (_disposed) return;
    afterInit(value);
  }

  set keyword(String keyword) {
    if (_disposed) return;
    value = value.copyWith(keyword: keyword);
    _filterList();
  }

  void _filterList() {
    if (_disposed) return;
    if (value.keyword?.isEmpty ?? true) {
      value = value.copyWith(
        recentConversations: _conversations,
        friends: _friends,
        bots: _bots,
        keyword: value.keyword,
      );
      return;
    }
    final keyword = value.keyword!.toLowerCase();

    final recentConversations =
        _conversations
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
    final sort = compareValuesBy<User>((e) {
      final indexOf = e.fullName?.toLowerCase().indexOf(keyword) ?? -1;
      if (indexOf != -1) return indexOf;
      return e.identityNumber.indexOf(keyword);
    });

    final filterFriends = _friends.where(where).toList()..sort(sort);
    final filterBots = _bots.where(where).toList()..sort(sort);

    value = value.copyWith(
      recentConversations: recentConversations,
      friends: filterFriends,
      bots: filterBots,
      keyword: value.keyword,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class ConversationFilterState {
  const ConversationFilterState({
    this.recentConversations = const [],
    this.friends = const [],
    this.bots = const [],
    this.keyword,
  });

  final List<ConversationItem> recentConversations;
  final List<User> friends;
  final List<User> bots;
  final String? keyword;

  Set<String> get appIds => {
    ...recentConversations.map((e) => e.ownerId).nonNulls,
    ...[...bots, ...friends].map((e) => e.userId),
  };

  ConversationFilterState copyWith({
    List<ConversationItem>? recentConversations,
    List<User>? friends,
    List<User>? bots,
    String? keyword,
  }) => ConversationFilterState(
    recentConversations: recentConversations ?? this.recentConversations,
    friends: friends ?? this.friends,
    bots: bots ?? this.bots,
    keyword: keyword ?? this.keyword,
  );
}
