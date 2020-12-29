part of 'message_bloc.dart';

class MessageState extends Equatable {
  const MessageState({
    this.messages,
    this.noMoreData = false,
  });

  final List<Message> messages;
  final bool noMoreData;

  @override
  List<Object> get props => [messages, noMoreData];

  MessageState copyWith({
    final List<Message> messages,
    final bool noMoreData,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      noMoreData: noMoreData ?? this.noMoreData,
    );
  }
}
