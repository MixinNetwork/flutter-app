import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../account/show_pin_message_key_value.dart';
import '../../../blaze/vo/pin_message_minimal.dart';
import '../../../db/database_event_bus.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/message/item/pin_message.dart';
import '../../provider/mention_cache_provider.dart';

class PinMessageState extends Equatable {
  const PinMessageState({required this.messageIds, this.lastMessage});

  final List<String> messageIds;
  final String? lastMessage;

  @override
  List<Object?> get props => [messageIds, lastMessage];
}

extension PinMessageCubitExtension on BuildContext {
  List<String> get currentPinMessageIds => read<PinMessageState>().messageIds;

  List<String> get watchCurrentPinMessageIds =>
      watch<PinMessageState>().messageIds;

  String? get lastMessage => read<PinMessageState>().lastMessage;
}

PinMessageState usePinMessageState(String? conversationId) {
  final context = useContext();

  final pinMessageIds = useMemoizedStream<List<String>>(
    () {
      if (conversationId == null) return Stream.value([]);
      return context.database.pinMessageDao
          .pinMessageIds(conversationId)
          .watchWithStream(
            eventStreams: [
              DataBaseEventBus.instance.watchPinMessageStream(
                conversationIds: [conversationId],
              ),
            ],
            duration: kSlowThrottleDuration,
          )
          .map((event) => event.nonNulls.toList());
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
      if (!showLastPinMessage ||
          conversationId == null ||
          pinMessageIds.firstOrNull == null) {
        return Stream.value(null);
      }
      final messageId = pinMessageIds.first;

      return context.database.pinMessageDao
          .pinMessageItem(messageId, conversationId)
          .watchSingleOrNullWithStream(
            eventStreams: [
              DataBaseEventBus.instance.watchInsertOrReplaceMessageIdsStream(
                messageIds: [messageId],
              ),
              DataBaseEventBus.instance.deleteMessageIdStream.where(
                (event) => event.any((element) => element.contains(messageId)),
              ),
            ],
            duration: kSlowThrottleDuration,
          )
          .asyncMap((message) async {
            if (message == null) return null;

            final pinMessageMinimal = PinMessageMinimal.fromJsonString(
              message.content ?? '',
            );
            if (pinMessageMinimal == null) return null;
            final preview = await generatePinPreviewText(
              pinMessageMinimal: pinMessageMinimal,
              mentionCache: context.providerContainer.read(
                mentionCacheProvider,
              ),
            );

            return context.l10n.chatPinMessage(
              message.userFullName ?? '',
              preview,
            );
          });
    },
    keys: [showLastPinMessage, conversationId, pinMessageIds.firstOrNull],
  ).data;

  return useMemoized(
    () =>
        PinMessageState(messageIds: pinMessageIds, lastMessage: previewContent),
    [previewContent, pinMessageIds],
  );
}
