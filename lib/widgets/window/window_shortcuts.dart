import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../utils/system/main_window.dart';

class WindowShortcuts extends StatelessWidget {
  const WindowShortcuts({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.keyW, meta: true):
          _CloseWindowIntent(),
    },
    actions: {
      _CloseWindowIntent: CallbackAction(
        onInvoke: (intent) {
          mainWindow?.hide();
        },
      ),
    },
    child: child,
  );
}

class _CloseWindowIntent extends Intent {
  const _CloseWindowIntent() : super();
}
