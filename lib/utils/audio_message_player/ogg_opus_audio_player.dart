import 'dart:async';

import 'package:ogg_opus_player/ogg_opus_player.dart';
import 'package:rxdart/rxdart.dart';

import '../extension/extension.dart';
import '../logger.dart';
import 'audio_message_service.dart';

class _OggOpusPlaybackState extends PlaybackState {
  _OggOpusPlaybackState(this._state);

  final PlayerState _state;

  @override
  bool get isCompleted => _state == PlayerState.ended;

  @override
  bool get isPlaying => _state == PlayerState.playing;
}

class OggOpusAudioMessagePlayer extends AudioMessagePlayer {
  final _currentPlaying = BehaviorSubject<MessageMedia?>();

  OggOpusPlayer? _player;

  final List<MessageMedia> _medias = [];

  int _index = -1;

  final _playbackState = BehaviorSubject.seeded(PlayerState.idle);

  @override
  Stream<MessageMedia?> get currentStream => _currentPlaying.stream;

  @override
  void dispose() {
    stop();
    _medias.clear();
    _index = -1;
  }

  @override
  bool get isPlaying => _playbackState.value == PlayerState.playing;

  @override
  MessageMedia? get current => _medias.getOrNull(_index);

  @override
  void play(List<MessageMedia> media) {
    stop();
    _medias.clear();
    _index = -1;

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
      _playbackState.value = PlayerState.ended;
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
    player.state.addListener(_handlePlayerState);
    player.play();
    assert(_player == null);
    _player = player;
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
      _playbackState.value = state;
    }
    if (state == PlayerState.ended) {
      _playNext();
    } else if (state == PlayerState.error) {
      i('play ${current?.mediaPath} failed.');
    }
  }

  @override
  Stream<PlaybackState> get playbackStream => _playbackState.stream
      .distinct()
      .map((event) => _OggOpusPlaybackState(event));

  void _disposeCurrentPlayer() {
    _player?.state.removeListener(_handlePlayerState);
    _player?.dispose();
    _player = null;
  }

  @override
  void stop() {
    _disposeCurrentPlayer();
    _playbackState.value = PlayerState.idle;
  }

  @override
  Duration currentPosition() =>
      Duration(milliseconds: ((_player?.currentPosition ?? 0) * 1000).toInt());
}
