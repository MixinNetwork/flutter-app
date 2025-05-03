import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../db/dao/message_dao.dart';
import '../../../db/database.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/logger.dart';
import '../../provider/slide_category_provider.dart';

class SearchMessageState with EquatableMixin {
  const SearchMessageState(this.items, this.loading);

  final List<SearchMessageDetailItem> items;
  final bool loading;

  bool get initializing => items.isEmpty && loading;

  @override
  List<Object?> get props => [items, loading];
}

abstract class SearchMessageCubit extends Cubit<SearchMessageState> {
  SearchMessageCubit({
    required this.database,
    required this.keyword,
    required this.limit,
  }) : super(const SearchMessageState([], false)) {
    _load();
    itemPositionsListener.itemPositions.addListener(_onItemPosition);
  }

  factory SearchMessageCubit.conversation({
    required Database database,
    required String keyword,
    required String conversationId,
    required String? userId,
    required List<String>? categories,
    required int limit,
  }) => _ConversationSearchMessageCubit(
    database: database,
    keyword: keyword,
    conversationId: conversationId,
    userId: userId,
    categories: categories,
    limit: limit,
  );

  factory SearchMessageCubit.slideCategory({
    required Database database,
    required String keyword,
    required SlideCategoryState category,
    required int limit,
  }) => _SlideCategorySearchMessageCubit(
    database: database,
    keyword: keyword,
    category: category,
    limit: limit,
  );

  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  final Database database;

  final String keyword;

  final int limit;

  var _hasMore = true;

  @override
  void emit(SearchMessageState state) {
    if (isClosed) {
      i('search message cubit: closed, ignore');
      return;
    }
    super.emit(state);
  }

  Future<void> _load() async {
    if (state.loading) {
      w('search message cubit: loading, ignore');
      return;
    }
    if (!_hasMore) {
      return;
    }
    final lastMessageId = state.items.lastOrNull?.messageId;
    emit(SearchMessageState(state.items, true));
    try {
      final items = await _doFuzzySearch(lastMessageId);
      if (items.isEmpty) {
        d('search message cubit: no more data $lastMessageId');
        _hasMore = false;
      }
      emit(SearchMessageState([...state.items, ...items], false));
    } catch (error, stacktrace) {
      e('search message cubit: load error', error, stacktrace);
      emit(SearchMessageState(state.items, false));
      _hasMore = false;
    }
  }

  Future<List<SearchMessageDetailItem>> _doFuzzySearch(String? anchorMessageId);

  void _onItemPosition() {
    final itemPositionValue = itemPositionsListener.itemPositions.value;
    if (itemPositionValue.isEmpty) {
      return;
    }
    final lastIndex = itemPositionValue.last.index;
    if (lastIndex >= state.items.length - 4) {
      _load();
    }
  }

  @override
  Future<void> close() {
    itemPositionsListener.itemPositions.removeListener(_onItemPosition);
    return super.close();
  }
}

class _ConversationSearchMessageCubit extends SearchMessageCubit {
  _ConversationSearchMessageCubit({
    required this.conversationId,
    required super.database,
    required super.keyword,
    required super.limit,
    this.userId,
    this.categories,
  });

  final String? userId;
  final List<String>? categories;
  final String conversationId;

  @override
  Future<List<SearchMessageDetailItem>> _doFuzzySearch(
    String? anchorMessageId,
  ) {
    if (keyword.isEmpty) {
      return _loadUserMessages(anchorMessageId);
    }
    return database.fuzzySearchMessage(
      query: keyword,
      limit: limit,
      conversationIds: [conversationId],
      userId: userId,
      categories: categories,
      anchorMessageId: anchorMessageId,
    );
  }

  Future<List<SearchMessageDetailItem>> _loadUserMessages(
    String? anchorMessageId,
  ) {
    if (userId == null) {
      return Future.value([]);
    }
    return database.messageDao.messageByConversationAndUser(
      userId: userId!,
      limit: limit,
      anchorMessageId: anchorMessageId,
      conversationId: conversationId,
      categories: categories,
    );
  }
}

class _SlideCategorySearchMessageCubit extends SearchMessageCubit {
  _SlideCategorySearchMessageCubit({
    required this.category,
    required super.database,
    required super.keyword,
    required super.limit,
  });

  final SlideCategoryState category;

  @override
  Future<List<SearchMessageDetailItem>> _doFuzzySearch(
    String? anchorMessageId,
  ) => database.fuzzySearchMessageByCategory(
    keyword,
    category: category,
    limit: limit,
    anchorMessageId: anchorMessageId,
  );
}
