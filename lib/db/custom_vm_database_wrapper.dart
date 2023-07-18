import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';

import '../utils/event_bus.dart';
import '../utils/extension/extension.dart';
import '../utils/logger.dart';

class CustomVmDatabaseWrapper extends QueryExecutor {
  CustomVmDatabaseWrapper(
    this.queryExecutor, {
    this.logStatements = false,
    required this.explain,
  });

  final bool logStatements;
  final bool explain;

  late final NativeDatabase queryExecutor;

  T _handleSqliteException<T>(ValueGetter<T> callback) {
    try {
      return callback();
    } on SqliteException catch (e) {
      if (e.extendedResultCode != 267) rethrow;
      if (![e.message, e.explanation].whereNotNull().any(
          (element) => element.contains('database disk image is malformed'))) {
        rethrow;
      }
      EventBus.instance.fire(e);
      rethrow;
    }
  }

  Future<T> _handleSqliteExceptionByFuture<T>(
      ValueGetter<Future<T>> callback) async {
    try {
      return await callback();
    } on SqliteException catch (e) {
      if (e.extendedResultCode != 267) rethrow;
      if (![e.message, e.explanation].whereNotNull().any(
          (element) => element.contains('database disk image is malformed'))) {
        rethrow;
      }
      EventBus.instance.fire(e);
      rethrow;
    }
  }

  @override
  TransactionExecutor beginTransaction() =>
      _handleSqliteException(queryExecutor.beginTransaction);

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) =>
      _handleSqliteExceptionByFuture(() => queryExecutor.ensureOpen(user));

  @override
  Future<void> runBatched(BatchedStatements statements) =>
      _handleSqliteExceptionByFuture(
          () => queryExecutor.runBatched(statements));

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) => logWrapper(
        () => queryExecutor.runCustom(statement, args),
        statement,
        args,
        logStatements,
      );

  @override
  Future<int> runDelete(String statement, List<Object?> args) => logWrapper(
        () => queryExecutor.runDelete(statement, args),
        statement,
        args,
        logStatements,
      );

  @override
  Future<int> runInsert(String statement, List<Object?> args) => logWrapper(
        () => queryExecutor.runInsert(statement, args),
        statement,
        args,
        logStatements,
      );

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
  Future<int> runUpdate(String statement, List<Object?> args) => logWrapper(
        () => queryExecutor.runUpdate(statement, args),
        statement,
        args,
        logStatements,
      );

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
      result = await _handleSqliteExceptionByFuture(run);
    } catch (error, s) {
      e('queryExecutor Error: $error\n$s\nstatement: $statement, args: $args');
      rethrow;
    }
    stopwatch?.stop();

    if (stopwatch != null && stopwatch.elapsed.inMilliseconds > 25) {
      Iterable<String>? details;
      var needPrint = false;

      if (explain) {
        final list = await queryExecutor.runSelect(
            'EXPLAIN QUERY PLAN $statement', args ?? []);

        details = list.map((e) => e['detail']).whereType<String>();

        needPrint = details
            .where((String detail) =>
                detail.startsWith('SCAN') ||
                detail.startsWith('USE TEMP B-TREE'))
            .isNotEmpty;
      }

      w('''
execution time: ${stopwatch.elapsed.inMilliseconds} MS, args: $args, sql:
$statement
''');
      if (needPrint && details != null) {
        w('EXPLAIN QUERY PLAN: \n${details.join('\n')}');
      }
    }

    return result;
  }

  @override
  SqlDialect get dialect => queryExecutor.dialect;
}
