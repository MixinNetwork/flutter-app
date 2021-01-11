import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

enum InteracteStatus {
  interactable,
  hovering,
  tapDowning,
}

class InteracterBuilder extends StatefulWidget {
  const InteracterBuilder({
    Key key,
    @required this.builder,
    this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onRightClick,
  }) : super(key: key);

  final Function(BuildContext context, InteracteStatus status,
      InteracteStatus lastStatus, Widget child) builder;

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onLongPress;
  final ValueChanged<PointerUpEvent> onRightClick;

  @override
  _InteracterBuilderState createState() => _InteracterBuilderState();
}

class _InteracterBuilderState extends State<InteracterBuilder> {
  bool hovering = false;
  bool tapDowning = false;

  InteracteStatus lastStatus = InteracteStatus.interactable;

  InteracteStatus get status {
    if (tapDowning) return InteracteStatus.tapDowning;
    if (hovering) return InteracteStatus.hovering;
    return InteracteStatus.interactable;
  }

  int lastPointerDown;

  @override
  Widget build(BuildContext context) {
    final child = widget.builder(context, status, lastStatus, widget.child);
    lastStatus = status;
    return MouseRegion(
      onEnter: (_) => setState(() {
        hovering = true;
      }),
      onExit: (_) => setState(() {
        hovering = false;
      }),
      child: GestureDetector(
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
        onDoubleTap: widget.onDoubleTap,
        onLongPress: widget.onLongPress,
        child: Listener(
          onPointerUp: (PointerUpEvent event) {
            if (event.pointer == lastPointerDown)
              widget.onRightClick?.call(event);
          },
          onPointerDown: (PointerDownEvent event) {
            if (event.buttons == kSecondaryButton)
              lastPointerDown = event.pointer;
          },
          child: child,
        ),
      ),
    );
  }
}

class InteractableDecoratedBox extends StatelessWidget {
  const InteractableDecoratedBox({
    Key key,
    Decoration decoration,
    this.hoveringDecoration,
    this.tapDowningDecoration,
    this.inDuration = const Duration(milliseconds: 120),
    this.outDuration = const Duration(milliseconds: 60),
    this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onRightClick,
  })  : _decoration = decoration,
        super(key: key);

  InteractableDecoratedBox.color({
    Key key,
    BoxDecoration decoration,
    Color hoveringColor,
    Color tapDowningColor,
    this.inDuration = const Duration(milliseconds: 120),
    this.outDuration = const Duration(milliseconds: 60),
    this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onRightClick,
  })  : _decoration = decoration ?? const BoxDecoration(),
        hoveringDecoration = hoveringColor != null
            ? decoration?.copyWith(color: hoveringColor)
            : null,
        tapDowningDecoration = tapDowningColor != null
            ? decoration?.copyWith(color: tapDowningColor)
            : null,
        super(key: key);

  final Decoration _decoration;
  final Decoration hoveringDecoration;
  final Decoration tapDowningDecoration;

  final Duration inDuration;
  final Duration outDuration;

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onLongPress;
  final ValueChanged<PointerUpEvent> onRightClick;

  @override
  Widget build(BuildContext context) => InteracterBuilder(
        child: child,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        onRightClick: onRightClick,
        builder: (BuildContext context, InteracteStatus status,
                InteracteStatus lastStatus, Widget child) =>
            TweenAnimationBuilder<Decoration>(
          tween: DecorationTween(
            end: {
                  InteracteStatus.interactable:
                      _decoration ?? const BoxDecoration(),
                  InteracteStatus.hovering:
                      hoveringDecoration ?? tapDowningDecoration ?? _decoration,
                  InteracteStatus.tapDowning:
                      tapDowningDecoration ?? hoveringDecoration ?? _decoration,
                }[status] ??
                const BoxDecoration(),
          ),
          duration: lastStatus == InteracteStatus.interactable &&
                  status != InteracteStatus.interactable
              ? inDuration
              : outDuration,
          curve: Curves.decelerate,
          child: child,
          builder: (BuildContext context, Decoration value, Widget child) =>
              DecoratedBox(
            decoration: value,
            child: child,
          ),
        ),
      );
}
