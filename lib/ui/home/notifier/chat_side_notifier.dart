import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../conversation_info_destination.dart';

class ChatSideState extends Equatable {
  const ChatSideState({
    this.destinations = const [],
  });

  final List<ConversationInfoDestination> destinations;

  ChatSideState copyWith({
    List<ConversationInfoDestination>? destinations,
  }) => ChatSideState(
    destinations: destinations ?? this.destinations,
  );

  @override
  List<Object?> get props => [destinations];
}

class ChatSideNotifier extends ValueNotifier<ChatSideState> {
  ChatSideNotifier() : super(const ChatSideState());

  var _disposed = false;

  ChatSideState get state => value;

  set state(ChatSideState newState) {
    if (_disposed || newState == value) return;
    value = newState;
  }

  ConversationInfoDestination? get currentDestination =>
      state.destinations.isEmpty ? null : state.destinations.last;

  bool isCurrentDestination(ConversationInfoDestination destination) =>
      currentDestination == destination;

  void openDestination(ConversationInfoDestination destination) {
    final destinations = state.destinations.toList();
    final index = destinations.indexOf(destination);
    if (destinations.isNotEmpty && index == destinations.length - 1) return;
    if (index != -1) destinations.removeRange(index, destinations.length);
    state = state.copyWith(destinations: [...destinations, destination]);
  }

  void onPopPage() {
    if (state.destinations.isEmpty) return;
    state = state.copyWith(
      destinations: state.destinations.toList()..removeLast(),
    );
  }

  void closeDestination() => onPopPage();

  void pop() {
    if (state.destinations.isEmpty) return;
    state = state.copyWith(
      destinations: state.destinations
          .sublist(0, state.destinations.length - 1)
          .toList(),
    );
  }

  void toggleDestination(ConversationInfoDestination destination) {
    if (isCurrentDestination(destination)) {
      pop();
      return;
    }
    openDestination(destination);
  }

  void closeAfterContentJump({required bool routeMode}) {
    if (routeMode) clear();
  }

  void toggleInfoPage() {
    if (state.destinations.isEmpty) {
      state = state.copyWith(
        destinations: [ConversationInfoDestination.infoPage],
      );
      return;
    }
    clear();
  }

  void clear() {
    state = state.copyWith(destinations: []);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class SearchConversationKeywordNotifier
    extends ValueNotifier<(String?, String)> {
  SearchConversationKeywordNotifier({
    required ChatSideNotifier chatSideNotifier,
  }) : super(const (null, '')) {
    _searchPageVisible = _isSearchPageVisible(chatSideNotifier.value);
    _chatSideListener = () {
      final visible = _isSearchPageVisible(chatSideNotifier.value);
      if (visible == _searchPageVisible) return;
      _searchPageVisible = visible;
      value = const (null, '');
    };
    chatSideNotifier.addListener(_chatSideListener!);
    _chatSideNotifier = chatSideNotifier;
  }

  ChatSideNotifier? _chatSideNotifier;
  VoidCallback? _chatSideListener;
  var _searchPageVisible = false;

  static bool _isSearchPageVisible(ChatSideState state) =>
      state.destinations.contains(
        ConversationInfoDestination.searchMessageHistory,
      );

  static void updateKeyword(BuildContext context, String keyword) {
    final notifier = context.read<SearchConversationKeywordNotifier>();
    notifier.value = (notifier.value.$1, keyword);
  }

  static void updateSelectedUser(BuildContext context, String? userId) {
    final notifier = context.read<SearchConversationKeywordNotifier>();
    notifier.value = (userId, notifier.value.$2);
  }

  @override
  void dispose() {
    final chatSideNotifier = _chatSideNotifier;
    final chatSideListener = _chatSideListener;
    if (chatSideNotifier != null && chatSideListener != null) {
      chatSideNotifier.removeListener(chatSideListener);
    }
    super.dispose();
  }
}
