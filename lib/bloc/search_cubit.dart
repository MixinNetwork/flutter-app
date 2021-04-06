import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/db/dao/conversations_dao.dart';
import 'package:flutter_app/db/dao/messages_dao.dart';
import 'package:flutter_app/db/dao/users_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:rxdart/rxdart.dart';

class SearchState extends Equatable {
  const SearchState({
    this.users = const [],
    this.conversations = const [],
    this.messages = const [],
    this.keyword = '',
  });

  final List<User> users;
  final List<SearchConversationItem> conversations;
  final List<SearchMessageItem> messages;
  final String keyword;

  @override
  List<Object?> get props => [
        users,
        conversations,
        messages,
        keyword,
      ];

  bool get isEmpty =>
      users.isEmpty && conversations.isEmpty && messages.isEmpty;
}

class SearchCubit extends Cubit<SearchState> with SubscribeMixin {
  SearchCubit({
    required this.userDao,
    required this.conversationDao,
    required this.messagesDao,
    required String id,
  }) : super(const SearchState()) {
    addSubscription(_streamController.stream
        .distinct()
        .throttleTime(const Duration(milliseconds: 200))
        .asyncMap(
          (keyword) async => SearchState(
            keyword: keyword,
            users: await userDao
                .fuzzySearchUser(
                    id: id, username: keyword, identityNumber: keyword)
                .get(),
            conversations:
                await conversationDao.fuzzySearchConversation(keyword).get(),
            // messages: await messagesDao
            //     .fuzzySearchMessage(query: keyword, limit: 10)
            //     .get(),
          ),
        )
    .map((event) {
      print('fuck messages: ${event.messages}');
      return event;
    })
        .listen(emit));
  }

  final UserDao userDao;
  final ConversationsDao conversationDao;
  final MessagesDao messagesDao;

  final _streamController = StreamController<String>();

  set keyword(String keyword) => _streamController.add(keyword);

  @override
  Future<void> close() async {
    await _streamController.close();
    await super.close();
  }
}
