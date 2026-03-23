import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' hide Provider;
import 'package:ogg_opus_player/ogg_opus_player.dart';

import '../../../constants/resources.dart';
import '../../../utils/audio_message_player/audio_message_service.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/file.dart';
import '../../../utils/load_balancer_utils.dart';
import '../../../utils/logger.dart';
import '../../../utils/system/audio_session.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/toast.dart';
import '../../../widgets/waveform_widget.dart';
import '../../provider/account_server_provider.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/quote_message_provider.dart';
import '../../provider/ui_context_providers.dart';
import '../providers/home_scope_providers.dart';

enum RecorderState { idle, recording, recordingStopped }

class VoiceRecorderState with EquatableMixin {
  const VoiceRecorderState({
    required this.state,
    this.startTime,
    this.recodedData,
  });

  final RecorderState state;

  final DateTime? startTime;

  final RecordedData? recodedData;

  @override
  List<Object?> get props => [startTime, state];
}

class RecordedData with EquatableMixin {
  RecordedData(this.waveform, this.duration, this.path);

  final List<int> waveform;
  final Duration duration;
  final String path;

  @override
  List<Object?> get props => [waveform, duration, path];
}

class VoiceRecorderController extends Notifier<VoiceRecorderState> {
  @override
  VoiceRecorderState build() {
    ref.onDispose(() {
      if (state.state == RecorderState.recording ||
          state.state == RecorderState.recordingStopped) {
        unawaited(cancelAndExitRecordeMode());
      } else if (_startingCompleter != null) {
        unawaited(
          _startingCompleter?.future.then((_) => cancelAndExitRecordeMode()),
        );
      }
      _timer?.cancel();
    });
    return const VoiceRecorderState(state: RecorderState.idle);
  }

  OggOpusRecorder? _recorder;
  String? _recorderFilePath;

  AudioMessagePlayService get audioMessagePlayService =>
      ref.watch(audioMessagePlayServiceProvider);

  Completer<void>? _startingCompleter;

  Timer? _timer;

  Future<void> startRecording() async {
    if (_startingCompleter != null && !_startingCompleter!.isCompleted) {
      d('startRecording: waiting for previous startRecording to complete');
      return;
    }
    assert(_recorder == null, 'Recorder already started');
    audioMessagePlayService.stop();
    _startingCompleter = Completer();
    final path = await generateTempFilePath(TempFileType.voiceRecord);
    _recorderFilePath = path;
    final file = File(path);
    assert(!file.existsSync(), 'file already exists.');
    if (file.existsSync()) {
      await file.delete();
    }
    await file.create(recursive: true);
    d('start recode voice, path : $path');
    await AudioSession.instance.activeRecord();
    _recorder = OggOpusRecorder(path);
    _recorder?.start();
    _timer = Timer(const Duration(seconds: 60), stopRecording);
    state = VoiceRecorderState(
      startTime: DateTime.now(),
      state: RecorderState.recording,
    );
    _startingCompleter!.complete();
  }

  Future<RecordedData> stopRecording({bool isCanceled = false}) async {
    if (_timer?.isActive == true) {
      _timer?.cancel();
      _timer = null;
    }

    assert(_recorder != null, 'recorder is null.');
    assert(_recorderFilePath != null, 'recorder file path is null.');
    final path = _recorderFilePath;
    final recorder = _recorder;

    _recorder = null;
    _recorderFilePath = null;

    List<int>? waveform;
    double? duration;

    await recorder?.stop();

    if (!isCanceled) {
      waveform = await recorder?.getWaveformData();
      duration = await recorder?.duration();
    }

    recorder?.dispose();
    await AudioSession.instance.deactivate();

    final recodeData = RecordedData(
      waveform ?? const [],
      duration == null
          ? Duration.zero
          : Duration(milliseconds: (duration * 1000).round()),
      path!,
    );

    state = VoiceRecorderState(
      state: RecorderState.recordingStopped,
      recodedData: recodeData,
    );
    return recodeData;
  }

  Future<void> cancelAndExitRecordeMode() async {
    if (state.state == RecorderState.idle) {
      return;
    }
    if (state.state == RecorderState.recordingStopped) {
      state = const VoiceRecorderState(state: RecorderState.idle);
      return;
    }
    final result = await stopRecording(isCanceled: true);
    state = const VoiceRecorderState(state: RecorderState.idle);
    try {
      await File(result.path).delete();
    } catch (error, stacktrace) {
      e('cancelRecording: failed to delete file. $error $stacktrace');
    }
  }
}

class VoiceRecorderBarOverlayComposition extends HookConsumerWidget {
  const VoiceRecorderBarOverlayComposition({
    required this.child,
    required this.layoutWidth,
    super.key,
  });

  final Widget child;

  final double layoutWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRecorderMode = ref.watch(
      voiceRecorderControllerProvider.select(
        (state) => state.state != RecorderState.idle,
      ),
    );
    final link = useMemoized(LayerLink.new);

