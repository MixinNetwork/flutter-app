part of 'voice_recorder_bottom_bar.dart';

enum VoiceRecorderStatus { idle, recording, recordingStopped }

class VoiceRecorderState with EquatableMixin {
  const VoiceRecorderState({
    required this.status,
    this.startTime,
    this.recordedData,
  });

  final VoiceRecorderStatus status;
  final DateTime? startTime;
  final RecordedData? recordedData;

  @override
  List<Object?> get props => [startTime, status, recordedData];
}

class RecordedData with EquatableMixin {
  RecordedData(this.waveform, this.duration, this.path);

  final List<int> waveform;
  final Duration duration;
  final String path;

  @override
  List<Object?> get props => [waveform, duration, path];
}

class VoiceRecorderNotifier extends ValueNotifier<VoiceRecorderState> {
  VoiceRecorderNotifier(this.audioMessagePlayService)
    : super(const VoiceRecorderState(status: VoiceRecorderStatus.idle));

  OggOpusRecorder? _recorder;
  String? _recorderFilePath;

  final AudioMessagePlayService audioMessagePlayService;

  Completer<void>? _startingCompleter;

  Timer? _timer;
  var _disposed = false;

  VoiceRecorderState get state => value;

  void _setState(VoiceRecorderState state) {
    if (_disposed) return;
    value = state;
  }

  Future<void> startRecording() async {
    if (_disposed) return;
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
    _setState(
      VoiceRecorderState(
        startTime: DateTime.now(),
        status: VoiceRecorderStatus.recording,
      ),
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

    _setState(
      VoiceRecorderState(
        status: VoiceRecorderStatus.recordingStopped,
        recordedData: recodeData,
      ),
    );
    return recodeData;
  }

  Future<void> cancelAndExitRecordMode() async {
    if (state.status == VoiceRecorderStatus.idle) {
      return;
    }
    if (state.status == VoiceRecorderStatus.recordingStopped) {
      _setState(const VoiceRecorderState(status: VoiceRecorderStatus.idle));
      return;
    }
    final result = await stopRecording(isCanceled: true);
    _setState(const VoiceRecorderState(status: VoiceRecorderStatus.idle));
    try {
      await File(result.path).delete();
    } catch (error, stacktrace) {
      e('cancelRecording: failed to delete file. $error $stacktrace');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_disposeRecording());
    super.dispose();
  }

  Future<void> _disposeRecording() async {
    if (_startingCompleter != null && !_startingCompleter!.isCompleted) {
      await _startingCompleter?.future;
    }
    if (_recorder != null || _recorderFilePath != null) {
      final result = await stopRecording(isCanceled: true);
      try {
        await File(result.path).delete();
      } catch (error, stacktrace) {
        e('disposeRecording: failed to delete file. $error $stacktrace');
      }
      return;
    }
    if (state.status == VoiceRecorderStatus.recording ||
        state.status == VoiceRecorderStatus.recordingStopped) {
      await cancelAndExitRecordMode();
    }
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
