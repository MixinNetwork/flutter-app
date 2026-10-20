import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:flutter/widgets.dart';

import '../logger.dart';

/// Whether an assistive technology talks to apps through AT-SPI.
final linuxAccessibilityEnabled = ValueNotifier<bool>(false);

Future<void> watchLinuxAccessibility() async {
  try {
    final bus = DBusRemoteObject(
      DBusClient.session(),
      name: 'org.a11y.Bus',
      path: DBusObjectPath('/org/a11y/bus'),
    );
    Future<void> refresh() async {
      final status = await bus.getAllProperties('org.a11y.Status');
      linuxAccessibilityEnabled.value =
          (status['IsEnabled']?.asBoolean() ?? false) ||
          (status['ScreenReaderEnabled']?.asBoolean() ?? false);
    }

    // A failed connection throws here. A signal subscription would report it
    // as an unhandled error inside the dbus package instead.
    await refresh();
    bus.propertiesChanged
        .where((signal) => signal.propertiesInterface == 'org.a11y.Status')
        .listen(
          (_) => unawaited(refresh().catchError((_) {})),
          onError: (Object error) =>
              i('linux accessibility status signal failed: $error'),
        );
    // The status can change before the subscription starts.
    await refresh();
  } catch (error) {
    // Without the AT-SPI bus no assistive technology can reach the app.
    i('linux accessibility status unavailable: $error');
  }
  i('linux accessibility enabled: ${linuxAccessibilityEnabled.value}');
}

/// The Linux binding, which builds semantics only while an assistive
/// technology is on.
///
/// The Linux embedder always enables semantics. Every render object that is
/// added then marks semantics dirty, and opening a chat or scrolling a list
/// flushed semantics for several milliseconds in a frame. Other platforms
/// build semantics only while assistive technology is on, so Linux follows the
/// AT-SPI status.
class LinuxSemanticsBinding extends WidgetsFlutterBinding {
  @override
  bool get semanticsEnabled =>
      super.semanticsEnabled && linuxAccessibilityEnabled.value;

  @override
  void addSemanticsEnabledListener(VoidCallback listener) {
    super.addSemanticsEnabledListener(listener);
    linuxAccessibilityEnabled.addListener(listener);
  }

  @override
  void removeSemanticsEnabledListener(VoidCallback listener) {
    super.removeSemanticsEnabledListener(listener);
    linuxAccessibilityEnabled.removeListener(listener);
  }
}
