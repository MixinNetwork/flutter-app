import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../db/mixin_database.dart' hide Offset, Message;
import '../../../enum/media_status.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/vlc_service.dart';
import '../../interacter_decorated_box.dart';
import '../../status.dart';
import '../../waveform_widget.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';

class AudioMessage extends HookWidget {
  const AudioMessage({
    Key? key,
    required this.showNip,
    required this.isCurrentUser,
    required this.message,
    required this.pinArrow,
  }) : super(key: key);

  final bool showNip;
  final bool isCurrentUser;
  final MessageItem message;
  final Widget? pinArrow;

  @override
  Widget build(BuildContext context) {
    final playing = useAudioMessagePlaying(
      message.messageId,
      isMediaList: context.isTranscript,
    );

    final duration = useMemoized(
        () => Duration(
              milliseconds: int.tryParse(message.mediaDuration ?? '') ?? 0,
            ),
        [message.mediaDuration]);

    final waveform = useMemoized(
      () => base64Decode(message.mediaWaveform ?? ''),
      [message.mediaWaveform],
    );

    return MessageBubble(
      messageId: message.messageId,
      showNip: showNip,
      isCurrentUser: isCurrentUser,
      pinArrow: pinArrow,
      outerTimeAndStatusWidget: MessageDatetimeAndStatus(
        showStatus: isCurrentUser,
        message: message,
      ),
      forceIsCurrentUserColor: false,
      child: InteractiveDecoratedBox(
        onTap: () {
          switch (message.mediaStatus) {
            case MediaStatus.read:
            case MediaStatus.done:
              if (playing) {
                context.vlcService.stop();
                return;
              }

              if (context.audioMessagesPlayAgent != null) {
                context.vlcService.playMessages(
                  context.audioMessagesPlayAgent!
                      .getMessages(message.messageId),
                  context.audioMessagesPlayAgent!.convertMessageAbsolutePath,
                );
                return;
              }
              context.vlcService.playAudioMessage(message);
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
                switch (message.mediaStatus) {
                  case MediaStatus.canceled:
                    if (message.relationship == UserRelationship.me &&
                        message.mediaUrl?.isNotEmpty == true) {
                      return const StatusUpload();
                    } else {
                      return const StatusDownload();
                    }
                  case MediaStatus.pending:
                    return StatusPending(messageId: message.messageId);
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
                  SizedBox(
                    height: 12,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: playing ? 1 : 0),
                      duration: playing ? duration : Duration.zero,
                      builder: (context, value, _) => WaveformWidget(
                        value: value,
                        width: 50,
                        waveform: waveform,
                        duration: duration.inSeconds,
                        backgroundColor: message.mediaStatus == MediaStatus.read
                            ? context.theme.waveformBackground
                            : context.theme.accent,
                        foregroundColor: message.mediaStatus == MediaStatus.read
                            ? context.theme.waveformForeground
                            : context.theme.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${duration.inSeconds}‘',
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
