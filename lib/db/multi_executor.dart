import 'dart:async';

import 'package:drift/drift.dart';

class _ExecutorCompleter {
  _ExecutorCompleter(this.statement, this.args)
      : _completer = Completer<List<Map<String, Object?>>>();

  final String statement;
  final List<Object?> args;
  final Completer<List<Map<String, Object?>>> _completer;

  Future<List<Map<String, Object?>>> get future => _completer.future;

  void complete([FutureOr<List<Map<String, Object?>>>? value]) {
    _completer.complete(value);
  }

  void completeError(Object error, [StackTrace? stackTrace]) {
    _completer.completeError(error, stackTrace);
  }
}

class _QueryExecutorPool {
  _QueryExecutorPool(this._executors) : _idleExecutors = [..._executors];

  final List<QueryExecutor> _executors;
  final List<QueryExecutor> _idleExecutors;

  final List<_ExecutorCompleter> _queue = [];
  final List<_ExecutorCompleter> _running = [];

  Future<bool> ensureOpen(QueryExecutorUser user) async {
    final result = await Future.wait(
        _executors.map((QueryExecutor executor) => executor.ensureOpen(user)));
    return result.every((element) => element);
  }

  Future<void> close() async =>
      Future.wait(_executors.map((QueryExecutor executor) => executor.close()));

  Future<List<Map<String, Object?>>> runSelect(
      String statement, List<Object?> args) {
    final executorCompleter = _ExecutorCompleter(statement, args);
    _queue.add(executorCompleter);
    _run();
    return executorCompleter.future;
  }

  void _run() {
    if (_queue.isEmpty) return;
    if (_idleExecutors.isEmpty) return;

    final executor = _idleExecutors.removeAt(0);
    final completer = _queue.removeAt(0);

    _running.add(completer);

    completer.future.whenComplete(() {
      _running.remove(completer);
      _idleExecutors.add(executor);
      _run();
    });

    executor
        .runSelect(completer.statement, completer.args)
        .then(completer.complete, onError: completer.completeError);
  }
}

class MultiReadExecutor extends QueryExecutor {
  MultiReadExecutor({
    required List<QueryExecutor> reads,
    required QueryExecutor write,
  })  : queryExecutorPool = _QueryExecutorPool(reads),
        _write = write;

  // ignore: library_private_types_in_public_api
  final _QueryExecutorPool queryExecutorPool;
  final QueryExecutor _write;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async =>
      await _write.ensureOpen(user) &&
      await queryExecutorPool.ensureOpen(_NoMigrationsWrapper(user));

  @override
  TransactionExecutor beginTransaction() => _write.beginTransaction();

  @override
  Future<void> runBatched(BatchedStatements statements) async {
    await _write.runBatched(statements);
  }

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) async {
    await _write.runCustom(statement, args);
  }

  @override
  Future<int> runDelete(String statement, List<Object?> args) async =>
      _write.runDelete(statement, args);

  @override
  Future<int> runInsert(String statement, List<Object?> args) async =>
      _write.runInsert(statement, args);

  @override
  Future<List<Map<String, Object?>>> runSelect(
          String statement, List<Object?> args) =>
      queryExecutorPool.runSelect(statement, args);

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async =>
      _write.runUpdate(statement, args);

  @override
  Future<void> close() async {
    await _write.close();
    await queryExecutorPool.close();
  }
}

class _NoMigrationsWrapper extends QueryExecutorUser {
  _NoMigrationsWrapper(this.inner);

  final QueryExecutorUser inner;

  @override
  int get schemaVersion => inner.schemaVersion;

  @override
  Future<void> beforeOpen(
      QueryExecutor executor, OpeningDetails details) async {
    // don't run any migrations
  }
}
