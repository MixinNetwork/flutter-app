import 'dart:async';
import 'dart:io';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

import '../../account/account_server.dart';
import '../../db/mixin_database.dart';
import '../../enum/media_status.dart';
import '../extension/extension.dart';
import '../hook.dart';
import 'audio_message_player.dart';

export 'audio_message_player.dart';

class AudioMessagePlayService {
  AudioMessagePlayService(
    this._accountServer,
    Stream<String?> conversationIdStream,
  ) {
    _player = AudioMessagePlayer.platform();
    initListen();
    conversationIdSubscription =
        conversationIdStream.distinct().listen((event) => _player.stop());
  }

  final AccountServer _accountServer;

  late final AudioMessagePlayer _player;
  bool _isMediaList = false;
  StreamSubscription<String?>? conversationIdSubscription;

  bool get playing => _player.isPlaying;

  Duration get currentPosition {
    assert(supportCurrentPosition, 'not supported.');
    return _player.currentPosition();
  }

  bool get supportCurrentPosition => _player.supportCurrentPosition();

  void initListen() {
    _player.playbackStream.asyncMap((playbackState) async {
      if (!playbackState.isCompleted) return;

      final media = _player.current;

      if (_isMediaList) return;

      if (media == null) return;

      final currentMessage = media.messageItem;
      final message =
          await _accountServer.database.messageDao.findNextAudioMessageItem(
        conversationId: currentMessage.conversationId,
        messageId: currentMessage.messageId,
        createdAt: currentMessage.createdAt,
      );
      if (message == null) return;
      playAudioMessage(message);
    }).listen((event) {});
  }

  void dispose() {
    conversationIdSubscription?.cancel();
    _player.dispose();
  }

  void playAudioMessage(MessageItem message) {
    _player.stop();
    _isMediaList = false;

    if (![MediaStatus.done, MediaStatus.read].contains(message.mediaStatus)) {
      return;
    }
    final path = _accountServer.convertMessageAbsolutePath(message);
    final file = File(path);
    if (!file.existsSync()) return;

    if (message.mediaStatus == MediaStatus.done) {
      unawaited(_accountServer.database.messageDao
          .updateMediaStatus(MediaStatus.read, message.messageId));
    }

    _player.play([
      MessageMedia(
        message,
        convertMessageAbsolutePath: _accountServer.convertMessageAbsolutePath,
      )
    ]);
  }

  void playMessages(
    List<MessageItem> messages,
    String Function(MessageItem) convertMessageAbsolutePath,
  ) {
    _player.stop();
    _isMediaList = true;

    _player.play(messages
        .map(
          (e) => MessageMedia(
            e,
            convertMessageAbsolutePath: convertMessageAbsolutePath,
          ),
        )
        .where((e) => File(e.mediaPath).existsSync())
        .toList());
  }

  void stop() {
    _player.stop();
  }
}

bool useAudioMessagePlaying(String messageId, {bool isMediaList = false}) {
  final context = useContext();

  final value = useMemoizedStream(
        () {
          final ams = context.audioMessageService;

          return CombineLatestStream.combine2(
            ams._player.currentStream,
            ams._player.playbackStream,
            (MessageMedia? a, PlaybackState b) =>
                Tuple2<MessageMedia?, PlaybackState>(a, b),
          ).map((event) {
            if (!event.item2.isPlaying) return false;

            final message = event.item1?.messageItem;
            return message?.messageId == messageId &&
                isMediaList == ams._isMediaList;
          }).distinct();
        },
        keys: [messageId, isMediaList],
      ).data ??
      false;

  return value;
}
