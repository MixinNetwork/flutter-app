import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../utils/logger.dart';

class CustomVmDatabaseWrapper extends QueryExecutor {
  CustomVmDatabaseWrapper(this.queryExecutor, {this.logStatements = false});

  final bool logStatements;

  late final NativeDatabase queryExecutor;

  @override
  TransactionExecutor beginTransaction() => queryExecutor.beginTransaction();

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) =>
      queryExecutor.ensureOpen(user);

  @override
  Future<void> runBatched(BatchedStatements statements) =>
      queryExecutor.runBatched(statements);

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) => logWrapper(
        () => queryExecutor.runCustom(statement, args),
        statement,
        args,
        logStatements,
      );

  @override
  Future<int> runDelete(String statement, List<Object?> args) =>
      queryExecutor.runDelete(statement, args);

  @override
  Future<int> runInsert(String statement, List<Object?> args) =>
      queryExecutor.runInsert(statement, args);

  @override
  Future<List<Map<String, Object?>>> runSelect(
          String statement, List<Object?> args) =>
      logWrapper(
        () => queryExecutor.runSelect(statement, args),
        statement,
        args,
        logStatements,
      );

  @override
  Future<int> runUpdate(String statement, List<Object?> args) =>
      queryExecutor.runUpdate(statement, args);

  @override
  Future<void> close() => queryExecutor.close();

  Future<T> logWrapper<T>(Future<T> Function() run, String statement,
      List<Object?>? args, bool logStatements) async {
    Stopwatch? stopwatch;
    if (logStatements) {
      stopwatch = Stopwatch()..start();
    }

    T result;
    try {
      result = await run();
    } catch (error, s) {
      e('queryExecutor Error: $error\n$s\nstatement: $statement, args: $args');
      rethrow;
    }
    stopwatch?.stop();

    if (stopwatch != null && stopwatch.elapsed.inMilliseconds > 5) {
      final list = await queryExecutor.runSelect(
          'EXPLAIN QUERY PLAN $statement', args ?? []);

      final details = list.map((e) => e['detail']).whereType<String>();

      final needPrint = details
          .where((String detail) =>
              detail.startsWith('SCAN') || detail.startsWith('USE TEMP B-TREE'))
          .isNotEmpty;
      if (needPrint) {
        w('''
execution time: ${stopwatch.elapsed.inMilliseconds} MS, args: $args, sql:
$statement
EXPLAIN QUERY PLAN RESULT: 
${details.join('\n')}
''');
      }
    }

    return result;
  }
}
