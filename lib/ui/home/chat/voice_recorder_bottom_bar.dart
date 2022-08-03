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
import '../bloc/conversation_cubit.dart';
import '../bloc/quote_message_cubit.dart';

class VoiceRecorderCubitState with EquatableMixin {
  const VoiceRecorderCubitState({
    required this.startTime,
  });

  bool get isRecording => startTime != null;
  final DateTime? startTime;

  @override
  List<Object?> get props => [startTime];
}

class RecorderResult {
  RecorderResult(this.waveform, this.duration, this.path);

  final List<int> waveform;
  final Duration duration;
  final String path;
}

class VoiceRecorderCubit extends Cubit<VoiceRecorderCubitState> {
  VoiceRecorderCubit() : super(const VoiceRecorderCubitState(startTime: null));

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
    ));
    _startingCompleter!.complete();
  }

  Future<RecorderResult> _stopRecording({bool isCanceled = false}) async {
    assert(_recorder != null, 'recorder is null.');
    assert(_recorderFilePath != null, 'recorder file path is null.');
    final path = _recorderFilePath;
    final recorder = _recorder;

    _recorder = null;
    _recorderFilePath = null;
    emit(const VoiceRecorderCubitState(
      startTime: null,
    ));

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

  Future<void> cancelRecording() async {
    final result = await _stopRecording(isCanceled: true);
    try {
      await File(result.path).delete();
    } catch (error, stacktrace) {
      e('cancelRecording: failed to delete file. $error $stacktrace');
    }
  }

  @override
  Future<void> close() async {
    d('cancel recording when closing.');
    if (_recorder != null) {
      await cancelRecording();
    } else if (_startingCompleter != null) {
      assert(
        _startingCompleter?.isCompleted == false,
        'startingCompleter is completed.',
      );
      await _startingCompleter?.future;
      await cancelRecording();
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
    assert(startTime != null, 'startTime is null.');
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
            onTap: () {
              context.read<VoiceRecorderCubit>().cancelRecording();
            },
          ),
          const Spacer(),
          HookBuilder(builder: (context) {
            final tickerProvider = useSingleTickerProvider();

            final duration = useState(Duration.zero);
            useEffect(() {
              final ticker = tickerProvider.createTicker((elapsed) {
                duration.value = DateTime.now().difference(startTime!);
              })
                ..start();
              return ticker.dispose;
            }, [tickerProvider, startTime]);

            return _RecorderDurationText(
              duration: duration.value,
            );
          }),
          const Spacer(),
          ActionButton(
            name: Resources.assetsImagesIcSendSvg,
            color: context.theme.icon,
            onTap: () async {
              final conversationItem = context.read<ConversationCubit>().state;
              final accountServer = context.accountServer;
              final quietMessageId =
                  context.read<QuoteMessageCubit>().state?.messageId;

              final result =
                  await context.read<VoiceRecorderCubit>()._stopRecording();
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
