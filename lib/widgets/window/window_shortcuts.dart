import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class WindowShortcuts extends StatelessWidget {
  const WindowShortcuts({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.keyW, meta: true):
              _CloseWindowIntent()
        },
        actions: {
          _CloseWindowIntent: CallbackAction(onInvoke: (intent) {
            appWindow.hide();
          })
        },
        child: child,
      );
}

class _CloseWindowIntent extends Intent {
  const _CloseWindowIntent() : super();
}
