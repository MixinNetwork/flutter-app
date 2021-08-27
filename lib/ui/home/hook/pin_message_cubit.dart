import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../../../account/show_pin_message_key_value.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/message_optimize.dart';
import '../bloc/conversation_cubit.dart';

class PinMessageState extends Equatable {
  const PinMessageState({
    required this.messageIds,
    this.lastMessage,
  });

  final List<String> messageIds;
  final String? lastMessage;

  @override
  List<Object?> get props => [
        messageIds,
        lastMessage,
      ];
}

extension PinMessageCubitExtension on BuildContext {
  List<String> get currentPinMessageIds => read<PinMessageState>().messageIds;

  List<String> get watchCurrentPinMessageIds =>
      watch<PinMessageState>().messageIds;

  String? get lastMessage => read<PinMessageState>().lastMessage;
}

PinMessageState usePinMessageState() {
  final conversationId =
      useBlocStateConverter<ConversationCubit, ConversationState?, String?>(
    converter: (state) => state?.conversationId,
  );

  final pinMessageIds = useMemoizedStream<List<String>>(
    () {
      if (conversationId == null) return Stream.value([]);
      return useContext()
          .database
          .pinMessageDao
          .getPinMessageIds(conversationId)
          .watch()
          .map(
              (event) => event.where((e) => e != null).cast<String>().toList());
    },
    initialData: [],
    keys: [conversationId],
  ).requireData;

  final showLastPinMessage = useMemoizedStream<bool>(
    () {
      if (conversationId == null) return Stream.value(false);
      return ShowPinMessageKeyValue.instance.watch(conversationId);
    },
    initialData: false,
    keys: [conversationId],
  ).requireData;

  final previewContent = useMemoizedStream<String?>(
    () {
      if (!showLastPinMessage || conversationId == null) {
        return Stream.value(null);
      }
      return useContext()
          .database
          .pinMessageDao
          .lastPinMessageItem(conversationId)
          .watchSingleOrNull()
          .asyncMap((event) {
        if (event == null) return null;
        return messagePreviewOptimize(
          event.status,
          event.type,
          event.content,
          false,
          true,
          event.userFullName,
        );
      });
    },
    keys: [showLastPinMessage, conversationId],
  ).data;

  return useMemoized(
      () => PinMessageState(
            messageIds: pinMessageIds,
            lastMessage: previewContent,
          ),
      [
        previewContent,
        pinMessageIds,
      ]);
}
