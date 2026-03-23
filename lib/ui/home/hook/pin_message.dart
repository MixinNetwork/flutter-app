import 'package:equatable/equatable.dart';

class PinMessagePreview extends Equatable {
  const PinMessagePreview({
    required this.senderFullName,
    required this.preview,
  });

  final String senderFullName;
  final String preview;

  @override
  List<Object?> get props => [senderFullName, preview];
}

class PinMessageState extends Equatable {
  const PinMessageState({required this.messageIds, this.lastMessage});

  final List<String> messageIds;
  final PinMessagePreview? lastMessage;

  @override
  List<Object?> get props => [messageIds, lastMessage];
}
