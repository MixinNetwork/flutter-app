import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:ansicolor/ansicolor.dart';
import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../../utils/file.dart';
import '../custom_sqlite3_database.dart';

QueryExecutor _openDatabase(File file) {
  // Create the parent directory if it doesn't exist. sqlite will emit
  // confusing misuse warnings otherwise
  final dir = file.parent;
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  final db = sqlite3.open(file.path);
  return NativeDatabase.opened(
    DatabaseProfiler(db, explain: kDebugMode),
    setup: (rawDb) {
      rawDb
        ..execute('PRAGMA journal_mode=WAL;')
        ..execute('PRAGMA foreign_keys=ON;')
        ..execute('PRAGMA synchronous=NORMAL;');
    },
  );
}

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
    debugName: 'isolate_drift_${dbName}_write',
  );

  final write = await writeIsolate.connect();

  final reads = await Future.wait(List.generate(readCount, (i) async {
    final isolate = await _crateIsolate(
      identityNumber: identityNumber,
      portName: '${foregroundPortName}_$i',
      dbName: dbName,
      fromMainIsolate: fromMainIsolate,
      debugName: 'one_mixin_drift_read_$i',
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
  required String? debugName,
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
      debugName: debugName,
    );
    final isolate = await receivePort.first as DriftIsolate;
    IsolateNameServer.registerPortWithName(isolate.connectPort, portName);
    return isolate;
  } else {
    return DriftIsolate.fromConnectPort(existingIsolate, serialize: false);
  }
}

void _startBackground(_IsolateStartRequest request) {
  ansiColorDisabled = Platform.isIOS;
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
