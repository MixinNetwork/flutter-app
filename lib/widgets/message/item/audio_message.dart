import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../db/mixin_database.dart' hide Message, Offset;
import '../../../enum/media_status.dart';
import '../../../ui/home/providers/home_scope_providers.dart';
import '../../../ui/provider/account_server_provider.dart';
import '../../../ui/provider/conversation_provider.dart';
import '../../../ui/provider/ui_context_providers.dart';
import '../../../utils/extension/extension.dart';
import '../../interactive_decorated_box.dart';
import '../../status.dart';
import '../../waveform_widget.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';
import '../message_style.dart';
import 'transcript_message.dart';

class AudioMessage extends ConsumerWidget {
  const AudioMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final isTranscriptPage = useIsTranscriptPage();
    final isPinnedPage = useIsPinnedPage();
    final messageId = useMessageConverter(
      converter: (state) => state.messageId,
    );
    final mediaStatus = useMessageConverter(
      converter: (state) => state.mediaStatus,
    );
    final relationship = useMessageConverter(
      converter: (state) => state.relationship,
    );
    final mediaUrl = useMessageConverter(converter: (state) => state.mediaUrl);

    final playing = ref.watch(
      audioMessagePlayingProvider((
        messageId: messageId,
        isMediaList: isTranscriptPage,
      )),
    );

    final duration = useMessageConverter(
      converter: (state) => Duration(
        milliseconds: int.tryParse(state.mediaDuration ?? '') ?? 0,
      ),
    );

    final isMessageSentOut =
        (isTranscriptPage &&
            TranscriptPage.of(context)?.relationship == UserRelationship.me) ||
        (!isTranscriptPage && relationship == UserRelationship.me);
    final audioService = ref.read(audioMessagePlayServiceProvider);
    AudioMessagesPlayAgent? audioMessagesPlayAgent;
    if (isTranscriptPage) {
      final transcriptMessageId = TranscriptPage.of(context)?.messageId;
      if (transcriptMessageId != null) {
        audioMessagesPlayAgent = ref.read(
          transcriptAudioMessagesPlayAgentProvider(transcriptMessageId),
        );
      }
    } else if (isPinnedPage) {
      final conversationId = ref.read(currentConversationIdProvider);
      if (conversationId != null) {
        audioMessagesPlayAgent = ref.read(
          pinnedAudioMessagesPlayAgentProvider(conversationId),
        );
      }
    }

    return MessageBubble(
      outerTimeAndStatusWidget: const MessageDatetimeAndStatus(),
      forceIsCurrentUserColor: false,
      child: InteractiveDecoratedBox(
        onTap: () {
          final message = context.message;
          switch (message.mediaStatus) {
            case MediaStatus.read:
            case MediaStatus.done:
              if (playing) {
                audioService.stop();
                return;
              }

              if (audioMessagesPlayAgent != null) {
                audioService.playMessages(
                  audioMessagesPlayAgent.getMessages(
                    message.messageId,
                  ),
                  audioMessagesPlayAgent.convertMessageAbsolutePath,
                );
                return;
              }
              audioService.playAudioMessage(message);
            case MediaStatus.canceled:
              if (isMessageSentOut && message.mediaUrl?.isNotEmpty == true) {
                final accountServer = ref
                    .read(accountServerProvider)
                    .requireValue;
                if (isTranscriptPage) {
                  final transcriptMessageId = TranscriptPage.of(
                    context,
                  )?.messageId;
                  accountServer.reUploadTranscriptAttachment(
                    transcriptMessageId!,
                  );
                } else {
                  accountServer.reUploadAttachment(message);
                }
              } else {
                ref
                    .read(accountServerProvider)
                    .requireValue
                    .downloadAttachment(message.messageId);
              }
            case MediaStatus.pending:
              ref
                  .read(accountServerProvider)
                  .requireValue
                  .cancelProgressAttachmentJob(message.messageId);
            case MediaStatus.expired:
            case null:
              break;
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              builder: (context) {
                switch (mediaStatus) {
                  case MediaStatus.canceled:
                    return isMessageSentOut && mediaUrl?.isNotEmpty == true
                        ? const StatusUpload()
                        : const StatusDownload();
                  case MediaStatus.pending:
                    return const StatusPending();
                  case MediaStatus.expired:
                    return const StatusWarning();
                  case MediaStatus.done:
                  case MediaStatus.read:
                  case null:
                    return playing
                        ? const StatusAudioStop()
                        : const StatusAudioPlay();
                }
              },
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 238,
                    child: _AnimatedWave(duration: duration),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    duration.asMinutesSeconds,
                    style: TextStyle(
                      fontSize: context.messageStyle.tertiaryFontSize,
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedWave extends HookConsumerWidget {
  const _AnimatedWave({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final mediaWaveform = useMessageConverter(
      converter: (state) => state.mediaWaveform ?? '',
    );
    final mediaStatus = useMessageConverter(
      converter: (state) => state.mediaStatus,
    );
    final messageId = useMessageConverter(
      converter: (state) => state.messageId,
    );

    final waveform = useMemoized(
      () => base64Decode(mediaWaveform),
      [mediaWaveform],
    );

    final read = mediaStatus == MediaStatus.read;
    final isTranscriptPage = useIsTranscriptPage();
    final playing = ref.watch(
      audioMessagePlayingProvider((
        messageId: messageId,
        isMediaList: isTranscriptPage,
      )),
    );

    final isMe = useMessageConverter(
      converter: (state) => state.relationship == UserRelationship.me,
    );

    final position =
        ((ref.watch(audioPlayerPositionProvider).value ?? 0) /
                duration.inMilliseconds)
            .clamp(0.0, 1.0);

    return SizedBox(
      height: 12,
      child: WaveformWidget(
        value: playing ? position : 0,
        waveform: waveform,
        backgroundColor: isMe || read ? theme.waveformBackground : theme.accent,
        foregroundColor: isMe || read ? theme.waveformForeground : theme.accent,
      ),
    );
  }
}

class AudioMessagesPlayAgent {
  AudioMessagesPlayAgent(
    List<MessageItem> list,
    this.convertMessageAbsolutePath,
  ) : _list = list.where((e) => e.type.isAudio).toList();

  final List<MessageItem> _list;
  final String Function(MessageItem? messageItem) convertMessageAbsolutePath;

  List<MessageItem> getMessages(String messageId) {
    final index = _list.indexWhere((element) => element.messageId == messageId);
    if (index == -1) return [];
    return _list.sublist(index);
  }
}

final transcriptAudioMessagesPlayAgentProvider = Provider.autoDispose
    .family<AudioMessagesPlayAgent?, String>((
      ref,
      transcriptMessageId,
    ) {
      final list =
          ref.watch(transcriptMessagesProvider(transcriptMessageId)).value ??
          const <MessageItem>[];
      final accountServer = ref.watch(accountServerProvider).value;
      if (accountServer == null) {
        return null;
      }
      return AudioMessagesPlayAgent(
        list,
        (message) => accountServer.convertMessageAbsolutePath(message, true),
      );
    });
