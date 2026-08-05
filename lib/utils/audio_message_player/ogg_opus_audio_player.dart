import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:rxdart/rxdart.dart';

import '../../db/mixin_database.dart';
import '../extension/extension.dart';
import '../logger.dart';

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
  completed;

  bool get isPlaying => this == PlaybackState.playing;

  bool get isCompleted => this == PlaybackState.completed;
}

class AudioMessagePlayer {
  AudioMessagePlayer() {
    _subscriptions.addAll([
      _player.stream.playing.listen(_handlePlaying),
      _player.stream.completed.listen(_handleCompleted),
      _player.stream.error.listen(_handleError),
    ]);
  }

  final _currentPlaying = BehaviorSubject<MessageMedia?>();

  final Player _player = Player();

  final _subscriptions = <StreamSubscription<dynamic>>[];

  final List<MessageMedia> _medias = [];

  int _index = -1;

  final _playbackState = BehaviorSubject.seeded(PlaybackState.idle);

  final _playbackSpeed = BehaviorSubject<double>.seeded(1);

  Stream<MessageMedia?> get currentStream => _currentPlaying.stream;

  Stream<double> get playbackSpeedStream => _playbackSpeed.stream;

  void dispose() {
    stop();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_player.dispose());
    _medias.clear();
    _index = -1;
  }

  PlaybackState get playbackState => _playbackState.value;

  MessageMedia? get current => _medias.getOrNull(_index);

  void play(List<MessageMedia> media, {bool resetPlaySpeed = true}) {
    stop();
    _medias.clear();
    _index = -1;

    if (resetPlaySpeed) {
      _playbackSpeed.value = 1;
    }

    if (media.isEmpty) {
      return;
    }
    _medias.addAll(media);
    _playNext();
  }

  void _playNext() {
    if (_index >= _medias.length - 1) {
      _playbackState.value = PlaybackState.completed;
      return;
    }
    if (_index < 0) {
      _index = 0;
    } else {
      _index++;
    }
    final media = _medias[_index];
    _currentPlaying.value = current;
    unawaited(_open(media));
  }

  Future<void> _open(MessageMedia media) async {
    try {
      await _player.open(Media(media.mediaPath));
      await _player.setRate(_playbackSpeed.value);
    } catch (error, stacktrace) {
      e('play ${media.mediaPath} failed: $error $stacktrace');
      stop();
    }
  }

  void _handlePlaying(bool playing) {
    if (playing) {
      _playbackState.value = PlaybackState.playing;
    } else if (_playbackState.value == PlaybackState.playing) {
      _playbackState.value = PlaybackState.paused;
    }
  }

  void _handleCompleted(bool completed) {
    if (completed) {
      _playNext();
    }
  }

  void _handleError(String error) {
    e('play ${current?.mediaPath} failed: $error');
    stop();
  }

  Stream<PlaybackState> get playbackStream => _playbackState.stream;

  void stop() {
    unawaited(_player.stop());
    _playbackState.value = PlaybackState.idle;
  }

  void pause() {
    unawaited(_player.pause());
  }

  void resume() {
    assert(
      _playbackState.value == PlaybackState.paused,
      'resume failed, player is not paused.',
    );
    unawaited(_player.play());
    _playbackState.value = PlaybackState.playing;
  }

  Duration currentPosition() => _player.state.position;

  void setPlaybackSpeed(double speed) {
    _playbackSpeed.value = speed;
    unawaited(_player.setRate(speed));
  }
}
