// A test-only app entry for .github/workflows/update-windows-store-test.yml.
// Build the MSIX with `-t integration_test/store_update_main.dart`, install
// and start it. It writes the result of storeUpdateCount to
// %USERPROFILE%\store_update_result.txt and exits. AppData is not used, as
// the package redirects its writes there.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_app/ui/provider/app_update_provider.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String result;
  try {
    final count = await storeUpdateChannel.invokeMethod<int>(
      'storeUpdateCount',
    );
    result = 'count $count';
  } on Exception catch (error) {
    result = 'error $error';
  }
  await File(
    p.join(Platform.environment['USERPROFILE']!, 'store_update_result.txt'),
  ).writeAsString(result);
  exit(0);
}
