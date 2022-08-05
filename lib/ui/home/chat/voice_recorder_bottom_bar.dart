import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:ogg_opus_player/ogg_opus_player.dart';

import '../../../constants/resources.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/file.dart';
import '../../../utils/hook.dart';
import '../../../utils/load_balancer_utils.dart';
import '../../../utils/logger.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/toast.dart';
import '../../../widgets/waveform_widget.dart';
import '../bloc/conversation_cubit.dart';
import '../bloc/quote_message_cubit.dart';

enum RecorderState {
  idle,
  recording,
  recordingStopped,
}

class VoiceRecorderCubitState with EquatableMixin {
  const VoiceRecorderCubitState({
    this.startTime,
    required this.state,
  });

  final RecorderState state;

  final DateTime? startTime;

  @override
  List<Object?> get props => [startTime, state];
}

class RecorderResult {
  RecorderResult(this.waveform, this.duration, this.path);

  final List<int> waveform;
  final Duration duration;
  final String path;
}

class VoiceRecorderCubit extends Cubit<VoiceRecorderCubitState> {
  VoiceRecorderCubit()
      : super(const VoiceRecorderCubitState(
          state: RecorderState.idle,
        ));

  OggOpusRecorder? _recorder;
  String? _recorderFilePath;

  Completer<void>? _startingCompleter;

  Future<void> startRecording() async {
    if (_startingCompleter != null && !_startingCompleter!.isCompleted) {
      d('startRecording: waiting for previous startRecording to complete');
      return;
    }
    assert(_recorder == null, 'Recorder already started');
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
    _recorder = OggOpusRecorder(path);
    _recorder?.start();
    emit(VoiceRecorderCubitState(
      startTime: DateTime.now(),
      state: RecorderState.recording,
    ));
    _startingCompleter!.complete();
  }

  Future<RecorderResult> _stopRecording({
    bool isCanceled = false,
    bool exitRecordMode = false,
  }) async {
    assert(_recorder != null, 'recorder is null.');
    assert(_recorderFilePath != null, 'recorder file path is null.');
    final path = _recorderFilePath;
    final recorder = _recorder;

    _recorder = null;
    _recorderFilePath = null;
    emit(
      VoiceRecorderCubitState(
        state: exitRecordMode
            ? RecorderState.idle
            : RecorderState.recordingStopped,
      ),
    );

    List<int>? waveform;
    double? duration;

    await recorder?.stop();

    if (!isCanceled) {
      waveform = await recorder?.getWaveformData();
      duration = await recorder?.duration();
    }

    recorder?.dispose();

    return RecorderResult(
      waveform ?? const [],
      duration == null
          ? Duration.zero
          : Duration(milliseconds: (duration * 1000).round()),
      path!,
    );
  }

  Future<void> cancelAndExitRecordeMode() async {
    debugPrint('state: ${state.state}');
    if (state.state == RecorderState.idle) {
      return;
    }
    if (state.state == RecorderState.recordingStopped) {
      emit(const VoiceRecorderCubitState(state: RecorderState.idle));
      return;
    }
    final result = await _stopRecording(isCanceled: true, exitRecordMode: true);
    try {
      await File(result.path).delete();
    } catch (error, stacktrace) {
      e('cancelRecording: failed to delete file. $error $stacktrace');
    }
  }

  @override
  Future<void> close() async {
    if (state.state == RecorderState.recording ||
        state.state == RecorderState.recordingStopped) {
      await cancelAndExitRecordeMode();
    } else if (_startingCompleter != null) {
      await _startingCompleter?.future;
      await cancelAndExitRecordeMode();
    }
    await super.close();
  }
}

