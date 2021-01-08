import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/acount/account_server.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/ui/home/bloc/slide_category_cubit.dart';

class Conversation with EquatableMixin {
  const Conversation({
    this.avatars,
    this.name,
    this.dateTime,
    this.messageStatus,
    this.message,
    this.count,
    this.unread,
  });

  final List<String> avatars;
  final String name;
  final DateTime dateTime;
  final String messageStatus;
  final String message;
  final int count;
  final bool unread;

  @override
  List<Object> get props => [
        avatars,
        name,
        dateTime,
        messageStatus,
        message,
        count,
        unread,
      ];
}

class ConversationListCubit extends Cubit<List<Conversation>>
    with SubscribeMixin {
  ConversationListCubit(
    SlideCategoryCubit slideCategoryCubit,
    AccountServer accountServer,
  ) : super(const []) {
    switchConversationList(slideCategoryCubit.state);
    addSubscription(slideCategoryCubit.listen(switchConversationList));
    addSubscription(accountServer.database.conversationDao
        .conversationList()
        .listen((list) {
      debugPrint('accountServer.database.conversationDao: $list');
    }));
  }

  // mock
  void switchConversationList(SlideCategoryState e) {
    switch (e.name) {
      case '陌生人':
        return emit([]);
      default:
        return emit(_generateList(e.name));
    }
  }

  List<Conversation> _generateList(String type) => List.generate(
      99,
      (index) => Conversation(
            name: '$type name $index',
            avatars: List.generate(
              (index % 4) + 1,
              (i) => 'https://i.pravatar.cc/150?u=$type-$index-$i',
            ),
            dateTime: DateTime.now().subtract(Duration(hours: index)),
            messageStatus: '',
            message: '$type message $index',
            count: index,
            unread: index.isEven,
          ));
}
