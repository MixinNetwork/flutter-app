import '../../db/mixin_database.dart';
import '../../utils/datetime_format_utils.dart';
import '../../utils/extension/extension.dart';

class MessageRowModel {
  MessageRowModel({
    required this.message,
    this.prev,
    this.next,
  }) : sameDayPrev = isSameDay(prev?.createdAt, message.createdAt),
       sameDayNext = isSameDay(next?.createdAt, message.createdAt),
       prevIsSystem = prev?.type.isSystem ?? false,
       prevIsPin = prev?.type.isPin ?? false,
       sameUserNext = next?.userId == message.userId {
    sameUserPrev =
        !prevIsSystem && !prevIsPin && prev?.userId == message.userId;
    dateTime = sameDayPrev ? null : message.createdAt;
  }

  final MessageItem message;
  final MessageItem? prev;
  final MessageItem? next;
  final bool sameDayPrev;
  final bool sameDayNext;
  final bool prevIsSystem;
  final bool prevIsPin;
  late final bool sameUserPrev;
  final bool sameUserNext;
  late final DateTime? dateTime;
}

class MessageRows {
  const MessageRows({
    required this.top,
    required this.bottom,
    this.center,
  });

  factory MessageRows.from({
    required List<MessageItem> top,
    required MessageItem? center,
    required List<MessageItem> bottom,
  }) => MessageRows(
    top: [
      for (var index = 0; index < top.length; index++)
        MessageRowModel(
          message: top[index],
          prev: top.getOrNull(index - 1),
          next: top.getOrNull(index + 1) ?? center ?? bottom.firstOrNull,
        ),
    ],
    center: center == null
        ? null
        : MessageRowModel(
            message: center,
            prev: top.lastOrNull,
            next: bottom.firstOrNull,
          ),
    bottom: [
      for (var index = 0; index < bottom.length; index++)
        MessageRowModel(
          message: bottom[index],
          prev: bottom.getOrNull(index - 1) ?? center ?? top.lastOrNull,
          next: bottom.getOrNull(index + 1),
        ),
    ],
  );

  final List<MessageRowModel> top;
  final MessageRowModel? center;
  final List<MessageRowModel> bottom;
}
