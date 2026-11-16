import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/core/read_model/mention_read_model.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/provider/conversation_provider.dart';
import 'package:flutter_app/ui/provider/mention_cache_provider.dart';
import 'package:flutter_app/ui/provider/mention_provider.dart';
import 'package:flutter_app/ui/provider/multi_auth_provider.dart';
import 'package:flutter_app/utils/platform.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/mention_panel.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _users = [
  User(
    userId: '00000000-0000-0000-0000-000000000001',
    identityNumber: '7001',
    fullName: 'Alice',
  ),
  User(
    userId: '00000000-0000-0000-0000-000000000002',
    identityNumber: '7002',
    fullName: 'Bob',
  ),
  User(
    userId: '00000000-0000-0000-0000-000000000003',
    identityNumber: '7003',
    fullName: 'Carol',
  ),
];

class _MentionReadModel extends Fake implements MentionReadModel {
  @override
  Stream<List<User>> friends() => Stream.value(_users);

  @override
  Stream<List<User>> searchBotGroupUsers({
    required String currentUserId,
    required String conversationId,
    required String keyword,
  }) => Stream.value(
    _users
        .where(
          (user) =>
              user.fullName!.toLowerCase().contains(keyword.toLowerCase()),
        )
        .toList(),
  );
}

class _ConversationNotifier extends StateNotifier<ConversationState?>
    implements ConversationStateNotifier {
  _ConversationNotifier()
    : super(
        const ConversationState(
          conversationId: 'bot-conversation',
          refreshKey: 'test',
          user: User(userId: 'bot', identityNumber: '7000'),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

typedef _MentionField = ({
  TextEditingController controller,
  FocusNode focusNode,
  ProviderContainer container,
  AutoDisposeStateNotifierProvider<MentionStateNotifier, MentionState> mentions,
  MentionCache cache,
});

Future<_MentionField> _pumpMentionField(
  WidgetTester tester,
  TargetPlatform platform,
) async {
  debugDefaultTargetPlatformOverride = platform;
  final isDarwin = kPlatformIsDarwin;
  kPlatformIsDarwin = platform == TargetPlatform.macOS;
  addTearDown(() {
    debugDefaultTargetPlatformOverride = null;
    kPlatformIsDarwin = isDarwin;
  });
  final controller = TextEditingController();
  final focusNode = FocusNode(onKeyEvent: (_, _) => KeyEventResult.ignored);
  final values = StreamController<TextEditingValue>.broadcast();
  final auth = MultiAuthStateNotifier(const MultiAuthState());
  final cache = MentionCache(null);
  final mentions =
      StateNotifierProvider.autoDispose<MentionStateNotifier, MentionState>(
        (ref) => MentionStateNotifier(
          readModel: _MentionReadModel(),
          multiAuthChangeNotifier: auth,
          textEditingValueStream: values.stream,
          conversationId: 'bot-conversation',
          isGroup: false,
          isBot: true,
        ),
      );
  final container = ProviderContainer(
    overrides: [
      conversationProvider.overrideWith((ref) => _ConversationNotifier()),
      mentionCacheProvider.overrideWithValue(cache),
    ],
  );
  controller.addListener(() => values.add(controller.value));
  addTearDown(() async {
    controller.dispose();
    focusNode.dispose();
    container.dispose();
    auth.dispose();
    cache.dispose();
    await values.close();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: BrightnessData(
        value: 0,
        brightnessThemeData: lightBrightnessThemeData,
        child: MaterialApp(
          home: Scaffold(
            body: Portal(
              child: FocusableActionDetector(
                autofocus: true,
                child: Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) => Align(
                      alignment: Alignment.bottomCenter,
                      child: MentionPanelPortalEntry(
                        constraints: const BoxConstraints(maxWidth: 400),
                        textEditingController: controller,
                        mentionProviderInstance: mentions,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Consumer(
                                    builder: (context, ref, child) =>
                                        FocusableActionDetector(
                                          autofocus: true,
                                          shortcuts: {
                                            // The real chat field always has Escape/post shortcuts.
                                            const SingleActivator(
                                              LogicalKeyboardKey.escape,
                                            ): const ActivateIntent(),
                                            if (ref
                                                .watch(mentions)
                                                .users
                                                .isEmpty)
                                              const SingleActivator(
                                                LogicalKeyboardKey.enter,
                                              ): const ActivateIntent(),
                                          },
                                          actions: {
                                            ActivateIntent:
                                                CallbackAction<ActivateIntent>(
                                                  onInvoke: (_) => null,
                                                ),
                                          },
                                          child: Stack(
                                            children: [
                                              TextField(
                                                focusNode: focusNode,
                                                controller: controller,
                                                maxLines: 7,
                                              ),
                                            ],
                                          ),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return (
    controller: controller,
    focusNode: focusNode,
    container: container,
    mentions: mentions,
    cache: cache,
  );
}

void main() {
  testWidgets('typing after @ keeps the macOS input connection and filters', (
    tester,
  ) async {
    final field = await _pumpMentionField(tester, TargetPlatform.macOS);
    await tester.showKeyboard(find.byType(TextField));
    tester.testTextInput.log.clear();

    for (final text in ['@', '@a', '@al', '@ali', '@al', '@', '@z', '@', '']) {
      // Send platform edits without showKeyboard/enterText refocusing the field.
      expect(field.focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.hasAnyClients, isTrue);
      tester.testTextInput.enterText(text);
      await tester.pumpAndSettle();
      expect(field.controller.text, text);
      expect(
        tester.widget<PortalTarget>(find.byType(PortalTarget).first).visible,
        text.isNotEmpty && text != '@z',
      );
      expect(field.focusNode.hasFocus, isTrue, reason: 'After typing $text');
      expect(tester.testTextInput.hasAnyClients, isTrue);
      expect(
        tester.testTextInput.log.where(
          (call) =>
              call.method == 'TextInput.clearClient' ||
              call.method == 'TextInput.setClient',
        ),
        isEmpty,
        reason: 'The native input connection must survive typing $text',
      );
      expect(
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a'),
        isFalse,
        reason: 'Letters must reach the native text input',
      );
      expect(
        field.container.read(field.mentions).users,
        switch (text) {
          '@' => _users,
          '@a' => [_users[0], _users[2]],
          '@al' || '@ali' => [_users[0]],
          _ => isEmpty,
        },
      );
    }
  });

  for (final platform in [TargetPlatform.macOS, TargetPlatform.windows]) {
    final mode = platform.name;

    Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    testWidgets('mention arrows navigate and clamp at both ends ($mode)', (
      tester,
    ) async {
      final field = await _pumpMentionField(tester, platform);
      await tester.enterText(find.byType(TextField), 'hello\n@');
      await tester.pumpAndSettle();
      expect(field.container.read(field.mentions).users, _users);
      expect(field.container.read(field.mentions).index, 0);
      expect(field.focusNode.hasFocus, isTrue);
      final selection = field.controller.selection;

      for (final index in [1, 2, 2]) {
        await press(tester, LogicalKeyboardKey.arrowDown);
        expect(field.container.read(field.mentions).index, index);
        expect(field.controller.selection, selection);
      }
      for (final index in [1, 0, 0]) {
        await press(tester, LogicalKeyboardKey.arrowUp);
        expect(field.container.read(field.mentions).index, index);
        expect(field.controller.selection, selection);
      }
      expect(field.focusNode.hasFocus, isTrue);
    });

    testWidgets('typing and backspace still work after navigation ($mode)', (
      tester,
    ) async {
      final field = await _pumpMentionField(tester, platform);
      await tester.enterText(find.byType(TextField), '@');
      await tester.pumpAndSettle();
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(field.container.read(field.mentions).index, 1);

      tester.testTextInput.enterText('@ali');
      await tester.pumpAndSettle();
      expect(field.container.read(field.mentions).users, [_users[0]]);
      for (final text in ['@al', '@a', '@', '']) {
        await press(tester, LogicalKeyboardKey.backspace);
        expect(field.controller.text, text);
        expect(field.focusNode.hasPrimaryFocus, isTrue);
        expect(tester.testTextInput.hasAnyClients, isTrue);
      }
      expect(field.container.read(field.mentions).users, isEmpty);
    });

    for (final (key, text, offset) in [
      (LogicalKeyboardKey.arrowUp, 'hello\n@', 7),
      (LogicalKeyboardKey.arrowDown, '@\nworld', 1),
    ]) {
      testWidgets('Shift+$key still extends the text selection ($mode)', (
        tester,
      ) async {
        final field = await _pumpMentionField(tester, platform);
        await tester.enterText(find.byType(TextField), text);
        field.controller.selection = TextSelection.collapsed(offset: offset);
        await tester.pumpAndSettle();
        expect(field.container.read(field.mentions).users, _users);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await press(tester, key);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        expect(field.controller.selection.isCollapsed, isFalse);
        expect(field.controller.selection.baseOffset, offset);
        expect(
          field.controller.selection.extentOffset,
          key == LogicalKeyboardKey.arrowUp
              ? lessThan(offset)
              : greaterThan(offset),
        );
        expect(field.container.read(field.mentions).index, 0);
      });
    }

    testWidgets('closed mention panel leaves caret navigation intact ($mode)', (
      tester,
    ) async {
      final field = await _pumpMentionField(tester, platform);
      await tester.enterText(find.byType(TextField), 'hello\nworld');
      await tester.pumpAndSettle();
      expect(field.container.read(field.mentions).users, isEmpty);

      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(field.controller.selection.extentOffset, lessThan(6));
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(field.controller.selection.extentOffset, greaterThanOrEqualTo(6));
    });

    testWidgets('IME composition does not navigate mentions ($mode)', (
      tester,
    ) async {
      final field = await _pumpMentionField(tester, platform);
      await tester.enterText(find.byType(TextField), 'hello\n@');
      await tester.pumpAndSettle();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'hello\n@a',
          selection: TextSelection.collapsed(offset: 8),
          composing: TextRange(start: 7, end: 8),
        ),
      );
      await tester.pumpAndSettle();
      expect(field.container.read(field.mentions).users, [
        _users[0],
        _users[2],
      ]);

      expect(field.focusNode.hasPrimaryFocus, isTrue);
      expect(tester.testTextInput.hasAnyClients, isTrue);

      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(field.container.read(field.mentions).index, 0);
      expect(field.controller.text, 'hello\n@a');

      tester.testTextInput.enterText('hello\n@ali');
      await tester.pumpAndSettle();
      expect(field.controller.text, 'hello\n@ali');
      expect(field.container.read(field.mentions).users, [_users[0]]);
      expect(field.focusNode.hasPrimaryFocus, isTrue);
      expect(tester.testTextInput.hasAnyClients, isTrue);
    });

    for (final selectionKey in [
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.tab,
    ]) {
      testWidgets('selects the navigated mention with $selectionKey ($mode)', (
        tester,
      ) async {
        final field = await _pumpMentionField(tester, platform);
        await tester.enterText(find.byType(TextField), 'hello\n@');
        await tester.pumpAndSettle();
        await press(tester, LogicalKeyboardKey.arrowDown);

        // Selection uses the existing key shortcuts on both platforms.
        await tester.sendKeyEvent(selectionKey);
        await tester.pumpAndSettle();
        expect(field.controller.text, 'hello\n@7002 ');
        expect(
          field.controller.selection,
          const TextSelection.collapsed(offset: 12),
        );
        expect(field.cache.identityNumberCache('7002')?.fullName, 'Bob');
        expect(field.container.read(field.mentions).users, isEmpty);
        expect(field.focusNode.hasFocus, isTrue);
      });
    }
  }

  Future<void> pressControl(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
  }

  testWidgets('Ctrl+N and Ctrl+P navigate mentions on macOS', (tester) async {
    final field = await _pumpMentionField(tester, TargetPlatform.macOS);
    await tester.enterText(find.byType(TextField), 'hello\n@');
    await tester.pumpAndSettle();
    final selection = field.controller.selection;

    for (final (key, index) in [
      (LogicalKeyboardKey.keyN, 1),
      (LogicalKeyboardKey.keyN, 2),
      (LogicalKeyboardKey.keyP, 1),
    ]) {
      await pressControl(tester, key);
      expect(field.container.read(field.mentions).index, index);
      expect(field.controller.selection, selection);
    }
  });

  testWidgets('Ctrl+P moves the caret when the mention panel is closed', (
    tester,
  ) async {
    final field = await _pumpMentionField(tester, TargetPlatform.macOS);
    await tester.enterText(find.byType(TextField), 'hello\nworld');
    await tester.pumpAndSettle();

    await pressControl(tester, LogicalKeyboardKey.keyP);
    expect(field.controller.selection.extentOffset, lessThan(6));
  });
}
