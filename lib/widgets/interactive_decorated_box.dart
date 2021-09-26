import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum InteractiveStatus {
  interactive,
  hovering,
  tapDowning,
}

class InteractiveBuilder extends StatefulWidget {
  const InteractiveBuilder({
    Key? key,
    required this.builder,
    this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onTapUp,
    this.onRightClick,
    this.onEnter,
    this.onExit,
    this.onHover,
    this.cursor = MouseCursor.defer,
    this.behavior = HitTestBehavior.opaque,
  }) : super(key: key);

  final Widget Function(BuildContext context, InteractiveStatus status,
      InteractiveStatus lastStatus, Widget? child) builder;

  final Widget? child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final ValueChanged<LongPressStartDetails>? onLongPress;
  final GestureTapUpCallback? onTapUp;
  final ValueChanged<PointerUpEvent>? onRightClick;
  final PointerEnterEventListener? onEnter;
  final PointerExitEventListener? onExit;
  final PointerHoverEventListener? onHover;
  final MouseCursor cursor;
  final HitTestBehavior? behavior;

  @override
  _InteractiveBuilderState createState() => _InteractiveBuilderState();
}

class _InteractiveBuilderState extends State<InteractiveBuilder> {
  bool hovering = false;
  bool tapDowning = false;

  InteractiveStatus lastStatus = InteractiveStatus.interactive;

  InteractiveStatus get status {
    if (tapDowning) return InteractiveStatus.tapDowning;
    if (hovering) return InteractiveStatus.hovering;
    return InteractiveStatus.interactive;
  }

  int? lastPointerDown;

  @override
  Widget build(BuildContext context) {
    final child = widget.builder(context, status, lastStatus, widget.child);
    lastStatus = status;
    return MouseRegionIgnoreTouch(
      onEnter: (event) {
        setState(() {
          hovering = true;
        });
        widget.onEnter?.call(event);
      },
      cursor: widget.cursor,
      onHover: (event) {
        setState(() {
          hovering = true;
        });
        widget.onHover?.call(event);
      },
      onExit: (event) {
        setState(() {
          hovering = false;
        });
        widget.onExit?.call(event);
      },
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: (_) => setState(() {
          tapDowning = true;
        }),
        onTapCancel: () => setState(() {
          tapDowning = false;
        }),
        onTap: () {
          setState(() {
            tapDowning = false;
          });
          widget.onTap?.call();
        },
        onTapUp: widget.onTapUp,
        onDoubleTap: widget.onDoubleTap,
        onLongPressStart: widget.onLongPress,
        child: Listener(
          onPointerUp: (PointerUpEvent event) {
            if (event.pointer == lastPointerDown) {
              widget.onRightClick?.call(event);
            }
          },
          onPointerDown: (PointerDownEvent event) {
            if (event.buttons == kSecondaryButton) {
              lastPointerDown = event.pointer;
            }
          },
          child: child,
        ),
      ),
    );
  }
}

class InteractiveDecoratedBox extends StatelessWidget {
  const InteractiveDecoratedBox({
    Key? key,
    Decoration? decoration,
    this.hoveringDecoration,
    this.tapDowningDecoration,
    this.inDuration = const Duration(milliseconds: 120),
    this.outDuration = const Duration(milliseconds: 60),
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onTapUp,
    this.onRightClick,
    this.onEnter,
    this.onExit,
    this.onHover,
    this.cursor = MouseCursor.defer,
    this.behavior = HitTestBehavior.opaque,
  })  : _decoration = decoration,
        super(key: key);

  InteractiveDecoratedBox.color({
    Key? key,
    BoxDecoration? decoration,
    Color? hoveringColor,
    Color? tapDowningColor,
    this.inDuration = const Duration(milliseconds: 120),
    this.outDuration = const Duration(milliseconds: 60),
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onTapUp,
    this.onRightClick,
    this.onEnter,
    this.onExit,
    this.onHover,
    this.cursor = MouseCursor.defer,
    this.behavior = HitTestBehavior.opaque,
  })  : _decoration = decoration ?? const BoxDecoration(),
        hoveringDecoration = hoveringColor != null
            ? decoration?.copyWith(color: hoveringColor)
            : null,
        tapDowningDecoration = tapDowningColor != null
            ? decoration?.copyWith(color: tapDowningColor)
            : null,
        super(key: key);

  final Decoration? _decoration;
  final Decoration? hoveringDecoration;
  final Decoration? tapDowningDecoration;

  final Duration? inDuration;
  final Duration? outDuration;

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final ValueChanged<LongPressStartDetails>? onLongPress;
  final GestureTapUpCallback? onTapUp;
  final ValueChanged<PointerUpEvent>? onRightClick;

  final PointerEnterEventListener? onEnter;
  final PointerExitEventListener? onExit;
  final PointerHoverEventListener? onHover;
  final MouseCursor cursor;
  final HitTestBehavior? behavior;

  @override
  Widget build(BuildContext context) => InteractiveBuilder(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        onRightClick: onRightClick,
        onTapUp: onTapUp,
        onEnter: onEnter,
        onExit: onExit,
        onHover: onHover,
        cursor: cursor,
        behavior: behavior,
        builder: (BuildContext context, InteractiveStatus status,
                InteractiveStatus lastStatus, Widget? child) =>
            TweenAnimationBuilder<Decoration>(
          tween: DecorationTween(
            end: {
                  InteractiveStatus.interactive:
                      _decoration ?? const BoxDecoration(),
                  InteractiveStatus.hovering:
                      hoveringDecoration ?? tapDowningDecoration ?? _decoration,
                  InteractiveStatus.tapDowning:
                      tapDowningDecoration ?? hoveringDecoration ?? _decoration,
                }[status] ??
                const BoxDecoration(),
          ),
          duration: (lastStatus == InteractiveStatus.interactive &&
                      status != InteractiveStatus.interactive
                  ? inDuration
                  : outDuration) ??
              Duration.zero,
          curve: Curves.decelerate,
          builder: (BuildContext context, Decoration value, Widget? child) =>
              DecoratedBox(
            decoration: value,
            child: child,
          ),
          child: child,
        ),
        child: child,
      );
}

class MouseRegionIgnoreTouch extends StatelessWidget {
  const MouseRegionIgnoreTouch({
    Key? key,
    this.onEnter,
    this.onExit,
    this.onHover,
    this.cursor = MouseCursor.defer,
    this.opaque = true,
    this.child,
  }) : super(key: key);
  final PointerEnterEventListener? onEnter;
  final PointerExitEventListener? onExit;
  final PointerHoverEventListener? onHover;
  final MouseCursor cursor;
  final bool opaque;
  final Widget? child;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (event) {
          if (event.kind == PointerDeviceKind.touch) {
            return;
          }
          onEnter?.call(event);
        },
        onExit: (event) {
          if (event.kind == PointerDeviceKind.touch) {
            return;
          }
          onExit?.call(event);
        },
        onHover: (event) {
          if (event.kind == PointerDeviceKind.touch) {
            return;
          }
          onHover?.call(event);
        },
        cursor: cursor,
        opaque: opaque,
        child: child,
      );
}
