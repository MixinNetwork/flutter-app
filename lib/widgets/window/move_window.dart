import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:window_manager/window_manager.dart';

import '../../utils/logger.dart';
import '../../utils/system/main_window.dart';

class MoveWindowBarrier extends StatelessWidget {
  const MoveWindowBarrier({required this.child, super.key, this.enable = true});

  final Widget child;

  final bool enable;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onPanStart: enable
        ? (details) {
            // do nothing, but we already intercept the events.
          }
        : null,
    child: child,
  );
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
        ? () {
            if (!Platform.isMacOS) return;
            final window = mainWindow;
            if (window == null) return;
            if (window.isMaximized) {
              d('window is maximized, restore');
              window.unmaximize();
              if (window.isMaximized) {
                d('window is still maximized, set to default size');
                final bounds = Rect.fromCenter(
                  center:
                      workAreaUnderCursor?.center ??
                      window.bounds.toRect().center,
                  width: 960,
                  height: 720,
                ).toNative();
                if (!window.animateBounds(bounds)) window.bounds = bounds;
              }
            } else {
              d('window is not maximized, maximize');
              window.maximize();
            }
          }
        : null,
    onPanStart: (details) {
      if (defaultTargetPlatform == TargetPlatform.windows) {
        // Disable MoveWindow for windows.
        // Windows already has a title bar.
        return;
      }
      mainWindow?.startDragging();
    },
    child: child,
  );
}

/// Global default window move action detector.
class GlobalMoveWindow extends StatelessWidget {
  const GlobalMoveWindow({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    textDirection: TextDirection.ltr,
    children: [
      child,
      const Align(
        alignment: Alignment.topCenter,
        child: SizedBox(height: 28, child: MoveWindow(clickToFullScreen: true)),
      ),
    ],
  );
}
