import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../../account/notification_service.dart';
import '../../../account/show_pin_message_key_value.dart';
import '../../../blaze/vo/pin_message_minimal.dart';
import '../../../db/dao/conversation_dao.dart';
import '../../../db/database_event_bus.dart';
import '../../../db/mixin_database.dart';
import '../../../paging/paging_controller.dart';
import '../../../ui/provider/abstract_responsive_navigator.dart';
import '../../../ui/provider/account_server_provider.dart';
import '../../../ui/provider/conversation_provider.dart';
import '../../../ui/provider/database_provider.dart';
import '../../../ui/provider/mention_cache_provider.dart';
import '../../../ui/provider/multi_auth_provider.dart';
import '../../../ui/provider/setting_provider.dart';
import '../../../ui/provider/slide_category_provider.dart';
import '../../../ui/provider/ui_context_providers.dart';
import '../../../utils/audio_message_player/audio_message_service.dart';
import '../../../utils/extension/extension.dart';
import '../../../widgets/message/item/audio_message.dart';
import '../../../widgets/message/item/pin_message.dart';
import '../../home/chat/chat_page.dart';
import '../../home/controllers/conversation_list_controller.dart';
import '../../home/controllers/message_controller.dart';
import '../../home/hook/pin_message.dart';
import '../chat/voice_recorder_bottom_bar.dart';
import '../home.dart';

export '../controllers/blink_controller.dart'
    show blinkColorProvider, blinkControllerProvider;

StateError _missingScopeProvider(String name) =>
    StateError('$name is not available in the current ProviderScope');

final conversationListControllerProvider =
    NotifierProvider.autoDispose<
      ConversationListController,
      PagingState<ConversationItem>
    >(ConversationListController.new);

final notificationServiceProvider = Provider.autoDispose<NotificationService>((
  ref,
) {
  // depends on buildContextProvider via ref.watch
  final accountServer = ref.watch(accountServerProvider).value;
  final database = ref.watch(databaseProvider).value;
  final context = ref.watch(buildContextProvider);
  if (accountServer == null || database == null) {
    throw _missingScopeProvider('NotificationService');
  }
  final service = NotificationService(
    context: context,
    accountServer: accountServer,
    database: database,
    settings: ref.watch(settingProvider.notifier),
    mentionCache: ref.watch(mentionCacheProvider),
    readAccount: () => ref.read(authAccountProvider),
    readConversationState: () => ref.read(conversationProvider),
    switchToChatsIfSettings: () =>
        ref.read(slideCategoryProvider.notifier).switchToChatsIfSettings(),
    selectConversation: (context, conversationId, {initIndexMessageId}) =>
        ConversationStateNotifier.selectConversation(
          ref.container,
          context,
          conversationId,
          initIndexMessageId: initIndexMessageId,
        ),
  );
  ref.onDispose(service.close);
  return service;
}, dependencies: [buildContextProvider]);

final audioMessagePlayServiceProvider =
    Provider.autoDispose<AudioMessagePlayService>((
      ref,
    ) {
      final accountServer = ref.watch(accountServerProvider).value;
      if (accountServer == null) {
        throw _missingScopeProvider('AudioMessagePlayService');
      }

      final service = AudioMessagePlayService(accountServer);
      ref.onDispose(service.dispose);
      return service;
    });

final currentPlayingAudioMessageProvider =
    StreamProvider.autoDispose<MessageItem?>((ref) {
      final service = ref.watch(audioMessagePlayServiceProvider);
      return service.currentMessageStream;
    });

final audioPlayerPlaybackStateProvider =
    StreamProvider.autoDispose<PlaybackState>((ref) {
      final service = ref.watch(audioMessagePlayServiceProvider);
      return service.playbackStateStream;
    });

final audioPlayerSpeedProvider = StreamProvider.autoDispose<double>((ref) {
  final service = ref.watch(audioMessagePlayServiceProvider);
  return service.playbackSpeedStream;
});

final audioPlayerPositionProvider = StreamProvider.autoDispose<double>((ref) {
  final service = ref.watch(audioMessagePlayServiceProvider);
  return service.positionStream;
});

final audioMessagePlayingProvider = Provider.autoDispose
    .family<bool, ({String messageId, bool isMediaList})>((ref, args) {
      final playbackState =
          ref.watch(audioPlayerPlaybackStateProvider).value ??
          PlaybackState.idle;
      final currentMessage = ref
          .watch(currentPlayingAudioMessageProvider)
          .value;
      if (!playbackState.isPlaying) {
        return false;
      }
      return currentMessage?.messageId == args.messageId &&
          serviceIsMediaList(ref) == args.isMediaList;
    });

bool serviceIsMediaList(Ref ref) =>
    ref.watch(audioMessagePlayServiceProvider).isMediaList;

final chatInputTextValueStreamProvider = Provider.autoDispose
    .family<Stream<TextEditingValue>, TextEditingController>((ref, controller) {
      late final StreamController<TextEditingValue> streamController;
      streamController = StreamController<TextEditingValue>.broadcast(
        onListen: () {
          if (!streamController.isClosed) {
            streamController.add(controller.value);
          }
        },
      );

      void listener() {
        if (!streamController.isClosed) {
          streamController.add(controller.value);
        }
      }

      controller.addListener(listener);
      ref.onDispose(() {
        controller.removeListener(listener);
        unawaited(streamController.close());
      });
      return streamController.stream.startWith(controller.value);
    });

