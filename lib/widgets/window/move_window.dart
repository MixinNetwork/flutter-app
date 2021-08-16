import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MoveWindowBarrier extends StatelessWidget {
  const MoveWindowBarrier({
    Key? key,
    required this.child,
    this.enable = true,
  }) : super(key: key);

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
    Key? key,
    this.child,
    this.behavior,
  }) : super(key: key);

  final Widget? child;

  final HitTestBehavior? behavior;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: behavior,
        onPanStart: (details) {
          appWindow.startDragging();
        },
        child: child,
      );
}

/// Global default window move action detector.
class GlobalMoveWindow extends StatelessWidget {
  const GlobalMoveWindow({Key? key, required this.child}) : super(key: key);

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
