import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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

class AudioMessage extends HookWidget {
  const AudioMessage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              if (message.relationship == UserRelationship.me &&
                  message.mediaUrl?.isNotEmpty == true) {
                context.accountServer.reUploadAttachment(message);
              } else {
                context.accountServer.downloadAttachment(message);
              }
              break;
            case MediaStatus.pending:
              context.accountServer
                  .cancelProgressAttachmentJob(message.messageId);
              break;
            default:
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
                    if (relationship == UserRelationship.me &&
                        mediaUrl?.isNotEmpty == true) {
                      return const StatusUpload();
                    } else {
                      return const StatusDownload();
                    }
                  case MediaStatus.pending:
                    return const StatusPending();
                  case MediaStatus.expired:
                    return const StatusWarning();
                  default:
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
                      fontSize: MessageItemWidget.tertiaryFontSize,
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

class _AnimatedWave extends HookWidget {
  const _AnimatedWave({
    Key? key,
    required this.duration,
  }) : super(key: key);

  final Duration duration;

  @override
  Widget build(BuildContext context) {
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

    double getPlayingFriction() {
      final friction =
          (context.audioMessageService.currentPosition.inMilliseconds) /
              duration.inMilliseconds;
      return friction.clamp(0.0, 1.0);
    }

    final position = useState(playing ? getPlayingFriction() : 0.0);

    final tickerProvider = useSingleTickerProvider();
    final ticker = useMemoized(
        () => tickerProvider.createTicker((elapsed) {
              final newValue = getPlayingFriction();
              // Avoid update too often. since there is performance issue in Flutter.
              // https://github.com/flutter/flutter/issues/85781
              if (newValue == 0 ||
                  newValue == 1 ||
                  (newValue - position.value).abs() > 0.01) {
                position.value = newValue;
              }
            }),
        [tickerProvider]);
    useEffect(() => ticker.dispose, [ticker]);
    useEffect(() {
      if (playing) {
        ticker.start();
      } else {
        ticker.stop();
        position.value = 0;
      }
    }, [playing]);

    return SizedBox(
      height: 12,
      child: WaveformWidget(
        value: position.value,
        waveform: waveform,
        backgroundColor:
            read ? context.theme.waveformBackground : context.theme.accent,
        foregroundColor:
            read ? context.theme.waveformForeground : context.theme.accent,
      ),
    );
  }
}

class AudioMessagesPlayAgent {
  AudioMessagesPlayAgent(
    this._list,
    this.convertMessageAbsolutePath,
  );

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
