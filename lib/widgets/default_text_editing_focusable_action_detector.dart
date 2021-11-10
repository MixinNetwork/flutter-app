import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DefaultTextEditingFocusableActionDetector
    extends FocusableActionDetector {
  DefaultTextEditingFocusableActionDetector({
    Key? key,
    required Widget child,
  }) : super(
          key: key,
          child: child,
          shortcuts: _shortcuts,
          actions: _actions,
        );

  static Map<SingleActivator, Intent> get _macShortcuts => {
        const SingleActivator(
          LogicalKeyboardKey.keyA,
          control: true,
        ): const ExtendSelectionToLineBreakIntent(
            forward: false, collapseSelection: false),
        const SingleActivator(
          LogicalKeyboardKey.keyE,
          control: true,
        ): const ExtendSelectionToLineBreakIntent(
            forward: true, collapseSelection: false),
      };

  static Map<ShortcutActivator, Intent> get _shortcuts {
    if (kIsWeb) return {};

    return {
      if (defaultTargetPlatform == TargetPlatform.macOS) ..._macShortcuts
    };
  }

  static Map<Type, Action<Intent>> get _actions {
    if (kIsWeb) {
      return {};
    }
    return {};
  }
}
