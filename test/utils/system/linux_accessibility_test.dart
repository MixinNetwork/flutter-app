import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/utils/system/linux_accessibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    linuxAccessibilityEnabled.value = false;
  });

  bool hasLabel(WidgetTester tester, String label) => tester.semantics
      .simulatedAccessibilityTraversal()
      .any((node) => node.label == label);

  Widget app() => const MaterialApp(
    home: LinuxSemanticsGate(child: Text('hello')),
  );

  testWidgets('Linux builds semantics only while assistive tech is on', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await tester.pumpWidget(app());
    expect(hasLabel(tester, 'hello'), isFalse);

    linuxAccessibilityEnabled.value = true;
    await tester.pump();
    expect(hasLabel(tester, 'hello'), isTrue);

    linuxAccessibilityEnabled.value = false;
    await tester.pump();
    expect(hasLabel(tester, 'hello'), isFalse);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('other platforms keep their semantics', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await tester.pumpWidget(app());
    expect(hasLabel(tester, 'hello'), isTrue);
    debugDefaultTargetPlatformOverride = null;
  });
}
