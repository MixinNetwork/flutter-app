import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../logger.dart';

/// Whether an assistive technology talks to apps through AT-SPI.
///
/// The Linux embedder always enables Flutter semantics, and a scrolled list
/// rebuilds its semantics on every frame. Other platforms build semantics only
/// while assistive technology is on, so Linux follows the AT-SPI status.
final linuxAccessibilityEnabled = ValueNotifier<bool>(false);

Future<void> watchLinuxAccessibility() async {
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

  try {
    bus.propertiesChanged
        .where((signal) => signal.propertiesInterface == 'org.a11y.Status')
        .listen((_) => unawaited(refresh().catchError((_) {})));
    await refresh();
  } catch (error) {
    // Without the AT-SPI bus no assistive technology can reach the app.
    i('linux accessibility status unavailable: $error');
  }
  i('linux accessibility enabled: ${linuxAccessibilityEnabled.value}');
}

/// Builds [child] without semantics on Linux while no assistive technology is
/// on.
class LinuxSemanticsGate extends StatelessWidget {
  const LinuxSemanticsGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.linux) return child;
    return ValueListenableBuilder<bool>(
      valueListenable: linuxAccessibilityEnabled,
      builder: (context, enabled, child) =>
          ExcludeSemantics(excluding: !enabled, child: child),
      child: child,
    );
  }
}
