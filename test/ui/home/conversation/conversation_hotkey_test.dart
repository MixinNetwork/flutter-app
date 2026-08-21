import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/ui/home/conversation/conversation_hotkey.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('does not bind conversation arrows for a multiline editor', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConversationHotKey(
            child: TextField(focusNode: focusNode, maxLines: 2),
          ),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();

    expect(_hasConversationShortcut(tester), isFalse);
  });

  testWidgets('moves the caret between lines with bare arrows', (tester) async {
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
          body: ConversationHotKey(
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
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('ancestor shortcuts receive arrows from a multiline editor', (
    tester,
  ) async {
    final focusNode = FocusNode();
    var invoked = false;
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableActionDetector(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.arrowUp): _TestIntent(),
            },
            actions: {
              _TestIntent: CallbackAction<_TestIntent>(
                onInvoke: (_) => invoked = true,
              ),
            },
            child: TextField(focusNode: focusNode, maxLines: 7),
          ),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);

    expect(invoked, isTrue);
  });

  testWidgets('keeps conversation arrows outside a multiline editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ConversationHotKey(child: SizedBox())),
      ),
    );

    expect(_hasConversationShortcut(tester), isTrue);
  });
}

class _TestIntent extends Intent {
  const _TestIntent();
}

bool _hasConversationShortcut(WidgetTester tester) => tester
    .widgetList<Shortcuts>(
      find.descendant(
        of: find.byType(ConversationHotKey),
        matching: find.byType(Shortcuts),
      ),
    )
    .any(
      (shortcuts) => shortcuts.shortcuts.values.any(
        (intent) =>
            intent is NextConversationIntent ||
            intent is PreviousConversationIntent,
      ),
    );
