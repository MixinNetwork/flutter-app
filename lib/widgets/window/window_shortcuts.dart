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
              _CloseWindowIntent()
        },
        actions: {
          _CloseWindowIntent: CallbackAction(onInvoke: (intent) {
            windowManager.hide();
            // if appWindow hidden, RawKeyboard#keysPressed will not clear.
            // However TextFiled will use RawKeyboard#keysPressed to decide if
            // handle the command + V/C events.
            // so we need clear keys pressed here.
            // FIXME: remove this if flutter framework handle this case properly.
            // ignore: invalid_use_of_visible_for_testing_member
            RawKeyboard.instance.clearKeysPressed();
          })
        },
        child: child,
      );
}

class _CloseWindowIntent extends Intent {
  const _CloseWindowIntent() : super();
}
