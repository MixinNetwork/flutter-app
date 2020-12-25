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
  }) : super(key: key);

  final Function(BuildContext context, InteracteStatus status,
      InteracteStatus lastStatus, Widget child) builder;

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onLongPress;

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
        child: child,
      ),
    );
  }
}

class InteractableDecoratedBox extends StatelessWidget {
  const InteractableDecoratedBox({
    Key key,
    this.decoration,
    this.hoveringDecoration,
    this.tapDowningDecoration,
    this.inDuration = const Duration(milliseconds: 120),
    this.outDuration = const Duration(milliseconds: 60),
    this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  }) : super(key: key);

  final Decoration decoration;
  final Decoration hoveringDecoration;
  final Decoration tapDowningDecoration;

  final Duration inDuration;
  final Duration outDuration;

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InteracterBuilder(
      child: child,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      builder: (BuildContext context, InteracteStatus status,
              InteracteStatus lastStatus, Widget child) =>
          TweenAnimationBuilder<Decoration>(
        tween: DecorationTween(
          end: {
            InteracteStatus.interactable: decoration ?? const BoxDecoration(),
            InteracteStatus.hovering: hoveringDecoration ??
                tapDowningDecoration ??
                const BoxDecoration(),
            InteracteStatus.tapDowning: tapDowningDecoration ??
                hoveringDecoration ??
                const BoxDecoration(),
          }[status],
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
}
