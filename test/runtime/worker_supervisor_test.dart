import 'dart:async';
import 'dart:isolate';

import 'package:flutter_app/runtime/isolate/router.dart';
import 'package:flutter_app/runtime/isolate/worker_supervisor.dart';
import 'package:flutter_app/runtime/isolate/protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/isolate_channel.dart';

class _ReadyWorkerInitParams {
  _ReadyWorkerInitParams({
    required this.sendPort,
    required this.readyDelay,
  });

  final SendPort sendPort;
  final Duration readyDelay;
}

Future<void> _readyWorkerMain(_ReadyWorkerInitParams params) async {
  final isolateChannel = IsolateChannel<dynamic>.connectSend(params.sendPort);
  final router = IsolateRouter.worker(
    inbound: isolateChannel.stream,
    sendMessage: isolateChannel.sink.add,
  );

  Future<void>.delayed(params.readyDelay, router.sendReady);

  await router.commands.firstWhere((command) => command is ExitWorkerCommand);
  Isolate.exit();
}

void main() {
  test('worker supervisor waits until ready control arrives', () async {
    final supervisor = WorkerSupervisor<_ReadyWorkerInitParams>(
      entryPoint: _readyWorkerMain,
      initParamsFactory: (sendPort) => _ReadyWorkerInitParams(
        sendPort: sendPort,
        readyDelay: const Duration(milliseconds: 80),
      ),
      heartbeatInterval: const Duration(seconds: 30),
      heartbeatTimeout: const Duration(seconds: 30),
    );
    addTearDown(supervisor.dispose);

    await supervisor.start();
    expect(supervisor.isRunning, isTrue);
    expect(supervisor.isReady, isFalse);

    await supervisor.waitUntilReady(timeout: const Duration(seconds: 1));
    expect(supervisor.isReady, isTrue);
  });

  test('worker supervisor send fails fast when channel is unavailable', () {
    final supervisor = WorkerSupervisor<_ReadyWorkerInitParams>(
      entryPoint: _readyWorkerMain,
      initParamsFactory: (sendPort) => _ReadyWorkerInitParams(
        sendPort: sendPort,
        readyDelay: Duration.zero,
      ),
    );
    addTearDown(supervisor.dispose);

    expect(
      () => supervisor.send(const ExitWorkerCommand()),
      throwsA(isA<StateError>()),
    );
  });
}
