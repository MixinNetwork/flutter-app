import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../constants/resources.dart';
import '../../../../db/mixin_database.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/system/clipboard.dart';
import '../../../action_button.dart';
import '../../../avatar_view/avatar_view.dart';
import '../../../user_selector/conversation_selector.dart';
import '../../message.dart';
import 'progress_bar.dart';
import 'slider.dart';

Future<void> showVideoPreviewPage(
  BuildContext context,
  String path, {
  required MessageItem message,
  required bool isTranscriptPage,
}) =>
    showDialog(
      context: context,
      builder: (context) => _VideoPreviewPage(
        path: path,
        message: message,
        isTranscriptPage: isTranscriptPage,
      ),
      barrierDismissible: false,
    );

final videoPlayerProvider =
    ChangeNotifierProvider<VideoPlayerController>((ref) {
  throw UnimplementedError();
});

class _CupertinoVideoPlayerStyle extends InheritedWidget {
  const _CupertinoVideoPlayerStyle({
    required super.child,
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;

  static _CupertinoVideoPlayerStyle of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<_CupertinoVideoPlayerStyle>();
    assert(result != null, 'No _CupertinoVideoStyle found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(_CupertinoVideoPlayerStyle old) =>
      background != old.background || foreground != old.foreground;
}

extension on BuildContext {
  _CupertinoVideoPlayerStyle get playerStyle =>
      _CupertinoVideoPlayerStyle.of(this);
}

final videoPlayerValueProvider =
    videoPlayerProvider.select((value) => value.value);

final shouldShowVideoControlProvider =
    StateNotifierProvider.autoDispose<_VideoControlShowHideNotifier, bool>(
  (ref) => _VideoControlShowHideNotifier(true),
);

class _VideoControlShowHideNotifier extends StateNotifier<bool> {
  _VideoControlShowHideNotifier(super.state) {
    _autoHide();
  }

  Timer? _timer;

  Future<void> _autoHide() async {
    if (!state) {
      return;
    }
    _timer = Timer(const Duration(seconds: 3), () {
      state = false;
    });
  }

  void shouldShow() {
    state = true;
    _timer?.cancel();
    _timer = null;
    _autoHide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class _VideoPreviewPage extends HookConsumerWidget {
  const _VideoPreviewPage({
    required this.path,
    required this.message,
    required this.isTranscriptPage,
  });

  final String path;
  final MessageItem message;
  final bool isTranscriptPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useMemoized(() {
      final controller = VideoPlayerController.file(File(path));
      return controller
        ..initialize()
        ..play();
    });

    useEffect(() => controller.dispose, [controller]);

    return ProviderScope(
      overrides: [
        videoPlayerProvider.overrideWith((ref) => controller),
      ],
      child: _CupertinoVideoPlayerStyle(
        background: const Color.fromRGBO(41, 41, 41, 0.7),
        foreground: const Color.fromARGB(255, 200, 200, 200),
        child: _PlayerShortcuts(
          path: path,
          child: Column(
            children: [
              _Bar(
                message: message,
                isTranscriptPage: isTranscriptPage,
              ),
              Expanded(
                child: Stack(
                  children: [
                    ColoredBox(
                      color: context.theme.background,
                      child: const SizedBox.expand(),
                    ),
                    const VideoFrame(),
                    _Controls(
                      message: message,
                      isTranscriptPage: isTranscriptPage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MuteOrUnMuteIntent extends Intent {
  const _MuteOrUnMuteIntent();
}

class _PlayPauseIntent extends Intent {
  const _PlayPauseIntent();
}

class _ForwardIntent extends Intent {
  const _ForwardIntent();
}

class _CopyIntent extends Intent {
  const _CopyIntent();
}

class _BackwardIntent extends Intent {
  const _BackwardIntent();
}

class _UpVolumeIntent extends Intent {
  const _UpVolumeIntent();
}

class _DownVolumeIntent extends Intent {
  const _DownVolumeIntent();
}

class _CloseIntent extends Intent {
  const _CloseIntent();
}

class _PlayerShortcuts extends HookConsumerWidget {
  const _PlayerShortcuts({
    required this.child,
    required this.path,
  });

  final Widget child;
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final node = useFocusScopeNode();
    final volumeBeforeMuted = useRef<double?>(null);
    return FocusableActionDetector(
      actions: {
        _MuteOrUnMuteIntent:
            CallbackAction<_MuteOrUnMuteIntent>(onInvoke: (intent) {
          final controller = ref.read(videoPlayerProvider);
          if (controller.value.volume == 0) {
            final target = volumeBeforeMuted.value ?? 0.5;
            controller.setVolume(target);
          } else {
            volumeBeforeMuted.value = controller.value.volume;
            controller.setVolume(0);
          }
        }),
        _PlayPauseIntent: CallbackAction<_PlayPauseIntent>(onInvoke: (intent) {
          final controller = ref.read(videoPlayerProvider);
          if (controller.value.isPlaying) {
            controller.pause();
          } else {
            controller.play();
          }
          ref.read(shouldShowVideoControlProvider.notifier).shouldShow();
        }),
        _ForwardIntent: CallbackAction<_ForwardIntent>(onInvoke: (intent) {
          final position =
              ref.read(videoPlayerValueProvider).position.inMilliseconds;
          final target = math.min(
              ref.read(videoPlayerValueProvider).duration.inMilliseconds,
              position + 15 * 1000);
          ref.read(videoPlayerProvider).seekTo(target.milliseconds);
        }),
        _CopyIntent:
            CallbackAction<_CopyIntent>(onInvoke: (intent) => copyFile(path)),
        _BackwardIntent: CallbackAction<_BackwardIntent>(onInvoke: (intent) {
          final position =
              ref.read(videoPlayerValueProvider).position.inMilliseconds;
          final target = math.max(0, position - 15 * 1000);
          ref.read(videoPlayerProvider).seekTo(target.milliseconds);
        }),
        _UpVolumeIntent: CallbackAction<_UpVolumeIntent>(onInvoke: (intent) {
          final controller = ref.read(videoPlayerProvider);
          final volume = controller.value.volume.clamp(0.0, 1.0);
          controller.setVolume(volume + 0.1);
        }),
        _DownVolumeIntent:
            CallbackAction<_DownVolumeIntent>(onInvoke: (intent) {
          final controller = ref.read(videoPlayerProvider);
          final volume = controller.value.volume.clamp(0.0, 1.0);
          controller.setVolume(volume - 0.1);
        }),
        _CloseIntent: CallbackAction<_CloseIntent>(onInvoke: (intent) {
          ref.read(videoPlayerProvider)
            ..pause()
            ..dispose();
          Navigator.pop(context);
        }),
      },
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyM, meta: true):
            _MuteOrUnMuteIntent(),
        SingleActivator(LogicalKeyboardKey.space): _PlayPauseIntent(),
        SingleActivator(LogicalKeyboardKey.arrowRight): _ForwardIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _BackwardIntent(),
        SingleActivator(LogicalKeyboardKey.keyC, meta: true): _CopyIntent(),
        SingleActivator(LogicalKeyboardKey.arrowUp): _UpVolumeIntent(),
        SingleActivator(LogicalKeyboardKey.arrowDown): _DownVolumeIntent(),
        SingleActivator(LogicalKeyboardKey.escape): _CloseIntent(),
      },
      child: FocusScope(
        node: node,
        autofocus: true,
        child: child,
      ),
    );
  }
}

class _Bar extends ConsumerWidget {
  const _Bar({
    required this.message,
    required this.isTranscriptPage,
  });

  final MessageItem message;
  final bool isTranscriptPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        color: context.theme.primary,
        height: 70,
        child: Row(
          children: [
            const SizedBox(width: 100),
            AvatarWidget(
              name: message.userFullName,
              size: 36,
              avatarUrl: message.avatarUrl,
              userId: message.userId,
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 200,
                  ),
                  child: Text(
                    message.userFullName!,
                    style: TextStyle(
                      fontSize: MessageItemWidget.primaryFontSize,
                      color: context.theme.text,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Text(
                  message.userIdentityNumber,
                  style: TextStyle(
                    fontSize: MessageItemWidget.secondaryFontSize,
                    color: context.theme.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            const Spacer(),
            if (!isTranscriptPage)
              ActionButton(
                name: Resources.assetsImagesShareSvg,
                size: 20,
                color: context.theme.icon,
                onTap: () async {
                  final accountServer = context.accountServer;
                  final result = await showConversationSelector(
                    context: context,
                    singleSelect: true,
                    title: context.l10n.forward,
                    onlyContact: false,
                  );
                  if (result == null || result.isEmpty) return;
                  await accountServer.forwardMessage(
                    message.messageId,
                    result.first.encryptCategory!,
                    conversationId: result.first.conversationId,
                    recipientId: result.first.userId,
                  );
                },
              ),
            const SizedBox(width: 14),
            ActionButton(
              name: Resources.assetsImagesCopySvg,
              color: context.theme.icon,
              size: 20,
              onTap: () => copyFile(context.accountServer
                  .convertMessageAbsolutePath(message, isTranscriptPage)),
            ),
            const SizedBox(width: 14),
            ActionButton(
              name: Resources.assetsImagesAttachmentDownloadSvg,
              color: context.theme.icon,
              size: 20,
              onTap: () async {
                if (message.mediaUrl?.isEmpty ?? true) return;
                await saveAs(
                    context, context.accountServer, message, isTranscriptPage);
              },
            ),
            const SizedBox(width: 14),
            ActionButton(
              name: Resources.assetsImagesIcCloseBigSvg,
              color: context.theme.icon,
              size: 20,
              onTap: () {
                Actions.invoke(context, const _CloseIntent());
              },
            ),
            const SizedBox(width: 24),
          ],
        ),
      );
}

class VideoFrame extends ConsumerWidget {
  const VideoFrame({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aspect = ref
        .watch(videoPlayerProvider.select((value) => value.value.aspectRatio));
    final controller = ref.watch(videoPlayerProvider.select((value) => value));
    return Center(
      child: AspectRatio(
        aspectRatio: aspect,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls({
    required this.message,
    required this.isTranscriptPage,
  });

  final MessageItem message;
  final bool isTranscriptPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showControl = ref.watch(shouldShowVideoControlProvider);
    return SizedBox.expand(
      child: MouseRegion(
        onHover: (event) {
          ref.read(shouldShowVideoControlProvider.notifier).shouldShow();
        },
        child: Stack(
          children: [
            if (showControl)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _OperationBar(
                    message: message,
                    isTranscriptPage: isTranscriptPage,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OperationBar extends ConsumerWidget {
  const _OperationBar({
    required this.message,
    required this.isTranscriptPage,
  });

  final MessageItem message;
  final bool isTranscriptPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Material(
          color: context.playerStyle.background,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500, minWidth: 300),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: _PlayerVolumeBar()),
                        ActionButton(
                          child: Icon(
                            CupertinoIcons.gobackward_15,
                            color: context.playerStyle.foreground,
                          ),
                          onTap: () {
                            final position = ref
                                .read(videoPlayerValueProvider)
                                .position
                                .inMilliseconds;
                            final target = math.max(0, position - 15 * 1000);
                            ref
                                .read(videoPlayerProvider)
                                .seekTo(target.milliseconds);
                          },
                        ),
                        const SizedBox(width: 8),
                        const _PlayPause(),
                        const SizedBox(width: 8),
                        ActionButton(
                          child: Icon(
                            CupertinoIcons.goforward_15,
                            color: context.playerStyle.foreground,
                          ),
                          onTap: () {
                            final position = ref
                                .read(videoPlayerValueProvider)
                                .position
                                .inMilliseconds;
                            final target = math.min(
                                ref
                                    .read(videoPlayerValueProvider)
                                    .duration
                                    .inMilliseconds,
                                position + 15 * 1000);
                            ref
                                .read(videoPlayerProvider)
                                .seekTo(target.milliseconds);
                          },
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const _PlayerProgressBar(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _PlayerVolumeBar extends HookConsumerWidget {
  const _PlayerVolumeBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volume = ref.watch(videoPlayerValueProvider
        .select((value) => value.volume.clamp(0.0, 1.0)));
    return Row(
      children: [
        ActionButton(
          padding: const EdgeInsets.all(4),
          child: Icon(
            color: context.playerStyle.foreground,
            switch (volume) {
              0 => CupertinoIcons.speaker_slash,
              < 0.25 => CupertinoIcons.speaker,
              < 0.5 => CupertinoIcons.speaker_1,
              < 0.75 => CupertinoIcons.speaker_2,
              _ => CupertinoIcons.speaker_3,
            },
          ),
          onTap: () => Actions.invoke(context, const _MuteOrUnMuteIntent()),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: SliderTheme(
            data: const SliderThemeData(
              trackHeight: 2,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: 6,
                elevation: 0,
              ),
              trackShape: UnboundedRoundedRectSliderTrackShape(
                removeAdditionalActiveTrackHeight: true,
              ),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: 10,
              ),
              showValueIndicator: ShowValueIndicator.always,
            ),
            child: Slider(
              value: volume,
              allowedInteraction: SliderInteraction.tapAndSlide,
              activeColor: context.theme.accent,
              inactiveColor:
                  context.playerStyle.foreground.withValues(alpha: 0.6),
              thumbColor: context.playerStyle.foreground,
              onChanged: (value) {
                ref.read(videoPlayerProvider).setVolume(value);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerProgressBar extends HookConsumerWidget {
  const _PlayerProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final durationText = ref.watch(videoPlayerValueProvider
        .select((value) => value.duration.asMinutesSeconds));
    final positionText = ref.watch(videoPlayerValueProvider
        .select((value) => value.position.asMinutesSeconds));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          positionText,
          style: TextStyle(
            fontSize: 12,
            color: context.playerStyle.foreground,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CupertinoVideoProgressBar(
            ref.watch(videoPlayerProvider.select((value) => value)),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          durationText,
          style: TextStyle(
            fontSize: 12,
            color: context.playerStyle.foreground,
          ),
        ),
      ],
    );
  }
}

class _PlayPause extends ConsumerWidget {
  const _PlayPause();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing =
        ref.watch(videoPlayerValueProvider.select((value) => value.isPlaying));
    return ActionButton(
      size: 32,
      color: context.playerStyle.foreground,
      name: playing
          ? Resources.assetsImagesPlayerPauseSvg
          : Resources.assetsImagesPlayerPlaySvg,
      onTap: () => Actions.invoke(context, const _PlayPauseIntent()),
    );
  }
}
