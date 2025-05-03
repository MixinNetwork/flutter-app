import 'dart:async';
import 'dart:io';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rxdart/rxdart.dart';

import '../../account/account_server.dart';
import '../../db/mixin_database.dart';
import '../../enum/media_status.dart';
import '../extension/extension.dart';
import '../hook.dart';
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

  Duration get currentPosition => _player.currentPosition();

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
        _accountServer.database.messageDao.updateMediaStatus(
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

bool useAudioMessagePlaying(String messageId, {bool isMediaList = false}) {
  final context = useContext();

  final result = useMemoizedStream(() {
    final ams = context.audioMessageService;

    return CombineLatestStream.combine2<
      MessageMedia?,
      bool,
      (MessageMedia?, bool)
    >(
      ams._player.currentStream,
      ams._player.playbackStream.map((e) => e.isPlaying).distinct(),
      (a, b) => (a, b),
    ).map((event) {
      if (!event.$2) return false;

      final message = event.$1?.messageItem;

      return message?.messageId == messageId && isMediaList == ams._isMediaList;
    }).distinct();
  }, keys: [messageId, isMediaList, context]);
  return result.data ?? false;
}

PlaybackState useAudioMessagePlayerState() {
  final context = useContext();

  final result = useMemoizedStream(() {
    final ams = context.audioMessageService;
    return ams._player.playbackStream.distinct();
  }, keys: [context]);
  return result.data ?? PlaybackState.idle;
}

MessageItem? useCurrentPlayingMessage() {
  final context = useContext();

  final result = useMemoizedStream(() {
    final ams = context.audioMessageService;
    return ams._player.currentStream.map((e) => e?.messageItem).distinct();
  }, keys: [context]);
  return result.data;
}

double useAudioPlayerPosition() {
  final context = useContext();
  final ams = context.audioMessageService;
  final position = useState<double>(0);
  final isImagePlay = useValueListenable(useImagePlaying(context));
  useEffect(() {
    Timer? timer;
    final subscription = ams._player.playbackStream.listen((event) {
      timer?.cancel();
      if (event == PlaybackState.idle || event == PlaybackState.completed) {
        position.value = 0;
        return;
      }
      if (event == PlaybackState.paused) {
        position.value = ams.currentPosition.inMilliseconds.toDouble();
        return;
      }
      // Avoid update too often. since there is performance issue in Flutter.
      // https://github.com/flutter/flutter/issues/85781
      timer = Timer.periodic(Duration(milliseconds: isImagePlay ? 40 : 200), (
        timer,
      ) {
        position.value = ams.currentPosition.inMilliseconds.toDouble();
      });
    });
    return () {
      subscription.cancel();
      timer?.cancel();
    };
  }, [ams, isImagePlay]);

  return position.value;
}

double useAudioPlayerSpeed() {
  final context = useContext();
  final ams = context.audioMessageService;
  final speed = useState<double>(1);
  useEffect(() {
    final subscription = ams._player.playbackSpeedStream.listen((event) {
      speed.value = event;
    });
    return subscription.cancel;
  }, [ams]);

  return speed.value;
}
