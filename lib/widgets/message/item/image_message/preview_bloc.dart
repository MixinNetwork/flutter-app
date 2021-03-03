import 'package:flutter/src/widgets/page_view.dart';
import 'package:flutter_app/bloc/paging/paging_bloc.dart';
import 'package:flutter_app/db/dao/messages_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';

class PreviewBloc extends PagingBloc<MessageItem> {
  PreviewBloc({
    required this.conversationId,
    required this.messagesDao,
    required int index,
    required this.pageController,
  }) : super(
          initState: const PagingState<MessageItem>(),
          limit: 20,
          index: index,
        ) {
    pageController.addListener(onItemPositions);
  }

  final String conversationId;
  final MessagesDao messagesDao;
  final PageController pageController;

  @override
  void onItemPositions() {
    if (!pageController.hasClients) return;
    final currentPage = pageController.page!.round();
    add(
      PagingItemPositionEvent(
        List.generate(10, (index) => currentPage - 5 + index)
            .where((index) => index > 0)
            .toList(),
      ),
    );
  }

  @override
  Future<void> close() async {
    pageController.removeListener(onItemPositions);
    await super.close();
  }

  @override
  Future<int> queryCount() =>
      messagesDao.mediaMessagesCount(conversationId).getSingle();

  @override
  Future<List<MessageItem>> queryRange(int limit, int offset) =>
      messagesDao.mediaMessages(conversationId, limit, offset).get();
}
