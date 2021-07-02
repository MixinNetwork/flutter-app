import 'package:flutter/widgets.dart';

class CallbackTextEditingAction<T extends Intent> extends TextEditingAction<T> {
  CallbackTextEditingAction({required this.onInvoke});

  final Function(
      Intent intent, TextEditingActionTarget? textEditingActionTarget,
      [BuildContext? context]) onInvoke;

  @override
  Object? invoke(covariant Intent intent, [BuildContext? context]) =>
      onInvoke(intent, textEditingActionTarget, context);
}
