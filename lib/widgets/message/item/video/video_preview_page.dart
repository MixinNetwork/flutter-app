import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../constants/resources.dart';
import '../../../../utils/extension/extension.dart';
import '../../../action_button.dart';

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
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: const Stack(
          children: [
            VideoFrame(),
            _Controls(),
          ],
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
            const Spacer(),
            Row(
              children: [
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                ),
                IconButton(
                  onPressed: () {
                    ref.read(videoPlayerProvider).pause();
                  },
                  icon: const Icon(Icons.pause),
                ),
                const Spacer(),
              ],
            ),
            const _OperationBar(),
            const SizedBox(height: 36),
          ],
        ),
      );
}

class _OperationBar extends ConsumerWidget {
  const _OperationBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Material(
          color: context.theme.background.withOpacity(0.5),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ActionButton(
                      child: const Icon(CupertinoIcons.gobackward_15),
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
                    const _PlayPause(),
                    ActionButton(
                      child: const Icon(CupertinoIcons.goforward_15),
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
                const SizedBox(height: 16),
              ],
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
        SizedBox(
          width: 48,
          child: Center(
            child: Text(
              positionText,
              style: TextStyle(
                fontSize: 14,
                color: context.theme.text,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: const _PlayerProgressSlider(),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 48,
          child: Center(
            child: Text(
              durationText,
              style: TextStyle(
                fontSize: 14,
                color: context.theme.text,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerProgressSlider extends HookConsumerWidget {
  const _PlayerProgressSlider();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userTrackingValue = useState<double?>(null);
    final position = ref
        .watch(videoPlayerValueProvider.select((value) => value.position))
        .inMilliseconds
        .toDouble();
    final duration = ref
        .watch(videoPlayerValueProvider.select((value) => value.duration))
        .inMilliseconds
        .toDouble();
    return Slider(
      max: duration,
      value: (userTrackingValue.value ?? position).clamp(
        0.0,
        duration,
      ),
      onChangeStart: (value) => userTrackingValue.value = value,
      onChanged: (value) => userTrackingValue.value = value,
      semanticFormatterCallback: (value) =>
          value.round().milliseconds.asMinutesSeconds,
      onChangeEnd: (value) {
        userTrackingValue.value = null;
        ref
            .read(videoPlayerProvider)
            .seekTo(Duration(milliseconds: value.round()));
      },
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
      color: context.theme.icon,
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
