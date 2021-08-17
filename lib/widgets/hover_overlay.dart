import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_portal/flutter_portal.dart';

class HoverOverlay extends HookWidget {
  const HoverOverlay({
    Key? key,
    required this.closeDuration,
    required this.child,
    required this.portal,
    required this.duration,
    this.closeWaitDuration = Duration.zero,
    this.inCurve = Curves.linear,
    this.outCurve = Curves.linear,
    this.childAnchor,
    this.portalAnchor,
    this.delayDuration,
    this.portalBuilder,
  }) : super(key: key);

  final Alignment? portalAnchor;
  final Alignment? childAnchor;
  final Widget portal;
  final Widget child;
  final Duration closeDuration;
  final Duration? delayDuration;
  final Duration duration;
  final Duration closeWaitDuration;
  final Curve inCurve;
  final Curve outCurve;
  final ValueWidgetBuilder<double>? portalBuilder;

  @override
  Widget build(BuildContext context) {
    final cancelableRef = useRef<CancelableOperation<bool>?>(null);

    final childHovering = useState(false);
    final portalHovering = useState(false);

    final visible = childHovering.value || portalHovering.value;

    final wait = closeWaitDuration.inMicroseconds;
    final totalClose = wait + closeDuration.inMicroseconds;

    Future<void> onChildHovering(_) async {
      if (cancelableRef.value != null &&
          !cancelableRef.value!.isCanceled &&
          !cancelableRef.value!.isCompleted) return;

      if (delayDuration != null) {
        cancelableRef.value = CancelableOperation.fromFuture(
          Future.delayed(delayDuration!, () => true),
        );
        final result = await cancelableRef.value?.valueOrCancellation(false);
        if (result ?? false) {
          childHovering.value = true;
        }
        cancelableRef.value = null;
      } else {
        childHovering.value = true;
      }
    }

    return PortalEntry(
      visible: visible,
      childAnchor: childAnchor,
      portalAnchor: portalAnchor,
      closeDuration: Duration(microseconds: totalClose),
      portal: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: visible ? 1 : 0),
        curve: Interval(
          visible ? 0 : (wait / totalClose),
          1,
          curve: visible ? inCurve : outCurve,
        ),
        duration: visible ? duration : Duration(microseconds: totalClose),
        builder: (context, progress, child) =>
            portalBuilder?.call(context, progress, child) ?? child!,
        child: MouseRegion(
          onEnter: (_) => portalHovering.value = true,
          onHover: (_) => portalHovering.value = true,
          onExit: (_) => portalHovering.value = false,
          child: portal,
        ),
      ),
      child: MouseRegion(
        onEnter: onChildHovering,
        onHover: onChildHovering,
        onExit: (_) async {
          await cancelableRef.value?.cancel();
          childHovering.value = false;
        },
        child: child,
      ),
    );
  }
}
