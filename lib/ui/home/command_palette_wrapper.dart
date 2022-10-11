import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/platform.dart';
import '../../widgets/actions/actions.dart';

class CommandPaletteWrapper extends StatelessWidget {
  const CommandPaletteWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
        shortcuts: {
          SingleActivator(
            LogicalKeyboardKey.keyK,
            meta: kPlatformIsDarwin,
            control: !kPlatformIsDarwin,
          ): const ToggleCommandPaletteIntent(),
        },
        child: child,
      );
}
