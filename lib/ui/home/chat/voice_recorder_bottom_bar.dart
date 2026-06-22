import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' hide ChangeNotifierProvider;
import 'package:ogg_opus_player/ogg_opus_player.dart';
import 'package:provider/provider.dart';

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
import '../../provider/conversation_provider.dart';
import '../../provider/quote_message_provider.dart';

part 'voice_recorder_state.dart';

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
    final voiceRecorderNotifier = context.read<VoiceRecorderNotifier>();
    final isRecorderMode =
        useValueListenable(voiceRecorderNotifier).status !=
        VoiceRecorderStatus.idle;
    final link = useMemoized(LayerLink.new);

    final overlay = Navigator.of(context).overlay ?? Overlay.of(context);

    final recorderBottomBarEntry = useRef<OverlayEntry?>(null);

    useEffect(() {
      final previousEntry = recorderBottomBarEntry.value;
      if (previousEntry?.mounted ?? false) {
        previousEntry?.remove();
      }
      recorderBottomBarEntry.value = null;
      if (!isRecorderMode) {
        return null;
      }
      final entry = OverlayEntry(
        builder: (context) =>
            ChangeNotifierProvider<VoiceRecorderNotifier>.value(
              value: voiceRecorderNotifier,
              child: _RecordingInterceptor(
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
            ),
      );
      recorderBottomBarEntry.value = entry;
      var disposed = false;
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        if (disposed) return;
        overlay.insert(entry);
      });
      return () {
        disposed = true;
        if (entry.mounted) {
          entry.remove();
        }
        if (recorderBottomBarEntry.value == entry) {
          recorderBottomBarEntry.value = null;
        }
      };
    }, [isRecorderMode, layoutWidth]);

    return CompositedTransformTarget(link: link, child: child);
  }
}

class _RecordingInterceptor extends HookConsumerWidget {
  const _RecordingInterceptor({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRecording =
        useValueListenable(context.read<VoiceRecorderNotifier>()).status ==
        VoiceRecorderStatus.recording;
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
                onDiscard: () {
                  context
                      .read<VoiceRecorderNotifier>()
                      .cancelAndExitRecordMode();
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
              color: context.theme.popUp,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      context.l10n.discardRecordingWarning,
                      style: TextStyle(
                        fontSize: 16,
                        height: 2,
                        color: context.theme.text,
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
                          child: Text(context.l10n.cancel),
                        ),
                        MixinButton(
                          onTap: () {
                            dimiss();
                            onDiscard();
                          },
                          child: Text(context.l10n.discard),
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
    final recorderNotifier = context.read<VoiceRecorderNotifier>();
    final recorderState = useValueListenable(recorderNotifier);
    final startTime = recorderState.startTime;
    final isRecording = recorderState.status == VoiceRecorderStatus.recording;
    final recordedResult = recorderState.recordedData;

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
      color: context.theme.primary,
      child: Row(
        children: [
          ActionButton(
            name: Resources.assetsImagesCloseOvalRecordSvg,
            color: context.theme.icon,
            onTap: () async {
              final path = recordedResult?.path;
              await context
                  .read<VoiceRecorderNotifier>()
                  .cancelAndExitRecordMode();
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
              color: context.theme.accent,
              onTap: () async {
                await recorderNotifier.stopRecording();
              },
            )
          else
            ActionButton(
              name: Resources.assetsImagesRecordRetrySvg,
              color: context.theme.icon,
              onTap: () async {
                final path = recordedResult?.path;
                await recorderNotifier.startRecording();
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
              final conversationItem = ref.read(conversationProvider);
              final accountServer = context.accountServer;

              final RecordedData result;

              if (recorderNotifier.state.status ==
                  VoiceRecorderStatus.recording) {
                result = await recorderNotifier.stopRecording();
              } else {
                if (recordedResult == null) {
                  e('result is null. ${recorderNotifier.state}');
                  return;
                }
                result = recordedResult;
              }
              await recorderNotifier.cancelAndExitRecordMode();
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
              ref.read(quoteMessageProvider.notifier).state = null;
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

class _RecordedResultPreviewLayout extends HookConsumerWidget {
  const _RecordedResultPreviewLayout({required this.result});

  final RecordedData result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = useMemoized(() => _Player(result.path));
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
                    value:
                        (player.position *
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
              style: TextStyle(color: context.theme.text, fontSize: 14),
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
        style: TextStyle(color: context.theme.text, fontSize: 14),
      ),
    ],
  );
}
