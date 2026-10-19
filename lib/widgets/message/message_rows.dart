import 'package:flutter/foundation.dart';

import '../../db/mixin_database.dart';
import '../../utils/datetime_format_utils.dart';
import '../../utils/extension/extension.dart';

@immutable
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

  // Rows render from the message and these neighbour flags only, so two rows
  // with equal values render the same and the timeline can skip the rebuild.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageRowModel &&
          other.message == message &&
          other.sameDayPrev == sameDayPrev &&
          other.sameDayNext == sameDayNext &&
          other.sameUserPrev == sameUserPrev &&
          other.sameUserNext == sameUserNext &&
          other.dateTime == dateTime &&
          (other.next == null) == (next == null);

  @override
  int get hashCode => Object.hash(
    message,
    sameDayPrev,
    sameDayNext,
    sameUserPrev,
    sameUserNext,
    dateTime,
    next == null,
  );
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
