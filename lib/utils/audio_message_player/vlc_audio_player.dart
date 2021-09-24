import 'package:dart_vlc/dart_vlc.dart' as vlc;
import 'package:extended_image/extended_image.dart';
import 'package:flutter_app/utils/extension/extension.dart';

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
  final _player = vlc.Player(id: 64);

  final List<MessageMedia> _medias = [];

  @override
  void dispose() {
    _player.dispose();
  }

  @override
  bool get isPlaying => _player.playback.isPlaying;

  @override
  Stream<MessageMedia?> get currentStream => _player.currentStream.map(
      (event) => event.index == null ? null : _medias.getOrNull(event.index!));

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
  Stream<PlaybackState> get playbackStream =>
      _player.playbackStream.map((event) => _VlcPlaybackState(event));

  @override
  void stop() {
    _player.stop();
  }

  @override
  Duration currentPosition() => Duration.zero;

  @override
  bool supportCurrentPosition() => false;
}
