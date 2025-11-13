import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' hide Provider;
import 'package:provider/provider.dart';

import 'interactive_decorated_box.dart';

class _HoverOverlayForceHiddenTool {
  _HoverOverlayForceHiddenTool(this.hidden, this.duration);

  final List<ValueNotifier<bool>> hidden;
  final Duration duration;

  Future<void> invoke() async {
    hidden.forEach((element) {
      element.value = true;
    });
    await Future.delayed(duration * 2);
    hidden.forEach((element) {
      element.value = false;
    });
  }
}

typedef PortalBuilder<T> =
    Widget Function(
      BuildContext context,
      T value,
      Widget Function(Widget child) portalHoverWrapper,
      Widget? child,
    );

class HoverOverlay extends HookConsumerWidget {
  const HoverOverlay({
    required this.closeDuration,
    required this.child,
    required this.portal,
    required this.duration,
    super.key,
    this.anchor = const Filled(),
    this.portalCandidateLabels = const [PortalLabel.main],
    this.closeWaitDuration = Duration.zero,
    this.inCurve = Curves.linear,
    this.outCurve = Curves.linear,
    this.delayDuration,
    this.portalBuilder,
  });

  final Widget portal;
  final Widget child;
  final Duration closeDuration;
  final Duration? delayDuration;
  final Duration duration;
  final Duration closeWaitDuration;
  final Curve inCurve;
  final Curve outCurve;
  final PortalBuilder<double>? portalBuilder;
  final List<PortalLabel<dynamic>> portalCandidateLabels;
  final Anchor anchor;

  static void forceHidden(BuildContext context) {
    context.read<_HoverOverlayForceHiddenTool>().invoke();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cancelableRef = useRef<CancelableOperation<bool>?>(null);

    final forceHidden = useState<bool>(false);

    final childHovering = useState(false);
    final portalHovering = useState(false);
    final tapped = useState(false);

    final visible = useMemoized(
      () {
        if (forceHidden.value) {
          return false;
        }

        return (!tapped.value &&
                (childHovering.value || portalHovering.value)) ||
            tapped.value;
      },
      [
        tapped.value,
        childHovering.value,
        portalHovering.value,
        forceHidden.value,
      ],
    );

    final wait = closeWaitDuration.inMicroseconds;
    final totalClose = wait + closeDuration.inMicroseconds;

    final forceHiddenTool = useMemoized(
      () => _HoverOverlayForceHiddenTool([
        forceHidden,
        childHovering,
        portalHovering,
        tapped,
      ], Duration(microseconds: totalClose)),
      [forceHidden, totalClose],
    );

    Future<void> onChildHovering(_) async {
      if (cancelableRef.value != null &&
          !cancelableRef.value!.isCanceled &&
          !cancelableRef.value!.isCompleted) {
        return;
      }

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

    Widget portalHoverWrapper(Widget child) => MouseRegionIgnoreTouch(
      onEnter: onChildHovering,
      onHover: onChildHovering,
      onExit: (_) async {
        await cancelableRef.value?.cancel();
        childHovering.value = false;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (detail) {
          if (detail.kind == PointerDeviceKind.touch) {
            tapped.value = true;
          }
        },
        child: child,
      ),
    );

    return Provider.value(
      value: forceHiddenTool,
      child: PortalTarget(
        visible: visible,
        portalCandidateLabels: portalCandidateLabels,
        anchor: anchor,
        closeDuration: Duration(microseconds: totalClose),
        portalFollower: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => tapped.value = false,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: visible ? 1 : 0),
            curve: Interval(
              visible ? 0 : (wait / totalClose),
              1,
              curve: visible ? inCurve : outCurve,
            ),
            duration: visible ? duration : Duration(microseconds: totalClose),
            builder: (context, progress, child) =>
                portalBuilder?.call(
                  context,
                  progress,
                  portalHoverWrapper,
                  child,
                ) ??
                child!,
            child: MouseRegionIgnoreTouch(
              onEnter: (_) => portalHovering.value = true,
              onHover: (_) => portalHovering.value = true,
              onExit: (_) => portalHovering.value = false,
              child: portal,
            ),
          ),
        ),
        child: portalHoverWrapper(child),
      ),
    );
  }
}
