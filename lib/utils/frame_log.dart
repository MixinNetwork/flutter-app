import 'dart:io';
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Profile builds with `--dart-define=MIXIN_FRAME_LOG=true` print one line per
/// frame to stderr, for measuring the real app under real input.
const _frameLogEnabled = bool.fromEnvironment('MIXIN_FRAME_LOG');

/// Adds one timeline event per widget build and render object layout and
/// paint.
const _profileWidgets = bool.fromEnvironment('MIXIN_PROFILE_WIDGETS');

void startFrameLog() {
  if (_profileWidgets) {
    debugProfileBuildsEnabledUserWidgets = true;
    debugProfileLayoutsEnabled = true;
    debugProfilePaintsEnabled = true;
  }
  if (!_frameLogEnabled) return;
  SchedulerBinding.instance.addTimingsCallback((timings) {
    final buffer = StringBuffer();
    for (final timing in timings) {
      buffer.writeln(
        '[frame] vsync_us=${timing.timestampInMicroseconds(FramePhase.vsyncStart)} '
        'wait_us=${timing.vsyncOverhead.inMicroseconds} '
        'build_us=${timing.buildDuration.inMicroseconds} '
        'raster_us=${timing.rasterDuration.inMicroseconds}',
      );
    }
    stderr.write(buffer);
  });
}
