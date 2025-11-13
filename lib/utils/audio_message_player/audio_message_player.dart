import '../../db/mixin_database.dart';
import 'ogg_opus_audio_player.dart';

class MessageMedia {
  const MessageMedia(
    this.messageItem, {
    required this.convertMessageAbsolutePath,
  });

  final MessageItem messageItem;
  final String Function(MessageItem) convertMessageAbsolutePath;

  String get mediaPath => convertMessageAbsolutePath(messageItem);
}

enum PlaybackState {
  idle,
  playing,
  paused,
  completed
  ;

  bool get isPlaying => this == PlaybackState.playing;

  bool get isCompleted => this == PlaybackState.completed;
}

abstract class AudioMessagePlayer {
  AudioMessagePlayer();

  factory AudioMessagePlayer.oggOpus() => OggOpusAudioMessagePlayer();

  PlaybackState get playbackState;

  MessageMedia? get current;

  Stream<MessageMedia?> get currentStream;

  Stream<PlaybackState> get playbackStream;

  Stream<double> get playbackSpeedStream;

  void dispose();

  void stop();

  void pause();

  void resume();

  void play(List<MessageMedia> media, {bool resetPlaySpeed = true});

  Duration currentPosition();

  void setPlaybackSpeed(double speed);
}
