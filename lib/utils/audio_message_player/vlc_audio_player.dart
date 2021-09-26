import 'dart:async';

import 'package:dart_vlc/dart_vlc.dart' as vlc;
import 'package:extended_image/extended_image.dart';
import 'package:rxdart/rxdart.dart';

import '../extension/extension.dart';
import 'audio_message_player.dart';

class _VlcPlaybackState extends PlaybackState {
  _VlcPlaybackState(this._state);

  final vlc.PlaybackState _state;

  @override
  bool get isCompleted => _state.isCompleted;

  @override
  bool get isPlaying => _state.isPlaying;
}

class VlcAudioMessagePlayer extends AudioMessagePlayer {
  VlcAudioMessagePlayer() {
    _subscription = _player.playbackController.stream
        .map((event) => event.isPlaying)
        .distinct()
        .listen((playing) {
      _position = _player.position.position?.inMilliseconds ?? 0;
      assert(_position >= 0);
      _lastUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;
    });
  }

  final _player = vlc.Player(id: 64);

  final List<MessageMedia> _medias = [];

  StreamSubscription? _subscription;

  int _position = 0;
  int _lastUpdateTimestamp = -1;

  @override
  void dispose() {
    _subscription?.cancel();
    _player.dispose();
  }

  @override
  bool get isPlaying => _player.playback.isPlaying;

  @override
  Stream<MessageMedia?> get currentStream =>
      _player.currentController.stream.startWith(_player.current).map((event) =>
          event.index == null ? null : _medias.getOrNull(event.index!));

  @override
  MessageMedia? get current => _player.current.index == null
      ? null
      : _medias.getOrNull(_player.current.index!);

  @override
  void play(List<MessageMedia> media) {
    _medias.clear();
    final vlcMedias =
        media.map((e) => vlc.Media.file(File(e.mediaPath))).toList();
    _player.open(vlc.Playlist(medias: vlcMedias));
    _medias.addAll(media);
  }

  @override
  Stream<PlaybackState> get playbackStream => _player.playbackController.stream
      .startWith(_player.playback)
      .map((event) => _VlcPlaybackState(event));

  @override
  void stop() {
    _player.stop();
  }

  @override
  Duration currentPosition() {
    if (!isPlaying || _lastUpdateTimestamp <= 0) {
      return Duration(milliseconds: _position);
    }
    final offset = DateTime.now().millisecondsSinceEpoch - _lastUpdateTimestamp;
    if (offset.isNegative) {
      return Duration(milliseconds: _position);
    }
    return Duration(milliseconds: _position + offset);
  }
}
