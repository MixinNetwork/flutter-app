import 'dart:async';
import 'dart:io';

import 'package:rxdart/rxdart.dart';

import '../../account/account_server.dart';
import '../../db/mixin_database.dart';
import '../../enum/media_status.dart';
import '../system/audio_session.dart';
import 'audio_message_player.dart';

export 'audio_message_player.dart';

class AudioMessagePlayService {
  AudioMessagePlayService(this._accountServer) {
    _player = AudioMessagePlayer.oggOpus();
    initListen();
  }

  final AccountServer _accountServer;

  late final AudioMessagePlayer _player;
  bool _isMediaList = false;

  bool get playing => _player.playbackState.isPlaying;
  bool get isMediaList => _isMediaList;

  Duration get currentPosition => _player.currentPosition();
  Stream<PlaybackState> get playbackStateStream =>
      _player.playbackStream.distinct();
  Stream<MessageItem?> get currentMessageStream =>
      _player.currentStream.map((e) => e?.messageItem).distinct();
  Stream<double> get playbackSpeedStream =>
      _player.playbackSpeedStream.distinct();
  Stream<double> get positionStream => playbackStateStream.switchMap((event) {
    if (event == PlaybackState.idle || event == PlaybackState.completed) {
      return Stream<double>.value(0);
    }
    if (event == PlaybackState.paused) {
      return Stream<double>.value(currentPosition.inMilliseconds.toDouble());
    }
    return Stream<double>.periodic(
      const Duration(milliseconds: 200),
      (_) => currentPosition.inMilliseconds.toDouble(),
    ).startWith(currentPosition.inMilliseconds.toDouble());
  }).distinct();

  final _subscriptions = <StreamSubscription>[];

  void initListen() {
    _subscriptions.add(
      _player.playbackStream
          .asyncMap((playbackState) async {
            if (!playbackState.isCompleted) return;

            final media = _player.current;

            if (_isMediaList || media == null) {
              await AudioSession.instance.deactivate();
              return;
            }
            final currentMessage = media.messageItem;
            final message = await _accountServer.database.messageDao
                .findNextAudioMessageItem(
                  conversationId: currentMessage.conversationId,
                  messageId: currentMessage.messageId,
                );
            if (message == null) {
              await AudioSession.instance.deactivate();
              return;
            }
            await playAudioMessage(message, resetPlaySpeed: false);
          })
          .listen((event) {}),
    );
  }

  void dispose() {
    _player.dispose();
    _subscriptions
      ..forEach((e) => e.cancel())
      ..clear();
  }

  Future<void> playAudioMessage(
    MessageItem message, {
    bool resetPlaySpeed = true,
  }) async {
    _player.stop();
    _isMediaList = false;

    if (![MediaStatus.done, MediaStatus.read].contains(message.mediaStatus)) {
      return;
    }
    final path = _accountServer.convertMessageAbsolutePath(message);
    final file = File(path);
    if (!file.existsSync()) return;

    if (message.mediaStatus == MediaStatus.done) {
      unawaited(
        _accountServer.updateMessageMediaStatus(
          message.messageId,
          MediaStatus.read,
        ),
      );
    }

    await AudioSession.instance.activePlayback();

    _player.play([
      MessageMedia(
        message,
        convertMessageAbsolutePath: _accountServer.convertMessageAbsolutePath,
      ),
    ], resetPlaySpeed: resetPlaySpeed);
  }

  Future<void> playMessages(
    List<MessageItem> messages,
    String Function(MessageItem) convertMessageAbsolutePath,
  ) async {
    _player.stop();
    _isMediaList = true;
    await AudioSession.instance.activePlayback();
    _player.play(
      messages
          .map(
            (e) => MessageMedia(
              e,
              convertMessageAbsolutePath: convertMessageAbsolutePath,
            ),
          )
          .where((e) => File(e.mediaPath).existsSync())
          .toList(),
    );
  }

  void stop() {
    _player.stop();
  }

  Future<void> pause() async {
    _player.pause();
    await AudioSession.instance.deactivate();
  }

  Future<void> resume() async {
    await AudioSession.instance.activePlayback();
    _player.resume();
  }

  void setPlaySpeed(double speed) {
    _player.setPlaybackSpeed(speed);
  }
}
