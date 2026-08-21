import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/utils/system/text_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'moves a multiline caret without interrupting IME composition',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final focusNode = FocusNode();
      final controller = TextEditingController.fromValue(
        const TextEditingValue(
          text: 'abc\ndef',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      addTearDown(focusNode.dispose);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextInputActionHandler(
              child: TextField(
                focusNode: focusNode,
                controller: controller,
                maxLines: 7,
              ),
            ),
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);

      expect(controller.selection.baseOffset, 2);

      controller.value = const TextEditingValue(
        text: 'abc\ndef',
        selection: TextSelection.collapsed(offset: 6),
        composing: TextRange(start: 4, end: 6),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);

      expect(controller.selection.baseOffset, 6);
      debugDefaultTargetPlatformOverride = null;
    },
    skip: !Platform.isMacOS,
  );
}
