import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../utils/file.dart';
import '../custom_vm_database_wrapper.dart';

QueryExecutor _openDatabase(File dbFile) => CustomVmDatabaseWrapper(
      NativeDatabase(
        dbFile,
        setup: (rawDb) {
          rawDb
            ..execute('PRAGMA journal_mode=WAL;')
            ..execute('PRAGMA foreign_keys=ON;')
            ..execute('PRAGMA synchronous=NORMAL;');
        },
      ),
      logStatements: true,
      explain: kDebugMode,
    );

/// Connect to the database.
Future<QueryExecutor> openQueryExecutor({
  required String identityNumber,
  required String dbName,
  required bool fromMainIsolate,
  int readCount = 8,
}) async {
  final backgroundPortName =
      'one_mixin_drift_background_${identityNumber}_$dbName';
  final foregroundPortName =
      'one_mixin_drift_foreground_${identityNumber}_$dbName';

  final writeIsolate = await _crateIsolate(
    identityNumber: identityNumber,
    portName: backgroundPortName,
    dbName: dbName,
    fromMainIsolate: fromMainIsolate,
  );

  final write = await writeIsolate.connect();

  final reads = await Future.wait(List.generate(readCount, (i) async {
    final isolate = await _crateIsolate(
      identityNumber: identityNumber,
      portName: '${foregroundPortName}_$i',
      dbName: dbName,
      fromMainIsolate: fromMainIsolate,
    );
    return isolate.connect();
  }));

  return MultiExecutor.withReadPool(
    reads: reads.map((e) => e.executor).toList(),
    write: write.executor,
  );
}

Future<DriftIsolate> _crateIsolate({
  required String identityNumber,
  required String portName,
  required String dbName,
  bool fromMainIsolate = false,
}) async {
  if (fromMainIsolate) {
    // Remove port if it exists. to avoid port leak on hot reload.
    IsolateNameServer.removePortNameMapping(portName);
  }

  final existingIsolate = IsolateNameServer.lookupPortByName(portName);

  if (existingIsolate == null) {
    assert(fromMainIsolate, 'Isolate should be created from main isolate');
    final dbFile = File(
        p.join(mixinDocumentsDirectory.path, identityNumber, '$dbName.db'));
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _startBackground,
      _IsolateStartRequest(receivePort.sendPort, dbFile),
    );
    final isolate = await receivePort.first as DriftIsolate;
    IsolateNameServer.registerPortWithName(isolate.connectPort, portName);
    return isolate;
  } else {
    return DriftIsolate.fromConnectPort(existingIsolate, serialize: false);
  }
}

void _startBackground(_IsolateStartRequest request) {
  final executor = _openDatabase(request.dbFile);
  final isolate = DriftIsolate.inCurrent(
    () => DatabaseConnection(executor),
  );
  request.sendMoorIsolate.send(isolate);
}

class _IsolateStartRequest {
  _IsolateStartRequest(this.sendMoorIsolate, this.dbFile);

  final SendPort sendMoorIsolate;
  final File dbFile;
}
