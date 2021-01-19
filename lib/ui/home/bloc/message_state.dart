part of 'message_bloc.dart';

class MessageState extends PagingState<MessageItem> {
  const MessageState({
    List<MessageItem> list,
    bool noMoreData = false,
    this.conversationId,
  }) : super(list: list, noMoreData: noMoreData);

  final String conversationId;

  @override
  List<Object> get props => [list, noMoreData, conversationId];

  @override
  MessageState copyWith({
    String conversationId,
    List<MessageItem> list,
    bool noMoreData,
  }) {
    return MessageState(
      conversationId: conversationId ?? this.conversationId,
      list: list ?? this.list,
      noMoreData: noMoreData ?? this.noMoreData,
    );
  }
}
