import 'dart:ffi';
import 'dart:isolate';

import 'package:mixin_logger/mixin_logger.dart';
import 'package:sqlite3/sqlite3.dart';

class DatabaseProfiler extends Database {
  DatabaseProfiler(
    this.database, {
    this.logStatements = true,
    this.explain = false,
  });

  final Database database;
  final bool logStatements;
  final bool explain;

  @override
  set userVersion(int value) => database.userVersion = value;

  @override
  int get userVersion => database.userVersion;

  @override
  Stream<double> backup(Database toDatabase, {int nPage = 5}) =>
      database.backup(toDatabase, nPage: nPage);

  @override
  void createAggregateFunction<V>({
    required String functionName,
    required AggregateFunction<V> function,
    AllowedArgumentCount argumentCount = const AllowedArgumentCount.any(),
    bool deterministic = false,
    bool directOnly = true,
  }) {
    database.createAggregateFunction(
      functionName: functionName,
      function: function,
      argumentCount: argumentCount,
      deterministic: deterministic,
      directOnly: directOnly,
    );
  }

  @override
  void createCollation({
    required String name,
    required CollatingFunction function,
  }) {
    database.createCollation(name: name, function: function);
  }

  @override
  void createFunction({
    required String functionName,
    required ScalarFunction function,
    AllowedArgumentCount argumentCount = const AllowedArgumentCount.any(),
    bool deterministic = false,
    bool directOnly = true,
  }) {
    database.createFunction(
      functionName: functionName,
      function: function,
      argumentCount: argumentCount,
      deterministic: deterministic,
      directOnly: directOnly,
    );
  }

  @override
  void dispose() => database.dispose();

  @override
  void execute(String sql, [List<Object?> parameters = const []]) =>
      logWrapper(() => database.execute(sql, parameters), sql, parameters);

  @override
  // ignore: deprecated_member_use
  int getUpdatedRows() => database.getUpdatedRows();

  @override
  Pointer<void> get handle => database.handle;

  @override
  int get lastInsertRowId => database.lastInsertRowId;

  @override
  PreparedStatement prepare(
    String sql, {
    bool persistent = false,
    bool vtab = true,
    bool checkNoTail = false,
  }) =>
      _PreparedStatementWrapper(
        database.prepare(
          sql,
          persistent: persistent,
          vtab: vtab,
          checkNoTail: checkNoTail,
        ),
        logWrapper,
      );

  @override
  List<PreparedStatement> prepareMultiple(
    String sql, {
    bool persistent = false,
    bool vtab = true,
  }) =>
      database.prepareMultiple(sql, persistent: persistent, vtab: vtab);

  @override
  ResultSet select(String sql, [List<Object?> parameters = const []]) =>
      logWrapper(() => database.select(sql, parameters), sql, parameters);

  @override
  Stream<SqliteUpdate> get updates => database.updates;

  T logWrapper<T>(T Function() run, String sql, List<Object?>? parameters) {
    Stopwatch? stopwatch;
    if (logStatements) {
      stopwatch = Stopwatch()..start();
    }

    T result;
    try {
      result = run();
    } catch (error, s) {
      e('queryExecutor Error: $error\n$s\nsql: $sql, parameters: $parameters');
      rethrow;
    }
    stopwatch?.stop();

    if (stopwatch != null && stopwatch.elapsed.inMilliseconds > 25) {
      Iterable<String>? details;
      var needPrint = false;

      if (explain) {
        final list =
            database.select('EXPLAIN QUERY PLAN $sql', parameters ?? []);

        details = list.map((e) => e['detail']).whereType<String>();

        needPrint = details
            .where((String detail) =>
                detail.startsWith('SCAN') ||
                detail.startsWith('USE TEMP B-TREE'))
            .isNotEmpty;
      }

      w('''
sql execution time: ${stopwatch.elapsed.inMilliseconds} MS, Isolate_${Isolate.current.hashCode}(${Isolate.current.debugName})
sql: $sql
parameter: $parameters
''');
      if (needPrint && details != null) {
        w('EXPLAIN QUERY PLAN: \n${details.join('\n')}');
      }
    }

    return result;
  }

  @override
  DatabaseConfig get config => database.config;

  @override
  int get updatedRows => database.updatedRows;

  @override
  bool get autocommit => database.autocommit;
}

class _PreparedStatementWrapper implements PreparedStatement {
  _PreparedStatementWrapper(this.stmt, this.logWrapper);

  final PreparedStatement stmt;
  final T Function<T>(T Function() run, String sql, List<Object?>? parameters)
      logWrapper;

  @override
  void dispose() => stmt.dispose();

  @override
  void execute([List<Object?> parameters = const <Object>[]]) =>
      logWrapper(() => stmt.execute(parameters), sql, parameters);

  @override
  void executeWith(StatementParameters parameters) {
    logWrapper(() => stmt.executeWith(parameters), sql, null);
  }

  @override
  Pointer<void> get handle => stmt.handle;

  @override
  IteratingCursor iterateWith(StatementParameters parameters) =>
      stmt.iterateWith(parameters);

  @override
  int get parameterCount => stmt.parameterCount;

  @override
  void reset() {
    stmt.reset();
  }

  @override
  ResultSet select([List<Object?> parameters = const <Object>[]]) =>
      logWrapper(() => stmt.select(parameters), sql, parameters);

  @override
  IteratingCursor selectCursor([List<Object?> parameters = const <Object>[]]) =>
      stmt.selectCursor(parameters);

  @override
  ResultSet selectWith(StatementParameters parameters) =>
      logWrapper(() => stmt.selectWith(parameters), sql, null);

  @override
  String get sql => stmt.sql;

  @override
  void executeMap(Map<String, Object?> parameters) {
    executeWith(StatementParameters.named(parameters));
  }

  @override
  ResultSet selectMap(Map<String, Object?> parameters) =>
      selectWith(StatementParameters.named(parameters));
}
