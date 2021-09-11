import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/utils/extension/extension.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

const _minCount = 30;
const _maxCount = 63;
const _minDuration = 1;
const _maxDuration = 60;
const _slope = (_maxCount - _minCount) / (_maxDuration - _minDuration);
const _intercept = _minCount - _minDuration * _slope;

const _barWidth = 2.0;
const _barRadius = _barWidth / 2;

class WaveformWidget extends HookWidget {
  const WaveformWidget({
    Key? key,
    required this.duration,
    required this.value,
    required this.width,
    required this.waveform,
  }) : super(key: key);

  final int duration;
  final double value;
  final double width;
  final List<int> waveform;

  @override
  Widget build(BuildContext context) {
    assert(value >= 0 && value <= 1);
    final samples = useMemoized(() {
      final duration = max(_minDuration, min(_maxDuration, waveform.length));
      final sampleCount = (_slope * duration + _intercept).round();
      return waveform.partition(sampleCount).map((e) => e.reduce(max)).toList();
    }, [duration, waveform]);

    print('fuck samples: $samples');

    return SizedBox(
      width: width,
      child: CustomPaint(
        painter: _WaveformPainter(
          waveform: samples,
          value: value,
          color: Colors.red,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter with EquatableMixin {
  _WaveformPainter({
    required this.value,
    required this.waveform,
    required Color color,
  }) {
    painter = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
  }

  final double value;
  final List<int> waveform;
  late final Paint painter;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    if (width == 0) return;

    final path = _path(waveform, size);

    canvas.drawPath(path, painter);
  }

  Path _path(List<int> samples, Size size) {
    final sampleX = size.width / samples.length;
    final maxSample = samples.reduce(max);
    final ratio = size.height / maxSample;
    final path = Path();
    samples.asMap().entries.forEach((entry) {
      final index = entry.key;
      final value = entry.value;

      final dy = value * ratio;
      final offset = Offset(index * sampleX, dy);
      print('fuck offset: $offset');
      path.addRRect(
          const BorderRadius.vertical(top: Radius.circular(_barRadius)).toRRect(
              offset & Size(_barWidth, dy)));
    });

    return path;
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      this != oldDelegate;

  @override
  List<Object?> get props => [value, waveform];
}
