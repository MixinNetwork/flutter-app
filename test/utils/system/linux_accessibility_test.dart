@TestOn('mac-os')
library;

import 'package:flutter_app/utils/system/linux_accessibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The macOS test host has no session bus, as a Linux session without
  // D-Bus.
  test(
    'reports no assistive technology when the session bus is missing',
    () async {
      await expectLater(watchLinuxAccessibility(), completes);
      await pumpEventQueue();
      expect(linuxAccessibilityEnabled.value, isFalse);
    },
  );
}
