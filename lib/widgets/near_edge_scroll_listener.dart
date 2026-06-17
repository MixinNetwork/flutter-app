import 'package:flutter/widgets.dart';

class NearEdgeScrollListener extends StatelessWidget {
  const NearEdgeScrollListener({
    required this.child,
    this.onNearStart,
    this.onNearEnd,
    this.viewportFraction = 0.5,
    super.key,
  });

  final Widget child;
  final VoidCallback? onNearStart;
  final VoidCallback? onNearEnd;
  final double viewportFraction;

  @override
  Widget build(
    BuildContext context,
  ) => NotificationListener<ScrollNotification>(
    onNotification: (notification) {
      if (notification is! ScrollUpdateNotification) return false;
      final scrollDelta = notification.scrollDelta;
      if (scrollDelta == null || scrollDelta == 0) return false;

      final threshold =
          notification.metrics.viewportDimension * viewportFraction;
      if (scrollDelta > 0) {
        if (notification.metrics.maxScrollExtent - notification.metrics.pixels <
            threshold) {
          onNearEnd?.call();
        }
      } else {
        if ((notification.metrics.minScrollExtent - notification.metrics.pixels)
                .abs() <
            threshold) {
          onNearStart?.call();
        }
      }

      return false;
    },
    child: child,
  );
}
