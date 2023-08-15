import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../utils/logger.dart';
import '../../utils/platform.dart';

class MoveWindowBarrier extends StatelessWidget {
  const MoveWindowBarrier({
    super.key,
    required this.child,
    this.enable = true,
  });

  final Widget child;

  final bool enable;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onPanStart: enable
          ? (details) {
              // do nothing, but we already intercept the events.
            }
          : null,
      child: child);
}

/// Widget to detect mouse drag, and start move window.
/// Use [MoveWindowBarrier] to intercept window move action.
class MoveWindow extends StatelessWidget {
  const MoveWindow({
    super.key,
    this.child,
    this.behavior,
    this.clickToFullScreen = false,
  });

  final Widget? child;

  final HitTestBehavior? behavior;

  final bool clickToFullScreen;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: behavior,
        onDoubleTap: clickToFullScreen
            ? () async {
                if (defaultTargetPlatform == TargetPlatform.windows) {
                  // Disable MaximizeWindow for windows.
                  // Windows already has a title bar.
                  return;
                }
                if (!kPlatformIsDesktop) {
                  return;
                }
                if (await windowManager.isMaximized()) {
                  d('window is maximized, restore');
                  await windowManager.unmaximize();
                  if (await windowManager.isMaximized()) {
                    d('window is still maximized, set to default size');
                    const windowSize = Size(960, 720);
                    final position =
                        await calcWindowPosition(windowSize, Alignment.center);
                    await windowManager.setBounds(null,
                        position: position, size: windowSize, animate: true);
                  }
                } else {
                  d('window is not maximized, maximize');
                  await windowManager.maximize();
                }
              }
            : null,
        onPanStart: (details) {
          if (defaultTargetPlatform == TargetPlatform.windows) {
            // Disable MoveWindow for windows.
            // Windows already has a title bar.
            return;
          }
          if (!kPlatformIsDesktop) {
            return;
          }
          windowManager.startDragging();
        },
        child: child,
      );
}

/// Global default window move action detector.
class GlobalMoveWindow extends StatelessWidget {
  const GlobalMoveWindow({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        textDirection: TextDirection.ltr,
        children: [
          child,
          const Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 28,
              child: MoveWindow(clickToFullScreen: true),
            ),
          ),
        ],
      );
}
