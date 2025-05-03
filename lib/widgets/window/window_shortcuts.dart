import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

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
          windowManager.hide();
        },
      ),
    },
    child: child,
  );
}

class _CloseWindowIntent extends Intent {
  const _CloseWindowIntent() : super();
}