    final overlay = Navigator.of(context).overlay ?? Overlay.of(context);

    final recorderBottomBarEntry = useRef<OverlayEntry?>(null);

    useEffect(() {
      recorderBottomBarEntry.value?.remove();
      recorderBottomBarEntry.value = null;
      if (!isRecorderMode) {
        return;
      }
      final entry = OverlayEntry(
        builder: (context) => _RecordingInterceptor(
          child: UnconstrainedBox(
            child: CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomCenter,
              followerAnchor: Alignment.bottomCenter,
              child: SizedBox(
                width: layoutWidth,
                child: const Material(child: VoiceRecorderBottomBar()),
              ),
            ),
          ),
        ),
      );
      recorderBottomBarEntry.value = entry;
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        overlay.insert(entry);
      });
    }, [isRecorderMode, layoutWidth]);

    return CompositedTransformTarget(link: link, child: child);
  }
}

class _RecordingInterceptor extends HookConsumerWidget {
  const _RecordingInterceptor({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRecording = ref.watch(
      voiceRecorderControllerProvider.select(
        (state) => state.state == RecorderState.recording,
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (isRecording)
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
            onTap: () async {
              _showDiscardRecordingWarningAlertOverlay(
                context,
                theme: ref.read(brightnessThemeDataProvider),
                l10n: ref.read(localizationProvider),
                onDiscard: () {
                  ref
                      .read(voiceRecorderControllerProvider.notifier)
                      .cancelAndExitRecordeMode();
                },
              );
            },
          ),
        child,
      ],
    );
  }
}

