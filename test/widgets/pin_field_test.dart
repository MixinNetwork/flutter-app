import 'dart:async';

import 'package:flutter_app/widgets/pin_field.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class _PinHost extends HookWidget {
  const _PinHost({
    required this.textController,
    required this.focusNode,
    required this.onCompleted,
  });

  final TextEditingController textController;
  final FocusNode focusNode;
  final ValueChanged<String> onCompleted;

  @override
  Widget build(BuildContext context) {
    final pinController = usePinInputController(
      textController: textController,
      focusNode: focusNode,
    );
    return MaterialPinField(
      length: 6,
      pinController: pinController,
      autoFocus: true,
      theme: borderPinTheme(
        borderColor: Colors.black,
        focusedBorderColor: Colors.black,
        filledBorderColor: Colors.black,
        borderWidth: 2,
        spacing: 25,
      ),
      onCompleted: (value) {
        onCompleted(value);
        scheduleMicrotask(pinController.clear);
      },
    );
  }
}

void main() {
  testWidgets('pin field completes, clears and accepts input again', (
    tester,
  ) async {
    final textController = TextEditingController();
    final focusNode = FocusNode();
    final completed = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _PinHost(
            textController: textController,
            focusNode: focusNode,
            onCompleted: completed.add,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(EditableText), '123456');
    await tester.pump();
    expect(completed, ['123456']);
    expect(textController.text, isEmpty);

    await tester.enterText(find.byType(EditableText), '654321');
    await tester.pump();
    expect(completed, ['123456', '654321']);

    // Unmounting disposes the pin controller but not the caller's objects.
    await tester.pumpWidget(const SizedBox());
    textController.text = 'still usable';
    focusNode.requestFocus();
    expect(tester.takeException(), isNull);

    textController.dispose();
    focusNode.dispose();
  });
}
