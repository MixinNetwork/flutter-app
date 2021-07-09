import 'dart:io';

import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';

import '../utils/logger.dart';

class CustomVmDatabaseWrapper extends QueryExecutor {
  CustomVmDatabaseWrapper(File file,
      {this.logStatements = false, DatabaseSetup? setup}) {
    vmDatabase = VmDatabase(file, logStatements: false, setup: setup);
  }

  final bool logStatements;

  late final VmDatabase vmDatabase;

  @override
  TransactionExecutor beginTransaction() => vmDatabase.beginTransaction();

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) =>
      vmDatabase.ensureOpen(user);

  @override
  Future<void> runBatched(BatchedStatements statements) =>
      vmDatabase.runBatched(statements);

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) => logWrapper(
        () => vmDatabase.runCustom(statement, args),
        statement,
        args,
        logStatements,
      );

  @override
  Future<int> runDelete(String statement, List<Object?> args) =>
      vmDatabase.runDelete(statement, args);

  @override
  Future<int> runInsert(String statement, List<Object?> args) =>
      vmDatabase.runInsert(statement, args);

  @override
  Future<List<Map<String, Object?>>> runSelect(
          String statement, List<Object?> args) =>
      logWrapper(
        () => vmDatabase.runSelect(statement, args),
        statement,
        args,
        logStatements,
      );

  @override
  Future<int> runUpdate(String statement, List<Object?> args) =>
      vmDatabase.runUpdate(statement, args);

  @override
  Future<void> close() => vmDatabase.close();

  Future<T> logWrapper<T>(Future<T> Function() run, String statement,
      List<Object?>? args, bool logStatements) async {
    Stopwatch? stopwatch;
    if (logStatements) {
      stopwatch = Stopwatch()..start();
    }

    final result = await run();
    stopwatch?.stop();

    if (stopwatch != null && stopwatch.elapsed.inMilliseconds > 5) {
      final list = await vmDatabase.runSelect(
          'EXPLAIN QUERY PLAN $statement', args ?? []);

      final details = list.map((e) => e['detail']).whereType<String>();

      final needPrint = details
          .where((String detail) =>
              detail.startsWith('SCAN') || detail.startsWith('USE TEMP B-TREE'))
          .isNotEmpty;
      if (needPrint) {
        w('''execution time: ${stopwatch.elapsed.inMilliseconds} MS, args: $args, sql:
$statement
EXPLAIN QUERY PLAN RESULT: 
${details.join('\n')}
''');
      }
    }

    return result;
  }
}
