import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../constants/resources.dart';
import '../../../../utils/extension/extension.dart';
import '../../../action_button.dart';
import 'progress_bar.dart';

Future<void> showVideoPreviewPage(BuildContext context, String path) =>
    showDialog(
      context: context,
      builder: (context) => _VideoPreviewPage(path: path),
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

class _VideoPreviewPage extends HookConsumerWidget {
  const _VideoPreviewPage({required this.path});

  final String path;

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
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: const Stack(
            children: [
              VideoFrame(),
              _Controls(),
            ],
          ),
        ),
      ),
    );
  }
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
  const _Controls();

  @override
  Widget build(BuildContext context, WidgetRef ref) => MouseRegion(
        onHover: (event) {},
        child: Column(
          children: [
            const SizedBox(height: 54),
            Row(
              children: [
                _CupertinoButton(
                  name: Resources.assetsImagesIcCloseSvg,
                  onTap: () {
                    ref.read(videoPlayerProvider)
                      ..pause()
                      ..dispose();
                    Navigator.maybePop(context);
                  },
                ),
              ],
            ),
            const Spacer(),
            const _OperationBar(),
            const SizedBox(height: 36),
          ],
        ),
      );
}

class _CupertinoButton extends StatelessWidget {
  const _CupertinoButton({
    required this.onTap,
    required this.name,
  });

  final VoidCallback onTap;
  final String name;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: _CupertinoContainer(
          child: SvgPicture.asset(
            name,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              context.theme.icon,
              BlendMode.srcIn,
            ),
          ),
        ),
      );
}

class _CupertinoContainer extends StatelessWidget {
  const _CupertinoContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ColoredBox(
            color: context.theme.background.withOpacity(0.8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: child,
            ),
          ),
        ),
      );
}

class _OperationBar extends ConsumerWidget {
  const _OperationBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Material(
          color: context.playerStyle.background,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  const _PlayerProgressBar(),
                ],
              ),
            ),
          ),
        ),
      );
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
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, minWidth: 300),
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
      color: context.playerStyle.foreground,
      name: playing
          ? Resources.assetsImagesPlayerPauseSvg
          : Resources.assetsImagesPlayerPlaySvg,
      onTap: () {
        final controller = ref.read(videoPlayerProvider);
        if (controller.value.isPlaying) {
          controller.pause();
        } else {
          controller.play();
        }
      },
    );
  }
}
