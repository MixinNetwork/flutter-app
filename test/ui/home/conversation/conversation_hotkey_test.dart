import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/ui/home/conversation/conversation_hotkey.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('disables conversation arrows for a multiline editor', (
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

    expect(
      _conversationArrowsEnabled(tester, find.byType(EditableText)),
      isFalse,
    );
  });

  testWidgets('keeps the home subtree when focus enters a multiline editor', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    var builds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConversationHotKey(
            child: Column(
              children: [
                Builder(
                  builder: (context) {
                    Theme.of(context);
                    builds++;
                    return const SizedBox();
                  },
                ),
                TextField(focusNode: focusNode, maxLines: 2),
              ],
            ),
          ),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();

    expect(builds, 1);
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

    expect(
      _conversationArrowsEnabled(tester, find.byType(SizedBox).last),
      isTrue,
    );
  });
}

class _TestIntent extends Intent {
  const _TestIntent();
}

// Looks up the action the way the shortcut manager does, from [finder].
bool _conversationArrowsEnabled(WidgetTester tester, Finder finder) {
  const intent = NextConversationIntent();
  final action = Actions.maybeFind<NextConversationIntent>(
    tester.element(finder),
    intent: intent,
  );
  return action?.isEnabled(intent) ?? false;
}