void _showDiscardRecordingWarningAlertOverlay(
  BuildContext context, {
  required BrightnessThemeData theme,
  required Localization l10n,
  required VoidCallback onDiscard,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);

  OverlayEntry? entry;

  void dimiss() {
    entry?.remove();
    entry = null;
  }

  entry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: dimiss,
          child: const SizedBox.expand(
            child: ColoredBox(color: Color(0x80000000)),
          ),
        ),
        Center(
          child: SizedBox(
            width: 400,
            child: Material(
              borderRadius: const BorderRadius.all(Radius.circular(11)),
              color: theme.popUp,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      l10n.discardRecordingWarning,
                      style: TextStyle(
                        fontSize: 16,
                        height: 2,
                        color: theme.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Row(
                      children: [
                        const Spacer(),
                        MixinButton(
                          backgroundTransparent: true,
                          onTap: dimiss,
                          child: Text(l10n.cancel),
                        ),
                        MixinButton(
                          onTap: () {
                            dimiss();
                            onDiscard();
                          },
                          child: Text(l10n.discard),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  overlay.insert(entry!);
}

class VoiceRecorderBottomBar extends HookConsumerWidget {
  const VoiceRecorderBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final voiceRecorderController = ref.read(
      voiceRecorderControllerProvider.notifier,
    );
    final startTime = ref.watch(
      voiceRecorderControllerProvider.select((state) => state.startTime),
    );
    final isRecording = ref.watch(
      voiceRecorderControllerProvider.select(
        (state) => state.state == RecorderState.recording,
      ),
    );
    final recordedResult = ref.watch(
      voiceRecorderControllerProvider.select((state) => state.recodedData),
    );

    useEffect(() {
      if (recordedResult == null) {
        return;
      }
      final audioFile = File(recordedResult.path);
      if (!audioFile.existsSync()) {
        e('audio file does not exist.');
        scheduleMicrotask(() {
          showToastFailed(null);
        });
        return;
      }
      if (audioFile.lengthSync() == 0) {
        e('audio file is empty.');
        scheduleMicrotask(() {
          showToastFailed(null);
        });
        return;
      }
    }, [recordedResult]);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.primary,
      child: Row(
        children: [
          ActionButton(
            name: Resources.assetsImagesCloseOvalRecordSvg,
            color: theme.icon,
            onTap: () async {
              final path = recordedResult?.path;
              await voiceRecorderController.cancelAndExitRecordeMode();
              if (path != null) {
                try {
                  await File(path).delete();
                } catch (error, stacktrace) {
                  e(
                    'cancelRecording: failed to delete file. $error $stacktrace',
                  );
                }
              }
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: recordedResult == null
                  ? startTime == null
                        ? const SizedBox()
                        : _RecordingLayout(startTime: startTime)
                  : _RecordedResultPreviewLayout(result: recordedResult),
            ),
          ),
          if (isRecording)
            ActionButton(
              name: Resources.assetsImagesRecordStopSvg,
              color: theme.accent,
              onTap: () async => voiceRecorderController.stopRecording(),
            )
          else
            ActionButton(
              name: Resources.assetsImagesRecordRetrySvg,
              color: theme.icon,
              onTap: () async {
                final path = recordedResult?.path;
                await voiceRecorderController.startRecording();
                if (path != null) {
                  try {
                    await File(path).delete();
                  } catch (error, stacktrace) {
                    e('re-recorder: failed to delete file. $error $stacktrace');
                  }
                }
              },
            ),
          ActionButton(
            name: Resources.assetsImagesIcSendSvg,
            color: theme.icon,
            onTap: () async {
              final conversationItem = ref.read(conversationProvider);
              final accountServer = ref
                  .read(accountServerProvider)
                  .requireValue;

              final RecordedData result;

              if (voiceRecorderController.state.state ==
                  RecorderState.recording) {
                result = await voiceRecorderController.stopRecording();
              } else {
                if (recordedResult == null) {
                  e('result is null. ${voiceRecorderController.state}');
                  return;
                }
                result = recordedResult;
              }
              await voiceRecorderController.cancelAndExitRecordeMode();
              final audioFile = File(result.path);
              if (!audioFile.existsSync()) {
                e('audio file does not exist.');
                return;
              }
              if (audioFile.lengthSync() == 0) {
                e('audio file is empty.');
                return;
              }
              if (conversationItem == null) return;

              final quoteMessageId = ref.read(quoteMessageIdProvider);
              ref.read(quoteMessageProvider.notifier).clear();
              await accountServer.sendAudioMessage(
                audioFile.xFile,
                result.duration,
                await base64EncodeWithIsolate(result.waveform),
                conversationItem.encryptCategory,
                conversationId: conversationItem.conversationId,
                recipientId: conversationItem.userId,
                quoteMessageId: quoteMessageId,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Player {
  _Player(this.path);

  final String path;

  final isPlaying = ValueNotifier<bool>(false);

  double get position => _player?.currentPosition ?? 0.0;

  OggOpusPlayer? _player;

  Future<void> start() async {
    await AudioSession.instance.activePlayback();
    final player = OggOpusPlayer(path);
    player.state.addListener(() {
      final state = player.state.value;
      isPlaying.value = state == PlayerState.playing;
      if (state == PlayerState.ended) {
        stop();
      }
    });
    player.play();
    _player = player;
  }

  Future<void> stop() async {
    _player?.pause();
    _player?.dispose();
    _player = null;
    await AudioSession.instance.deactivate();
    isPlaying.value = false;
  }

  void dispose() {
    stop();
  }
}

class _RecordedResultPreviewLayout extends HookConsumerWidget {
  const _RecordedResultPreviewLayout({required this.result});

  final RecordedData result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final player = useMemoized(() => _Player(result.path));
    useEffect(() => player.dispose, []);
    final isPlaying = useValueListenable(player.isPlaying);
    return SizedBox(
      height: 32,
      child: Material(
        color: theme.listSelected,
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 2),
            if (!isPlaying)
              ActionButton(
                name: Resources.assetsImagesRecordPreviewPlaySvg,
                onTap: player.start,
              )
            else
              ActionButton(
                name: Resources.assetsImagesRecordPreviewStopSvg,
                onTap: player.stop,
              ),
            const SizedBox(width: 2),
            Expanded(
              child: SizedBox(
                height: 20,
                child: _TickRefreshContainer(
                  active: isPlaying,
                  builder: (context) => WaveformWidget(
                    value:
                        (player.position *
                                1000 /
                                result.duration.inMilliseconds)
                            .clamp(0.0, 1.0),
                    waveform: result.waveform,
                    backgroundColor: theme.waveformBackground,
                    foregroundColor: theme.waveformForeground,
                    maxBarCount: null,
                    alignment: WaveBarAlignment.center,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              result.duration.asMinutesSecondsWithDas,
              style: TextStyle(
                color: theme.text,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _TickRefreshContainer extends HookConsumerWidget {
  const _TickRefreshContainer({required this.builder, required this.active});

  final WidgetBuilder builder;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickerProvider = useSingleTickerProvider();
    final state = useState<bool>(false);
    final ticker = useMemoized(
      () => tickerProvider.createTicker((elapsed) {
        state.value = !state.value;
      }),
      [tickerProvider],
    );
    useEffect(() => ticker.dispose, [ticker]);

    useEffect(() {
      if (ticker.isActive == active) return;
      if (ticker.isActive) {
        ticker.stop();
      } else {
        ticker.start();
      }
    }, [active]);
    return builder(context);
  }
}

class _RecordingLayout extends StatelessWidget {
  const _RecordingLayout({required this.startTime});

  final DateTime startTime;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Spacer(),
      _TickRefreshContainer(
        builder: (context) => _RecorderDurationText(
          duration: DateTime.now().difference(startTime),
        ),
        active: true,
      ),
      const Spacer(),
    ],
  );
}

class _RecorderDurationText extends ConsumerWidget {
  const _RecorderDurationText({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox.square(
          dimension: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFE57874),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          duration.asMinutesSecondsWithDas,
          style: TextStyle(
            color: theme.text,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
