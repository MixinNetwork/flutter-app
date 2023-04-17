import 'package:audio_session/audio_session.dart' as plugin;
import 'package:mixin_logger/mixin_logger.dart';

import '../platform.dart';

class AudioSession {
  AudioSession._internal();

  static final AudioSession instance = AudioSession._internal();

  bool _recordActivated = false;
  bool _playbackActivated = false;

  Future<void> activePlayback() async {
    if (!kPlatformIsMobile) {
      return;
    }
    if (_playbackActivated) {
      return;
    }
    if (_recordActivated) {
      await deactivate();
    }
    _playbackActivated = true;
    try {
      final instance = await plugin.AudioSession.instance;
      await instance.configure(const plugin.AudioSessionConfiguration.speech());
      await instance.setActive(true);
    } catch (error, stacktrace) {
      e('AudioSession activePlayback error', error, stacktrace);
    }
  }

  Future<void> activeRecord() async {
    if (!kPlatformIsMobile) {
      return;
    }
    if (_recordActivated) {
      return;
    }
    if (_playbackActivated) {
      await deactivate();
    }
    _recordActivated = true;
    try {
      final instance = await plugin.AudioSession.instance;
      await instance.configure(
        const plugin.AudioSessionConfiguration(
          avAudioSessionCategory: plugin.AVAudioSessionCategory.playAndRecord,
          avAudioSessionMode: plugin.AVAudioSessionMode.spokenAudio,
        ),
      );
      await instance.setActive(true);
    } catch (error, stacktrace) {
      e('AudioSession activeRecord error', error, stacktrace);
    }
  }

  Future<void> deactivate() async {
    if (!kPlatformIsMobile) {
      return;
    }
    if (!_playbackActivated && !_recordActivated) {
      return;
    }
    _playbackActivated = false;
    _recordActivated = false;
    try {
      final instance = await plugin.AudioSession.instance;
      await instance.setActive(
        false,
        avAudioSessionSetActiveOptions:
            plugin.AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
      );
    } catch (error, stacktrace) {
      e('AudioSession deactivate error', error, stacktrace);
    }
  }
}