final chatInputTextValueProvider = StreamProvider.autoDispose
    .family<TextEditingValue, TextEditingController>(
      (ref, controller) =>
          ref.watch(chatInputTextValueStreamProvider(controller)),
    );

final chatSideControllerProvider =
    NotifierProvider.autoDispose<ChatSideController, ResponsiveNavigatorState>(
      ChatSideController.new,
    );

final searchConversationKeywordControllerProvider =
    NotifierProvider.autoDispose<
      SearchConversationKeywordController,
      (String?, String)
    >(SearchConversationKeywordController.new);

final searchConversationKeywordForUserProvider = Provider.autoDispose
    .family<String, String?>((ref, userId) {
      final state = ref.watch(searchConversationKeywordControllerProvider);
      if (state.$1 == null || state.$1 == userId) {
        return state.$2;
      }
      return '';
    });

final searchConversationKeywordDebouncedProvider =
    StreamProvider.autoDispose<String>((ref) {
      final controller = ref.read(
        searchConversationKeywordControllerProvider.notifier,
      );
      return controller.stream
          .map((event) => event.$2.trim())
          .startWith(
            ref.read(searchConversationKeywordControllerProvider).$2.trim(),
          )
          .debounceTime(const Duration(milliseconds: 150));
    });
final messagePageLimitProvider = Provider<int>(
  (ref) => (ref.watch(mediaQueryDataProvider).size.height ~/ 20).clamp(1, 1000),
  dependencies: [mediaQueryDataProvider],
);

final pinMessageIdsProvider = StreamProvider.autoDispose
    .family<List<String>, String>((ref, conversationId) {
      final database = ref.watch(databaseProvider).value;
      if (database == null) {
        return Stream.value(const <String>[]);
      }

      return database.pinMessageDao
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
    });

final showLastPinMessageProvider = StreamProvider.autoDispose
    .family<bool, String>(
      (ref, conversationId) =>
          ShowPinMessageKeyValue.instance.watch(conversationId),
    );

final pinMessagePreviewProvider = StreamProvider.autoDispose
    .family<PinMessagePreview?, String>((ref, conversationId) {
      final database = ref.watch(databaseProvider).value;
      if (database == null) {
        return Stream.value(null);
      }

      final showLastPinMessage =
          ref.watch(showLastPinMessageProvider(conversationId)).value ?? false;
      final messageId = ref
          .watch(pinMessageIdsProvider(conversationId))
          .value
          ?.firstOrNull;
      if (!showLastPinMessage || messageId == null) {
        return Stream.value(null);
      }

      return database.pinMessageDao
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
              mentionCache: ref.watch(mentionCacheProvider),
            );
            return PinMessagePreview(
              senderFullName: message.userFullName ?? '',
              preview: preview,
            );
          });
    });

final pinnedMessagesProvider = StreamProvider.autoDispose
    .family<List<MessageItem>, String>((ref, conversationId) {
      final database = ref.watch(databaseProvider).value;
      if (database == null) {
        return Stream.value(const <MessageItem>[]);
      }

      return database.pinMessageDao
          .messageItems(conversationId)
          .watchWithStream(
            eventStreams: [
              DataBaseEventBus.instance.watchPinMessageStream(
                conversationIds: [conversationId],
              ),
              DataBaseEventBus.instance.updateAssetStream,
              DataBaseEventBus.instance.updateStickerStream,
            ],
            duration: kSlowThrottleDuration,
          );
    });

final pinnedAudioMessagesPlayAgentProvider = Provider.autoDispose
    .family<AudioMessagesPlayAgent?, String>((ref, conversationId) {
      final accountServer = ref.watch(accountServerProvider).value;
      if (accountServer == null) {
        return null;
      }

      final messages =
          ref.watch(pinnedMessagesProvider(conversationId)).value ??
          const <MessageItem>[];
      return AudioMessagesPlayAgent(
        messages.reversed.toList(),
        (message) => accountServer.convertMessageAbsolutePath(message, true),
      );
    });

final messageControllerProvider =
    NotifierProvider.autoDispose<MessageController, MessageState>(
      MessageController.new,
      dependencies: [messagePageLimitProvider],
    );

final pinMessageStateProvider = Provider.autoDispose<PinMessageState>((ref) {
  final conversationId = ref.watch(currentConversationIdProvider);
  if (conversationId == null) {
    return const PinMessageState(messageIds: []);
  }

  return PinMessageState(
    messageIds:
        ref.watch(pinMessageIdsProvider(conversationId)).value ??
        const <String>[],
    lastMessage: ref.watch(pinMessagePreviewProvider(conversationId)).value,
  );
});

final voiceRecorderControllerProvider =
    NotifierProvider.autoDispose<VoiceRecorderController, VoiceRecorderState>(
      VoiceRecorderController.new,
    );

final stickerAlbumsProvider = StreamProvider.autoDispose<List<StickerAlbum>>((
  ref,
) {
  final database = ref.watch(databaseProvider).value;
  if (database == null) {
    return Stream.value(const <StickerAlbum>[]);
  }

  return database.stickerAlbumDao.systemAddedAlbums().watchWithStream(
    eventStreams: [DataBaseEventBus.instance.updateStickerStream],
    duration: kVerySlowThrottleDuration,
  );
});
