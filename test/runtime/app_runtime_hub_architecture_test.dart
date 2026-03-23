import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'AppRuntimeHub waits for database instead of failing immediately',
    () async {
      final file = File(
        '/Users/yeungkc/coding/work/mixin/flutter-app/lib/runtime/app_runtime_hub.dart',
      );
      final content = await file.readAsString();

      expect(content, contains("if (args.database == null)"));
      expect(content, contains("[RuntimeHub] database not ready yet, waiting"));
    },
  );
}
