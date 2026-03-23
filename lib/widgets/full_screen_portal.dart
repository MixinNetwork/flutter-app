import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'menu.dart';

class FullScreenPortal extends HookConsumerWidget {
  const FullScreenPortal({
    required this.builder,
    required this.portalBuilder,
    super.key,
    this.duration = const Duration(milliseconds: 100),
    this.curve = Curves.easeOut,
  });

  final WidgetBuilder builder;
  final WidgetBuilder portalBuilder;

  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = useState(false);
    return Barrier(
      duration: duration,
      visible: visible.value,
      onClose: () => visible.value = false,
      child: PortalTarget(
        closeDuration: duration,
        visible: visible.value,
        portalFollower: TweenAnimationBuilder<double>(
          duration: duration,
          tween: Tween(begin: 0, end: visible.value ? 1 : 0),
          curve: curve,
          builder: (context, progress, child) =>
              Opacity(opacity: progress, child: child),
          child: visible.value
              ? Builder(builder: portalBuilder)
              : const SizedBox(),
        ),
        child: Builder(builder: builder),
      ),
    );
  }
}
