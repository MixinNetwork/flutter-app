import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../db/mixin_database.dart' hide Offset, Message;
import '../../../enum/media_status.dart';
import '../../../utils/audio_message_player/audio_message_service.dart';
import '../../../utils/extension/extension.dart';
import '../../interactive_decorated_box.dart';
import '../../status.dart';
import '../../waveform_widget.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';
import '../message_style.dart';
import 'transcript_message.dart';

class AudioMessage extends HookConsumerWidget {
  const AudioMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTranscriptPage = useIsTranscriptPage();
    final messageId =
        useMessageConverter(converter: (state) => state.messageId);
    final mediaStatus =
        useMessageConverter(converter: (state) => state.mediaStatus);
    final relationship =
        useMessageConverter(converter: (state) => state.relationship);
    final mediaUrl = useMessageConverter(converter: (state) => state.mediaUrl);

    final playing =
        useAudioMessagePlaying(messageId, isMediaList: isTranscriptPage);

    final duration = useMessageConverter(
      converter: (state) => Duration(
        milliseconds: int.tryParse(state.mediaDuration ?? '') ?? 0,
      ),
    );

    final isMessageSentOut = (isTranscriptPage &&
            TranscriptPage.of(context)?.relationship == UserRelationship.me) ||
        (!isTranscriptPage && relationship == UserRelationship.me);

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
                context.audioMessageService.stop();
                return;
              }

              if (context.audioMessagesPlayAgent != null) {
                context.audioMessageService.playMessages(
                  context.audioMessagesPlayAgent!
                      .getMessages(message.messageId),
                  context.audioMessagesPlayAgent!.convertMessageAbsolutePath,
                );
                return;
              }
              context.audioMessageService.playAudioMessage(message);
              break;
            case MediaStatus.canceled:
              if (isMessageSentOut && message.mediaUrl?.isNotEmpty == true) {
                if (isTranscriptPage) {
                  final transcriptMessageId =
                      TranscriptPage.of(context)?.messageId;
                  context.accountServer
                      .reUploadTranscriptAttachment(transcriptMessageId!);
                } else {
                  context.accountServer.reUploadAttachment(message);
                }
              } else {
                context.accountServer.downloadAttachment(message.messageId);
              }
              break;
            case MediaStatus.pending:
              context.accountServer
                  .cancelProgressAttachmentJob(message.messageId);
              break;
            case MediaStatus.expired:
            case null:
              break;
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              builder: (BuildContext context) {
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
                  _AnimatedWave(
                    duration: duration,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    duration.asMinutesSeconds,
                    style: TextStyle(
                      fontSize:
                          ref.watch(messageStyleProvider).tertiaryFontSize,
                      color: context.theme.secondaryText,
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
  const _AnimatedWave({
    required this.duration,
  });

  final Duration duration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaWaveform =
        useMessageConverter(converter: (state) => state.mediaWaveform ?? '');
    final mediaStatus =
        useMessageConverter(converter: (state) => state.mediaStatus);
    final messageId =
        useMessageConverter(converter: (state) => state.messageId);

    final waveform =
        useMemoized(() => base64Decode(mediaWaveform), [mediaWaveform]);

    final read = mediaStatus == MediaStatus.read;
    final isTranscriptPage = useIsTranscriptPage();
    final playing = useAudioMessagePlaying(
      messageId,
      isMediaList: isTranscriptPage,
    );

    final isMe = useMessageConverter(
        converter: (state) => state.relationship == UserRelationship.me);

    final position =
        (useAudioPlayerPosition() / duration.inMilliseconds).clamp(0.0, 1.0);

    return SizedBox(
      height: 12,
      child: WaveformWidget(
        value: playing ? position : 0,
        waveform: waveform,
        backgroundColor: isMe || read
            ? context.theme.waveformBackground
            : context.theme.accent,
        foregroundColor: isMe || read
            ? context.theme.waveformForeground
            : context.theme.accent,
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

extension _AudioMessagesPlayAgentExtension on BuildContext {
  AudioMessagesPlayAgent? get audioMessagesPlayAgent {
    try {
      return read<AudioMessagesPlayAgent>();
    } catch (e) {
      return null;
    }
  }
}
