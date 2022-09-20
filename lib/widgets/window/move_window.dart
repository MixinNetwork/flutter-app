import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  });

  final Widget? child;

  final HitTestBehavior? behavior;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: behavior,
        onPanStart: (details) {
          if (defaultTargetPlatform == TargetPlatform.windows) {
            // Disable MoveWindow for windows.
            // Windows already has a title bar.
            return;
          }
          if (!kPlatformIsDesktop) {
            return;
          }
          appWindow.startDragging();
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
              child: MoveWindow(),
            ),
          ),
        ],
      );
}
