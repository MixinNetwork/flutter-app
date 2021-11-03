import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../account/show_pin_message_key_value.dart';
import '../../../blaze/vo/pin_message_minimal.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/message/item/pin_message.dart';
import '../../../widgets/message/item/text/mention_builder.dart';
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
  final context = useContext();
  final conversationId =
      useBlocStateConverter<ConversationCubit, ConversationState?, String?>(
    converter: (state) => state?.conversationId,
  );

  final pinMessageIds = useMemoizedStream<List<String>>(
    () {
      if (conversationId == null) return Stream.value([]);
      return context.database.pinMessageDao
          .getPinMessageIds(conversationId)
          .watchThrottle()
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
      return context.database.pinMessageDao
          .lastPinMessageItem(conversationId)
          .watchSingleOrNullThrottle()
          .asyncMap((message) async {
        if (message == null) return null;

        final pinMessageMinimal =
            PinMessageMinimal.fromJsonString(message.content ?? '');
        if (pinMessageMinimal == null) return null;
        final preview = await generatePinPreviewText(
          pinMessageMinimal: pinMessageMinimal,
          mentionCache: context.read<MentionCache>(),
        );

        return context.l10n.pinned(message.userFullName ?? '', preview);
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
