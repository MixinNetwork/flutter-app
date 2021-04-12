import 'package:flutter_app/bloc/paging/paging_bloc.dart';
import 'package:flutter_app/bloc/simple_cubit.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/db/dao/messages_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';

class PreviewBloc extends PagingBloc<MessageItem> with SubscribeMixin {
  PreviewBloc({
    required this.conversationId,
    required this.messagesDao,
    required int index,
    required IntCubit intCubit,
  }) : super(
          initState: const PagingState<MessageItem>(),
          limit: 20,
          index: index,
        ) {
    addSubscription(intCubit.stream.distinct().listen(onItemPosition));
  }

  final String conversationId;
  final MessagesDao messagesDao;

  void onItemPosition(int index) {
    add(
      PagingItemPositionEvent(
        List.generate(10, (index) => index - 5 + index)
            .where((index) => index > 0)
            .toList(),
      ),
    );
  }

  @override
  Future<int> queryCount() =>
      messagesDao.mediaMessagesCount(conversationId).getSingle();

  @override
  Future<List<MessageItem>> queryRange(int limit, int offset) async {
    final future =
        await messagesDao.mediaMessages(conversationId, limit, offset).get();
    return future;
  }
}
