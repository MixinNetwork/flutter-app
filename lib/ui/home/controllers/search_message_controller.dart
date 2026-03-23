import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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

class ConversationSearchMessageArgs with EquatableMixin {
  const ConversationSearchMessageArgs({
    required this.database,
    required this.keyword,
    required this.conversationId,
    required this.limit,
    this.userId,
    this.categories,
  });

  final Database database;
  final String keyword;
  final String conversationId;
  final String? userId;
  final List<String>? categories;
  final int limit;

  @override
  List<Object?> get props => [
    database,
    keyword,
    conversationId,
    userId,
    categories,
    limit,
  ];
}

class SlideCategorySearchMessageArgs with EquatableMixin {
  const SlideCategorySearchMessageArgs({
    required this.database,
    required this.keyword,
    required this.category,
    required this.limit,
  });

  final Database database;
  final String keyword;
  final SlideCategoryState category;
  final int limit;

  @override
  List<Object?> get props => [database, keyword, category, limit];
}

class ConversationSearchMessageNotifier extends Notifier<SearchMessageState> {
  ConversationSearchMessageNotifier(this._args);

  final itemPositionsListener = ItemPositionsListener.create();
  var _hasMore = true;
  final ConversationSearchMessageArgs _args;

  @override
  SearchMessageState build() {
    _hasMore = true;
    itemPositionsListener.itemPositions.addListener(_onItemPosition);
    ref.onDispose(
      () => itemPositionsListener.itemPositions.removeListener(_onItemPosition),
    );
    Future<void>.microtask(_load);
    return const SearchMessageState([], false);
  }

  Future<void> _load() async {
    if (state.loading) {
      w('search message notifier: loading, ignore');
      return;
    }
    if (!_hasMore) return;

    final lastMessageId = state.items.lastOrNull?.messageId;
    state = SearchMessageState(state.items, true);
    try {
      final items = await _doFuzzySearch(lastMessageId);
      if (items.isEmpty) {
        d('search message notifier: no more data $lastMessageId');
        _hasMore = false;
      }
      state = SearchMessageState([...state.items, ...items], false);
    } catch (error, stacktrace) {
      e('search message notifier: load error', error, stacktrace);
      state = SearchMessageState(state.items, false);
      _hasMore = false;
    }
  }

  Future<List<SearchMessageDetailItem>> _doFuzzySearch(
    String? anchorMessageId,
  ) {
    if (_args.keyword.isEmpty) {
      return _loadUserMessages(anchorMessageId);
    }
    return _args.database.fuzzySearchMessage(
      query: _args.keyword,
      limit: _args.limit,
      conversationIds: [_args.conversationId],
      userId: _args.userId,
      categories: _args.categories,
      anchorMessageId: anchorMessageId,
    );
  }

  Future<List<SearchMessageDetailItem>> _loadUserMessages(
    String? anchorMessageId,
  ) {
    final userId = _args.userId;
    if (userId == null) {
      return Future.value([]);
    }
    return _args.database.messageDao.messageByConversationAndUser(
      userId: userId,
      limit: _args.limit,
      anchorMessageId: anchorMessageId,
      conversationId: _args.conversationId,
      categories: _args.categories,
    );
  }

  void _onItemPosition() {
    final itemPositionValue = itemPositionsListener.itemPositions.value;
    if (itemPositionValue.isEmpty) return;

    final lastIndex = itemPositionValue.last.index;
    if (lastIndex >= state.items.length - 4) {
      unawaited(_load());
    }
  }
}

class SlideCategorySearchMessageNotifier extends Notifier<SearchMessageState> {
  SlideCategorySearchMessageNotifier(this._args);

  final itemPositionsListener = ItemPositionsListener.create();
  var _hasMore = true;
  final SlideCategorySearchMessageArgs _args;

  @override
  SearchMessageState build() {
    _hasMore = true;
    itemPositionsListener.itemPositions.addListener(_onItemPosition);
    ref.onDispose(
      () => itemPositionsListener.itemPositions.removeListener(_onItemPosition),
    );
    Future<void>.microtask(_load);
    return const SearchMessageState([], false);
  }

  Future<void> _load() async {
    if (state.loading) {
      w('search message notifier: loading, ignore');
      return;
    }
    if (!_hasMore) return;

    final lastMessageId = state.items.lastOrNull?.messageId;
    state = SearchMessageState(state.items, true);
    try {
      final items = await _args.database.fuzzySearchMessageByCategory(
        _args.keyword,
        category: _args.category,
        limit: _args.limit,
        anchorMessageId: lastMessageId,
      );
      if (items.isEmpty) {
        d('search message notifier: no more data $lastMessageId');
        _hasMore = false;
      }
      state = SearchMessageState([...state.items, ...items], false);
    } catch (error, stacktrace) {
      e('search message notifier: load error', error, stacktrace);
      state = SearchMessageState(state.items, false);
      _hasMore = false;
    }
  }

  void _onItemPosition() {
    final itemPositionValue = itemPositionsListener.itemPositions.value;
    if (itemPositionValue.isEmpty) return;

    final lastIndex = itemPositionsListener.itemPositions.value.last.index;
    if (lastIndex >= state.items.length - 4) {
      unawaited(_load());
    }
  }
}

final conversationSearchMessageStateProvider = NotifierProvider.autoDispose
    .family<
      ConversationSearchMessageNotifier,
      SearchMessageState,
      ConversationSearchMessageArgs
    >(ConversationSearchMessageNotifier.new);

final slideCategorySearchMessageStateProvider = NotifierProvider.autoDispose
    .family<
      SlideCategorySearchMessageNotifier,
      SearchMessageState,
      SlideCategorySearchMessageArgs
    >(SlideCategorySearchMessageNotifier.new);
