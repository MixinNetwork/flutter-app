import 'dart:async';

import 'package:ogg_opus_player/ogg_opus_player.dart';
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
  final _currentPlaying = BehaviorSubject<MessageMedia?>();

  OggOpusPlayer? _player;

  final List<MessageMedia> _medias = [];

  int _index = -1;

  final _playbackState = BehaviorSubject.seeded(PlaybackState.idle);

  final _playbackSpeed = BehaviorSubject<double>.seeded(1);

  Stream<MessageMedia?> get currentStream => _currentPlaying.stream;

  Stream<double> get playbackSpeedStream => _playbackSpeed.stream;

  void dispose() {
    stop();
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
      // play ended.
      _disposeCurrentPlayer();
      _playbackState.value = PlaybackState.completed;
      return;
    }
    if (_index < 0) {
      _index = 0;
    } else {
      _index++;
    }
    _disposeCurrentPlayer();
    final media = _medias[_index];
    final player = OggOpusPlayer(media.mediaPath);
    assert(_player == null);
    _player = player;
    player.state.addListener(_handlePlayerState);
    player
      ..play()
      ..setPlaybackRate(_playbackSpeed.value);
    _currentPlaying.value = current;
  }

  void _handlePlayerState() {
    final player = _player;
    if (player == null) {
      return;
    }
    const interceptedEventType = {
      PlayerState.idle,
      PlayerState.error,
      PlayerState.ended,
    };
    final state = player.state.value;
    if (!interceptedEventType.contains(state)) {
      if (state == PlayerState.paused) {
        _playbackState.value = PlaybackState.paused;
      } else if (state == PlayerState.playing) {
        _playbackState.value = PlaybackState.playing;
      }
    }
    if (state == PlayerState.ended) {
      _playNext();
    } else if (state == PlayerState.error) {
      i('play ${current?.mediaPath} failed.');
      stop();
    }
  }

  Stream<PlaybackState> get playbackStream => _playbackState.stream;

  void _disposeCurrentPlayer() {
    _player?.state.removeListener(_handlePlayerState);
    _player?.dispose();
    _player = null;
  }

  void stop() {
    _disposeCurrentPlayer();
    _playbackState.value = PlaybackState.idle;
  }

  void pause() {
    _player?.pause();
  }

  void resume() {
    if (_player == null) {
      e('resume failed, player is null.');
      return;
    }
    assert(
      _playbackState.value == PlaybackState.paused,
      'resume failed, player is not paused.',
    );
    _player?.play();
    _playbackState.value = PlaybackState.playing;
  }

  Duration currentPosition() =>
      Duration(milliseconds: ((_player?.currentPosition ?? 0) * 1000).toInt());

  void setPlaybackSpeed(double speed) {
    _playbackSpeed.value = speed;
    _player?.setPlaybackRate(speed);
  }
}