class VoiceRecorderBottomBar extends HookWidget {
  const VoiceRecorderBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final startTime = useBlocStateConverter<VoiceRecorderCubit,
        VoiceRecorderCubitState, DateTime?>(
      converter: (state) => state.startTime,
    );
    final isRecording = useBlocStateConverter<VoiceRecorderCubit,
        VoiceRecorderCubitState, bool>(
      converter: (state) => state.state == RecorderState.recording,
    );
    final recordedResult = useState<RecorderResult?>(null);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      color: context.theme.primary,
      child: Row(
        children: [
          ActionButton(
            name: Resources.assetsImagesCloseOvalRecordSvg,
            color: context.theme.icon,
            onTap: () async {
              final path = recordedResult.value?.path;
              await context
                  .read<VoiceRecorderCubit>()
                  .cancelAndExitRecordeMode();
              if (path != null) {
                try {
                  await File(path).delete();
                } catch (error, stacktrace) {
                  e('cancelRecording: failed to delete file. $error $stacktrace');
                }
              }
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: recordedResult.value == null
                  ? startTime == null
                      ? const SizedBox()
                      : _RecordingLayout(startTime: startTime)
                  : _RecordedResultPreviewLayout(result: recordedResult.value!),
            ),
          ),
          if (isRecording)
            ActionButton(
              name: Resources.assetsImagesRecordStopSvg,
              color: context.theme.accent,
              onTap: () async {
                final recorderCubit = context.read<VoiceRecorderCubit>();
                final result = await recorderCubit._stopRecording();
                final audioFile = File(result.path);
                if (!audioFile.existsSync()) {
                  e('audio file does not exist.');
                  await showToastFailed(context, null);
                  return;
                }
                if (audioFile.lengthSync() == 0) {
                  e('audio file is empty.');
                  await showToastFailed(context, null);
                  return;
                }
                recordedResult.value = result;
              },
            )
          else
            ActionButton(
              name: Resources.assetsImagesRecordRetrySvg,
              color: context.theme.icon,
              onTap: () async {
                final path = recordedResult.value?.path;
                recordedResult.value = null;
                await context.read<VoiceRecorderCubit>().startRecording();
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
            color: context.theme.icon,
            onTap: () async {
              final conversationItem = context.read<ConversationCubit>().state;
              final accountServer = context.accountServer;
              final quietMessageId =
                  context.read<QuoteMessageCubit>().state?.messageId;

              final recorderCubit = context.read<VoiceRecorderCubit>();

              final RecorderResult result;

              if (recorderCubit.state.state == RecorderState.recording) {
                result = await recorderCubit._stopRecording(
                  exitRecordMode: true,
                );
              } else {
                if (recordedResult.value == null) {
                  e('result is null. ${recorderCubit.state}');
                  return;
                }
                result = recordedResult.value!;
                await recorderCubit.cancelAndExitRecordeMode();
              }
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

              await accountServer.sendAudioMessage(
                audioFile.xFile,
                result.duration,
                await base64EncodeWithIsolate(result.waveform),
                conversationItem.encryptCategory,
                conversationId: conversationItem.conversationId,
                recipientId: conversationItem.userId,
                quoteMessageId: quietMessageId,
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

  void start() {
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

  void stop() {
    _player?.pause();
    _player?.dispose();
    _player = null;
    isPlaying.value = false;
  }

  void dispose() {
    stop();
  }
}

class _RecordedResultPreviewLayout extends HookWidget {
  const _RecordedResultPreviewLayout({required this.result});

  final RecorderResult result;

  @override
  Widget build(BuildContext context) {
    final player = useMemoized(
      () => _Player(result.path),
    );
    useEffect(() => player.dispose, []);
    final isPlaying = useValueListenable(player.isPlaying);
    return SizedBox(
      height: 32,
      child: Material(
        color: context.theme.listSelected,
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
                    value: (player.position *
                            1000 /
                            result.duration.inMilliseconds)
                        .clamp(0.0, 1.0),
                    waveform: result.waveform,
                    backgroundColor: context.theme.waveformBackground,
                    foregroundColor: context.theme.waveformForeground,
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
                color: context.theme.text,
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

class _TickRefreshContainer extends HookWidget {
  const _TickRefreshContainer({
    required this.builder,
    required this.active,
  });

  final WidgetBuilder builder;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();
    final state = useState<bool>(false);
    final ticker = useMemoized(
      () => tickerProvider.createTicker((elapsed) {
        state.value = !state.value;
      }),
      [tickerProvider],
    );
    useEffect(
      () => ticker.dispose,
      [ticker],
    );

    useEffect(
      () {
        if (ticker.isActive == active) return;
        if (ticker.isActive) {
          ticker.stop();
        } else {
          ticker.start();
        }
      },
      [active],
    );
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

class _RecorderDurationText extends StatelessWidget {
  const _RecorderDurationText({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) => Row(
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
              color: context.theme.text,
              fontSize: 14,
            ),
          ),
        ],
      );
}
