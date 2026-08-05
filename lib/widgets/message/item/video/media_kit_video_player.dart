import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mixin_logger/mixin_logger.dart';

class MediaKitVideoValue {
  const MediaKitVideoValue({
    required this.position,
    required this.duration,
    required this.buffer,
    required this.volume,
    required this.isPlaying,
    required this.width,
    required this.height,
  });

  final Duration position;
  final Duration duration;
  final Duration buffer;
  final double volume;
  final bool isPlaying;
  final int? width;
  final int? height;

  bool get isInitialized =>
      width != null && height != null && duration > Duration.zero;

  double get aspectRatio {
    final width = this.width;
    final height = this.height;
    if (width == null || height == null || width == 0 || height == 0) {
      return 1;
    }
    return width / height;
  }
}

class MediaKitVideoPlayer extends ChangeNotifier {
  MediaKitVideoPlayer(
    this.path, {
    bool autoPlay = false,
    bool looping = false,
    bool muted = false,
  }) : player = Player() {
    controller = VideoController(player);
    _subscriptions.addAll([
      player.stream.playing.listen(_notify),
      player.stream.position.listen(_notify),
      player.stream.duration.listen(_notify),
      player.stream.buffer.listen(_notify),
      player.stream.volume.listen(_notify),
      player.stream.width.listen(_notify),
      player.stream.height.listen(_notify),
    ]);
    unawaited(_open(path, autoPlay: autoPlay, looping: looping, muted: muted));
  }

  final Player player;
  final String path;
  late final VideoController controller;

  final _subscriptions = <StreamSubscription<dynamic>>[];
  var _disposed = false;

  MediaKitVideoValue get value {
    final state = player.state;
    return MediaKitVideoValue(
      position: state.position,
      duration: state.duration,
      buffer: state.buffer,
      volume: (state.volume / 100).clamp(0.0, 1.0),
      isPlaying: state.playing,
      width: state.width,
      height: state.height,
    );
  }

  Future<void> _open(
    String path, {
    required bool autoPlay,
    required bool looping,
    required bool muted,
  }) async {
    try {
      await player.open(Media(path), play: autoPlay);
      if (looping) {
        await player.setPlaylistMode(PlaylistMode.single);
      }
      if (muted) {
        await player.setVolume(0);
      }
    } catch (error, stackTrace) {
      if (!_disposed) {
        e('video playback failed: $path $error $stackTrace');
      }
    }
  }

  Future<void> play() => player.play();

  Future<void> pause() => player.pause();

  Future<void> seekTo(Duration position) => player.seek(position);

  Future<void> setVolume(double volume) =>
      player.setVolume(volume.clamp(0.0, 1.0) * 100);

  void _notify<T>(T _) {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(player.dispose());
    super.dispose();
  }
}
