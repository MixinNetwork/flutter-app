import 'package:flutter/widgets.dart';

class Disable extends StatelessWidget {
  const Disable({
    required this.child,
    super.key,
    this.disable = true,
  });

  final bool disable;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: disable,
        child: AnimatedOpacity(
          opacity: disable ? 0.4 : 1,
          duration: const Duration(milliseconds: 200),
          child: child,
        ),
      );
}
