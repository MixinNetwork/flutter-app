import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../db/database.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/logger.dart';

class SearchMessageState with EquatableMixin {
  const SearchMessageState(
    this.items,
    this.loading,
  );

  final List<SearchMessageDetailItem> items;
  final bool loading;

  @override
  List<Object?> get props => [items, loading];
}

class SearchMessageCubit extends Cubit<SearchMessageState> {
  SearchMessageCubit({
    required this.database,
    required this.keyword,
    required this.limit,
    this.userId,
    this.categories,
    this.conversationId,
  }) : super(const SearchMessageState([], false)) {
    _load();
    itemPositionsListener.itemPositions.addListener(_onItemPosition);
  }

  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  final Database database;

  final String keyword;
  final String? userId;
  final List<String>? categories;
  final String? conversationId;

  final int limit;

  var _hasMore = true;

  Future<void> _load() async {
    if (state.loading) {
      w('search message cubit: loading, ignore');
      return;
    }
    if (!_hasMore) {
      d('search message cubit $keyword: no more items');
      return;
    }
    final lastMessageId = state.items.lastOrNull?.messageId;
    emit(SearchMessageState(state.items, true));
    try {
      final items = await database.fuzzySearchMessage(
        query: keyword,
        limit: limit,
        conversationId: conversationId,
        userId: userId,
        categories: categories,
        anchorMessageId: lastMessageId,
      );
      if (items.isEmpty) {
        _hasMore = false;
      }
      emit(SearchMessageState([
        ...state.items,
        ...items,
      ], false));
    } catch (error, stacktrace) {
      e('search message cubit: load error', error, stacktrace);
      emit(SearchMessageState(state.items, false));
      _hasMore = false;
    }
  }

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
