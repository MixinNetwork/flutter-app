import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../utils/app_lifecycle.dart';
import '../utils/logger.dart';

class FocusHelper extends HookWidget {
  const FocusHelper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    useDesktopLifecycleAutoFocus();
    useEditableTextAutoCleanSelection();

    return child;
  }
}

void useDesktopLifecycleAutoFocus() {
  final ref = useRef<FocusNode?>(null);
  useEffect(() {
    void onListen() {
      if (isAppActive) {
        ref.value?.requestFocus();
        ref.value = null;
        return;
      }
      ref.value = FocusManager.instance.primaryFocus;
      ref.value?.unfocus();
    }

    appActiveListener.addListener(onListen);
    return () {
      appActiveListener.removeListener(onListen);
      ref.value = null;
    };
  }, []);
}

void _cleanSelection(BuildContext? context) {
  try {
    final editableText = context?.findAncestorWidgetOfExactType<EditableText>();
    if (editableText == null) {
      return;
    }

    final controller = editableText.controller;
    final selection = controller.selection;
    controller.selection = selection.copyWith(
      baseOffset: selection.baseOffset,
      extentOffset: selection.baseOffset,
      isDirectional: true,
    );
  } catch (error, stacktrace) {
    e('_cleanSelection $error $stacktrace');
  }
}

void useEditableTextAutoCleanSelection() {
  final previousFocusRef = useRef<FocusNode?>(null);
  useEffect(() {
    void listener() {
      if (!isAppActive) return;

      final primaryFocus = FocusManager.instance.primaryFocus;
      if (previousFocusRef.value == primaryFocus) return;

      _cleanSelection(previousFocusRef.value?.context);

      previousFocusRef.value = primaryFocus;
    }

    FocusManager.instance.addListener(listener);
    return () {
      FocusManager.instance.removeListener(listener);
      previousFocusRef.value = null;
    };
  }, []);
}
