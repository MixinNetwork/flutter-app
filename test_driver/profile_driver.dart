import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver.dart';
import 'package:vm_service/vm_service.dart';

// Like perf_driver.dart, and also writes the hottest functions of the UI
// isolate to build/cpu_profile.txt.
Future<void> main() async {
  final driver = await FlutterDriver.connect();
  final service = driver.serviceClient;
  final isolateId = (await service.getVM()).isolates!.first.id!;
  await service.clearCpuSamples(isolateId);

  await integrationDriver(
    responseDataCallback: (data) async {
      final samples = await service.getCpuSamples(isolateId, 0, ~0 >>> 1);
      final functions = samples.functions!;
      final self = <int, int>{};
      final inclusive = <int, int>{};
      for (final sample in samples.samples!) {
        final stack = sample.stack ?? const <int>[];
        if (stack.isEmpty) continue;
        self[stack.first] = (self[stack.first] ?? 0) + 1;
        for (final index in stack.toSet()) {
          inclusive[index] = (inclusive[index] ?? 0) + 1;
        }
      }
      String name(int index) {
        final function = functions[index].function;
        if (function is FuncRef) {
          final owner = function.owner;
          final ownerName = owner is ClassRef ? '${owner.name}.' : '';
          final location = function.location?.script?.uri ?? '';
          return '$ownerName${function.name}  $location';
        }
        return '${function is NativeFunction ? function.name : function}';
      }

      String top(Map<int, int> counts, int limit) {
        final entries = counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return entries
            .take(limit)
            .map((e) => '${e.value.toString().padLeft(7)}  ${name(e.key)}')
            .join('\n');
      }

      final total = samples.samples!.length;
      File('build/cpu_profile.txt').writeAsStringSync(
        'samples: $total, period: ${samples.samplePeriod} us\n\n'
        '== self ==\n${top(self, 60)}\n\n'
        '== inclusive (app code) ==\n'
        '${top(Map.fromEntries(inclusive.entries.where((e) => name(e.key).contains('package:flutter_app'))), 60)}\n',
      );
      await driver.close();
      await writeResponseData(data);
    },
  );
}
