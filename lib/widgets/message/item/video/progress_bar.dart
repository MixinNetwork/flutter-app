import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../utils/logger.dart';

/// From project: https://github.com/fluttercommunity/chewie
class CupertinoVideoProgressBar extends StatelessWidget {
  const CupertinoVideoProgressBar(
    this.controller, {
    this.colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    super.key,
  });

  final VideoPlayerController controller;
  final ChewieProgressColors? colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;

  @override
  Widget build(BuildContext context) => VideoProgressBar(
        controller,
        barHeight: 5,
        handleHeight: 6,
        drawShadow: true,
        colors: colors ??
            ChewieProgressColors(
              playedColor: const Color.fromARGB(
                120,
                255,
                255,
                255,
              ),
              handleColor: const Color.fromARGB(
                255,
                255,
                255,
                255,
              ),
              bufferedColor: const Color.fromARGB(
                60,
                255,
                255,
                255,
              ),
              backgroundColor: const Color.fromARGB(
                20,
                255,
                255,
                255,
              ),
            ),
        onDragEnd: onDragEnd,
        onDragStart: onDragStart,
        onDragUpdate: onDragUpdate,
      );
}

class ChewieProgressColors {
  ChewieProgressColors({
    Color playedColor = const Color.fromRGBO(255, 0, 0, 0.7),
    Color bufferedColor = const Color.fromRGBO(30, 30, 200, 0.2),
    Color handleColor = const Color.fromRGBO(200, 200, 200, 1),
    Color backgroundColor = const Color.fromRGBO(200, 200, 200, 0.5),
  })  : playedPaint = Paint()..color = playedColor,
        bufferedPaint = Paint()..color = bufferedColor,
        handlePaint = Paint()..color = handleColor,
        backgroundPaint = Paint()..color = backgroundColor;

  final Paint playedPaint;
  final Paint bufferedPaint;
  final Paint handlePaint;
  final Paint backgroundPaint;
}

class VideoProgressBar extends StatefulWidget {
  VideoProgressBar(
    this.controller, {
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
    ChewieProgressColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    super.key,
  }) : colors = colors ?? ChewieProgressColors();

  final VideoPlayerController controller;
  final ChewieProgressColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;

  @override
  State createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<VideoProgressBar> {
  void listener() {
    if (!mounted) return;
    setState(() {});
  }

  bool _controllerWasPlaying = false;

  Offset? _latestDraggableOffset;

  VideoPlayerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(listener);
  }

  @override
  void deactivate() {
    controller.removeListener(listener);
    super.deactivate();
  }

  Future<void> _seekToRelativePosition(Offset globalPosition) {
    final position = context.calcRelativePosition(
      controller.value.duration,
      globalPosition,
    );
    d('player seeking to $position');
    return controller.seekTo(position);
  }

  @override
  Widget build(BuildContext context) {
    final child = StaticProgressBar(
      value: controller.value,
      colors: widget.colors,
      barHeight: widget.barHeight,
      handleHeight: widget.handleHeight,
      drawShadow: widget.drawShadow,
      latestDraggableOffset: _latestDraggableOffset,
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (DragStartDetails details) {
        if (!controller.value.isInitialized) {
          return;
        }
        _controllerWasPlaying = controller.value.isPlaying;
        if (_controllerWasPlaying) {
          controller.pause();
        }

        widget.onDragStart?.call();
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!controller.value.isInitialized) {
          return;
        }
        _latestDraggableOffset = details.globalPosition;
        listener();

        widget.onDragUpdate?.call();
      },
      onHorizontalDragEnd: (DragEndDetails details) async {
        if (_controllerWasPlaying) {
          unawaited(controller.play());
        }

        if (_latestDraggableOffset != null) {
          try {
            await _seekToRelativePosition(_latestDraggableOffset!);
          } finally {
            _latestDraggableOffset = null;
          }
        }

        widget.onDragEnd?.call();
      },
      onTapUp: (TapUpDetails details) {
        if (!controller.value.isInitialized) {
          return;
        }
        _seekToRelativePosition(details.globalPosition);
      },
      child: child,
    );
  }
}

class StaticProgressBar extends StatelessWidget {
  const StaticProgressBar({
    required this.value,
    required this.colors,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
    super.key,
    this.latestDraggableOffset,
  });

  final Offset? latestDraggableOffset;
  final VideoPlayerValue value;
  final ChewieProgressColors colors;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _ProgressBarPainter(
          value: value,
          draggableValue: context.calcRelativePosition(
            value.duration,
            latestDraggableOffset,
          ),
          colors: colors,
          barHeight: barHeight,
          handleHeight: handleHeight,
          drawShadow: drawShadow,
        ),
        child: const SizedBox(height: 20),
      );
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter({
    required this.value,
    required this.colors,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
    required this.draggableValue,
  });

  VideoPlayerValue value;
  ChewieProgressColors colors;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;
  final Duration draggableValue;

  @override
  bool shouldRepaint(CustomPainter painter) => true;

  @override
  void paint(Canvas canvas, Size size) {
    final baseOffset = size.height / 2 - barHeight / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0, baseOffset),
          Offset(size.width, baseOffset + barHeight),
        ),
        const Radius.circular(4),
      ),
      colors.backgroundPaint,
    );
    if (!value.isInitialized) {
      return;
    }
    final playedPartPercent = (draggableValue != Duration.zero
            ? draggableValue.inMilliseconds
            : value.position.inMilliseconds) /
        value.duration.inMilliseconds;
    final playedPart =
        playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    for (final range in value.buffered) {
      final start = range.startFraction(value.duration) * size.width;
      final end = range.endFraction(value.duration) * size.width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(start, baseOffset),
            Offset(end, baseOffset + barHeight),
          ),
          const Radius.circular(4),
        ),
        colors.bufferedPaint,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0, baseOffset),
          Offset(playedPart, baseOffset + barHeight),
        ),
        const Radius.circular(4),
      ),
      colors.playedPaint,
    );

    if (drawShadow) {
      final shadowPath = Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(playedPart, baseOffset + barHeight / 2),
            radius: handleHeight,
          ),
        );

      canvas.drawShadow(shadowPath, Colors.black, 0.2, false);
    }

    canvas.drawCircle(
      Offset(playedPart, baseOffset + barHeight / 2),
      handleHeight,
      colors.handlePaint,
    );
  }
}

extension RelativePositionExtensions on BuildContext {
  Duration calcRelativePosition(
    Duration videoDuration,
    Offset? globalPosition,
  ) {
    if (globalPosition == null) return Duration.zero;
    final box = findRenderObject()! as RenderBox;
    final tapPos = box.globalToLocal(globalPosition);
    final relative = tapPos.dx / box.size.width;
    final position = videoDuration * relative;
    return position;
  }
}
