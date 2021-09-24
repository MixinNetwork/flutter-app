import 'dart:io';

import 'package:equatable/equatable.dart';

import '../../db/mixin_database.dart';
import 'ogg_opus_audio_player.dart';
import 'vlc_audio_player.dart';

class MessageMedia {
  const MessageMedia(
    this.messageItem, {
    required this.convertMessageAbsolutePath,
  });

  final MessageItem messageItem;
  final String Function(MessageItem) convertMessageAbsolutePath;

  String get mediaPath => convertMessageAbsolutePath(messageItem);
}

abstract class PlaybackState extends Equatable {
  bool get isCompleted;

  bool get isPlaying;

  @override
  List<Object> get props => [
        isCompleted,
        isPlaying,
      ];
}

abstract class AudioMessagePlayer {
  AudioMessagePlayer();

  factory AudioMessagePlayer.vlc() => VlcAudioMessagePlayer();

  factory AudioMessagePlayer.oggOpus() => OggOpusAudioMessagePlayer();

  factory AudioMessagePlayer.platform() {
    if (Platform.isIOS || Platform.isMacOS) {
      return AudioMessagePlayer.oggOpus();
    }
    return AudioMessagePlayer.vlc();
  }

  bool get isPlaying;

  MessageMedia? get current;

  Stream<MessageMedia?> get currentStream;

  Stream<PlaybackState> get playbackStream;

  void dispose();

  void stop();

  void play(List<MessageMedia> media);
}
