import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/paging/paging_bloc.dart';

class ConversationListBloc
    extends PagingBloc<ConversationItem, PagingState<ConversationItem>> {
  ConversationListBloc(this.database)
      : super(const PagingState<ConversationItem>()) {
    addSubscription(
      database.insertOrUpdateEventServer.conversationInsertOrUpdateStream
          .listen(
        (item) => add(InsertOrMovePagingEvent(item)),
      ),
    );
  }

  final Database database;

  @override
  void firstLoad() async {
    add(
      ReplacePagingEvent(
        await database.conversationDao.conversationList(
          null,
          10,
        ),
      ),
    );
  }

  @override
  Future<List<ConversationItem>> loadMoreList(
      List<ConversationItem> list) async {
    final result = await database.conversationDao.conversationList(
      list.last.createdAt,
      10,
      list.map((e) => e.conversationId).toList(),
    );
    return result;
  }

  @override
  bool test(ConversationItem a, ConversationItem b) =>
      a?.conversationId == b?.conversationId;
}
