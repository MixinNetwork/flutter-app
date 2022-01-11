import 'dart:convert';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:very_good_analysis/very_good_analysis.dart';

import '../../ui/video/video_play_window.dart';
import '../../utils/extension/extension.dart';
import '../../utils/logger.dart';

enum WindowBusinessType { video }

const _kParamType = 'type';
const _kParamArgs = 'args';

Future<void> launchVideoPlayerWindow(
  String path, {
  required String windowName,
}) async {
  final controller = await DesktopMultiWindow.createWindow(jsonEncode({
    _kParamType: WindowBusinessType.video.name,
    _kParamArgs: path,
  }));
  unawaited(controller.setSize(const Size(1280, 750)));
  unawaited(controller.center());
  unawaited(controller.setTitle(windowName));
  unawaited(controller.show());
}

void runSubWindow(List<String> args) {
  i('display SubWindow: $args');
  assert(args.length >= 3);
  assert(args.firstOrNull == 'multi_window');
  final windowId = int.tryParse(args.getOrNull(1) ?? '');
  if (windowId == null) {
    e('Invalid window id: $windowId');
    return;
  }
  final launchArgsStr = args.getOrNull(2);
  final map = launchArgsStr == null ? null : jsonDecode(launchArgsStr) as Map;
  if (map == null || map.isEmpty || !map.containsKey(_kParamType)) {
    e('Invalid launch args: $launchArgsStr');
    WindowController.fromWindowId(windowId).close();
    return;
  }
  final type = WindowBusinessType.values.byName(map[_kParamType] as String);
  switch (type) {
    case WindowBusinessType.video:
      _runVideoPlayer(windowId, map[_kParamArgs] as String);
      break;
  }
}

void _runVideoPlayer(int windowId, String path) {
  DartVLC.initialize();
  runApp(MaterialApp(
    home: VideoPlayerWindow(path: path),
  ));
}
