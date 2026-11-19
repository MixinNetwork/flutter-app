import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/blaze/blaze_message.dart';
import 'package:flutter_app/blaze/blaze_message_param.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/utils/attachment/attachment_util.dart';
import 'package:flutter_app/utils/device_transfer/device_transfer_receiver.dart';
import 'package:flutter_app/utils/device_transfer/device_transfer_sender.dart';
import 'package:flutter_app/utils/device_transfer/device_transfer_widget.dart';
import 'package:flutter_app/utils/device_transfer/transfer_data_command.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_app/utils/file.dart';
import 'package:flutter_app/workers/device_transfer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

void main() {
  setUpAll(() {
    mixinDocumentsDirectory = Directory(
      p.join(Directory.systemTemp.path, 'test'),
    );
    EventBus.initialize();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late Database database;
  late DeviceTransfer transfer;
  late List<BlazeMessage> delivered;
  late int closedPort;
  late Completer<void> serverCreated;
  late Completer<void> senderFailed;

  setUp(() async {
    database = Database(
      MixinDatabase(NativeDatabase.memory()),
      FtsDatabase(NativeDatabase.memory()),
    );
    final userId = const Uuid().v4();
    final deviceId = const Uuid().v4();
    delivered = [];
    serverCreated = Completer();
    senderFailed = Completer();
    transfer = DeviceTransfer(
      database: database,
      userId: userId,
      messageDeliver: delivered.add,
      primarySessionId: const Uuid().v4(),
      deviceId: deviceId,
      sender: DeviceTransferSender(
        database: database,
        attachmentUtil: AttachmentUtilBase.of('10000'),
        protocolTempFileDir: '',
        deviceId: deviceId,
        onSenderServerCreated: serverCreated.complete,
        onSenderFailed: senderFailed.complete,
      ),
      receiver: DeviceTransferReceiver(
        database: database,
        userId: userId,
        attachmentUtil: AttachmentUtilBase.of('10000'),
        protocolTempFileDir: p.join(mixinDocumentsDirectory.path, 'receive'),
        deviceId: deviceId,
      ),
    );
    // A port that nothing listens on, so the connection is refused.
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    closedPort = server.port;
    await server.close();
  });

  tearDown(() async {
    transfer.dispose();
    await database.dispose();
  });

  TransferDataCommand pushCommand() => TransferDataCommand.push(
    ip: InternetAddress.loopbackIPv4.address,
    port: closedPort,
    deviceId: const Uuid().v4(),
    code: 1234,
    secretKey: base64Encode(List.filled(64, 1)),
  );

  Future<void> expectFailureAndCancel(void Function() connect) async {
    final failed = DeviceTransferEventBus.instance
        .on(DeviceTransferCallbackType.onConnectionFailed)
        .first
        .timeout(const Duration(seconds: 10));
    connect();
    expect((await failed).payload, ConnectionFailedReason.unknown);

    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (_cancelCount(delivered) == 0 && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(
      _cancelCount(delivered),
      1,
      reason:
          'The other device waits for the connection until it gets a cancel',
    );
  }

  test(
    'Agree to a refused push shows a failure and cancels the push',
    () async {
      transfer.handleRemoteCommand(pushCommand());
      await expectFailureAndCancel(
        () => EventBus.instance.fire(DeviceTransferCommand.confirmRestore),
      );
    },
  );

  test('A refused push after our pull shows a failure and cancels', () async {
    EventBus.instance.fire(DeviceTransferCommand.pullToRemote);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    delivered.clear();
    await expectFailureAndCancel(
      () => transfer.handleRemoteCommand(pushCommand()),
    );
  });

  test('A cancel from the other device closes our waiting server', () async {
    EventBus.instance.fire(DeviceTransferCommand.pushToRemote);
    await serverCreated.future.timeout(const Duration(seconds: 10));

    transfer.handleRemoteCommand(
      TransferDataCommand.cancel(deviceId: const Uuid().v4()),
    );
    await senderFailed.future.timeout(const Duration(seconds: 10));
  });
}

int _cancelCount(List<BlazeMessage> messages) => messages.where((message) {
  final data = (message.params! as BlazeMessageParam).data!;
  final plain =
      jsonDecode(utf8.decode(base64Decode(data))) as Map<String, dynamic>;
  final command =
      jsonDecode(plain['content'] as String) as Map<String, dynamic>;
  return command['action'] == kTransferCommandActionCancel;
}).length;
