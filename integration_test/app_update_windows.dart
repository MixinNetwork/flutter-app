import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_app/ui/provider/app_update_provider.dart';
import 'package:flutter_app/ui/provider/database_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rhttp/rhttp.dart';

// The old app of .github/workflows/update-windows-test.yml: it installs the
// first update it finds, as a click on the sidebar item would. Not shipped.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The update client gets the network through rhttp, as in lib/main.dart.
  await Rhttp.init();
  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWith((ref) => DatabaseOpener())],
  );
  container.listen(appUpdateProvider, (_, state) {
    switch (state.status) {
      case AppUpdateStatus.available:
        container.read(appUpdateProvider.notifier).update();
      case AppUpdateStatus.failed:
        exit(1);
      case AppUpdateStatus.none || AppUpdateStatus.downloading:
    }
  });
  runApp(const SizedBox());
}
