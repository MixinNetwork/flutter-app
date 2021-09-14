import 'dart:async';
import 'dart:io';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

import '../account/account_server.dart';
import '../db/mixin_database.dart';
import '../enum/media_status.dart';
import 'extension/extension.dart';
import 'hook.dart';

const _kMessageIdKey = 'message_id';
const _kConversationIdKey = 'conversation_id';
const _kCreatedAtKey = 'created_at';

class VlcService {
  VlcService(this._accountServer, Stream<String?> conversationIdStream) {
    _player = Player(id: 64);
    initListen();
    conversationIdSubscription =
        conversationIdStream.distinct().listen((event) => _player.stop());
  }

  final AccountServer _accountServer;

  late final Player _player;
  MessageItem? _currentMessage;
  List<MessageItem>? _currentMessages;
  bool _isMediaList = false;
  StreamSubscription<String?>? conversationIdSubscription;

  bool get playing => _player.playback.isPlaying;

  void initListen() {
    CombineLatestStream.combine2(
      _player.currentStream,
      _player.playbackStream,
      (CurrentState a, PlaybackState b) =>
          Tuple2<CurrentState, PlaybackState>(a, b),
    ).asyncMap((Tuple2<CurrentState, PlaybackState> value) async {
      final currentState = value.item1;
      final playbackState = value.item2;

      if (_isMediaList) return;
      if (!playbackState.isCompleted) return;
      final media = currentState.media;
      if (media == null) return;

      // todo use media.extras
      if (_currentMessage == null) return;
      final message =
          await _accountServer.database.messageDao.findNextAudioMessageItem(
        conversationId: _currentMessage!.conversationId,
        messageId: _currentMessage!.messageId,
        createdAt: _currentMessage!.createdAt,
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
    _currentMessage = null;
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

    _currentMessage = message;
    // todo in fact, extras not implement.
    final media = Media.file(file, extras: {
      _kMessageIdKey: message.messageId,
      _kConversationIdKey: message.conversationId,
      _kCreatedAtKey: message.createdAt,
    });

    _player.open(media);
  }

  void playMessages(
    List<MessageItem> messages,
    String Function(MessageItem) convertMessageAbsolutePath,
  ) {
    _currentMessage = null;
    _player.stop();
    _isMediaList = true;

    final medias = messages
        .map((message) {
          final path = convertMessageAbsolutePath(message);
          final file = File(path);
          final media = Media.file(file, extras: {
            _kMessageIdKey: message.messageId,
            _kConversationIdKey: message.conversationId,
            _kCreatedAtKey: message.createdAt,
          });
          return media;
        })
        .where((element) => File(element.resource).existsSync())
        .toList();

    if (medias.isEmpty) return;

    _currentMessages = messages;

    _player.open(Playlist(
      medias: medias,
    ));
  }

  void stop() {
    _currentMessage = null;
    _player.stop();
  }
}

bool useAudioMessagePlaying(String messageId, {bool isMediaList = false}) {
  final context = useContext();

  final value = useMemoizedStream(
        () {
          final vlcService = context.vlcService;

          return CombineLatestStream.combine2(
            vlcService._player.currentStream,
            vlcService._player.playbackStream,
            (CurrentState a, PlaybackState b) =>
                Tuple2<CurrentState, PlaybackState>(a, b),
          ).map((event) {
            if (!event.item2.isPlaying) return false;

            MessageItem? message;
            final currentState = event.item1;
            if (isMediaList) {
              if (currentState.index == null) return false;
              message =
                  vlcService._currentMessages?.getOrNull(currentState.index!);
            } else {
              message = vlcService._currentMessage;
            }

            return message?.messageId == messageId;
          }).distinct();
        },
        keys: [messageId],
      ).data ??
      false;

  return value;
}
