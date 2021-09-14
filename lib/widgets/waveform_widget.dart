import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

const _barMinHeight = 2.0;
const _maxBarCount = 60;
const _barWidth = 2.0;
const _barRadius = _barWidth / 2;
const _barSpacing = 2.0;

class WaveformWidget extends HookWidget {
  const WaveformWidget({
    Key? key,
    required this.duration,
    required this.value,
    required this.width,
    required this.waveform,
    required this.backgroundColor,
    required this.foregroundColor,
  }) : super(key: key);

  final int duration;
  final double value;
  final double width;
  final List<int> waveform;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    assert(value >= 0 && value <= 1);

    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) => HookBuilder(
        builder: (context) {
          final maxBarCount =
              ((constraints.maxWidth + _barSpacing) / (_barWidth + _barSpacing))
                  .floor();

          final samples = useMemoized(() {
            final sampleCount =
                min(min(waveform.length, _maxBarCount), maxBarCount);
            return waveform.asMap().entries.fold<List<int>>(
                List.filled(sampleCount, 0), (previousValue, element) {
              final index = element.key;
              final value = element.value;

              final i = (index * sampleCount / waveform.length).floor();

              previousValue[i] = max(previousValue[i], value);
              return previousValue;
            });
          }, [waveform, constraints.maxWidth]);

          final width =
              (samples.length * (_barWidth + _barSpacing)) - _barSpacing;
          return SizedBox(
            width: width,
            child: CustomPaint(
              painter: _WaveformPainter(
                waveform: samples,
                value: value,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter with EquatableMixin {
  _WaveformPainter({
    required this.value,
    required this.waveform,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    backgroundPainter = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    foregroundPainter = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.fill;
  }

  final double value;
  final List<int> waveform;
  late final Paint backgroundPainter;
  late final Paint foregroundPainter;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    if (width == 0) return;

    final path = _path(waveform, size);

    final progress = width * value;

    final foregroundPath = Path.combine(
      PathOperation.intersect,
      Path()..addRect(Rect.fromLTRB(0, 0, progress, height)),
      path,
    );
    final backgroundPath = Path.combine(
      PathOperation.intersect,
      Path()..addRect(Rect.fromLTRB(progress, 0, width, height)),
      path,
    );

    canvas
      ..drawPath(foregroundPath, foregroundPainter)
      ..drawPath(backgroundPath, backgroundPainter);
  }

  Path _path(List<int> samples, Size size) {
    const sampleX = _barWidth + _barSpacing;
    final maxSample = samples.reduce(max);

    final height = size.height;
    final minTop = height - _barMinHeight;

    final ratio = height / maxSample;
    final path = Path();

    samples.asMap().entries.forEach((entry) {
      final index = entry.key;
      final value = entry.value;

      final top = min(height - value * ratio, minTop);
      final left = index * sampleX;
      final right = left + _barWidth;
      path.addRRect(
          const BorderRadius.vertical(top: Radius.circular(_barRadius)).toRRect(
        Rect.fromLTRB(
          left,
          top,
          right,
          height,
        ),
      ));
    });

    return path;
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      this != oldDelegate;

  @override
  List<Object?> get props => [
        value,
        waveform,
        backgroundPainter.color,
        foregroundPainter.color,
      ];
}
