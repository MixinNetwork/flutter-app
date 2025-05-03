import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../constants/resources.dart';
import '../utils/extension/extension.dart';
import 'action_button.dart';

class MixinBackButton extends StatelessWidget {
  const MixinBackButton({super.key, this.color, this.onTap});

  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ActionButton(
      name: Resources.assetsImagesIcBackSvg,
      color: color ?? context.theme.icon,
      onTap: () {
        if (onTap != null) return onTap?.call();
        Navigator.pop(context);
      },
    ),
  );
}

class MixinCloseButton extends StatelessWidget {
  const MixinCloseButton({super.key, this.onTap, this.color});

  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => ActionButton(
    name: Resources.assetsImagesIcCloseSvg,
    color: color ?? context.theme.icon,
    onTap: onTap ?? () => Navigator.pop(context),
  );
}

class NTapGestureDetector extends HookWidget {
  const NTapGestureDetector({
    required this.child,
    required this.n,
    super.key,
    this.onTap,
  }) : assert(n > 2, 'n must be greater than 2');

  final GestureTapCallback? onTap;
  final Widget child;
  final int n;

  @override
  Widget build(BuildContext context) {
    final click = useMemoized(() => <int>[]);
    return GestureDetector(
      onTap: () {
        final now = DateTime.now().millisecondsSinceEpoch;

        if (click.isEmpty) {
          click.add(now);
          return;
        }

        final diff = now - click.last;
        if (diff < 500) {
          click.add(now);
        } else {
          click.clear();
        }

        if (click.length == n) {
          click.clear();
          onTap?.call();
        }
      },
      child: child,
    );
  }
}
