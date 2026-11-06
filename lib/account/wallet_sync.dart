import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../db/database.dart';
import '../db/database_event_bus.dart';
import '../utils/logger.dart';
import 'account_key_value.dart';

const _kOutputLimit = 500;
const _kSnapshotLimit = 300;

class WalletSync {
  WalletSync({
    required this.client,
    required this.database,
    required this.userId,
    required this.refreshUsers,
  });

  final Client client;
  final Database database;
  final String userId;
  final Future<void> Function(List<String> userIds) refreshUsers;

  /// Sums the unspent outputs of the user into a balance for each kernel
  /// asset.
  ///
  /// Desktop does not spend outputs, so it cannot learn which outputs another
  /// device spent. Each sync reads all unspent outputs again and replaces the
  /// stored balances.
  late final syncBalances = _Coalesced('balances', _syncBalances);

  /// Reads the snapshots that were created after the last synced snapshot.
  late final syncSnapshots = _Coalesced('snapshots', _syncSnapshots);

  Future<void> _syncBalances() async {
    final balances = <String, Decimal>{};
    int? offset;
    while (true) {
      final outputs = (await client.utxoApi.getOutputs(
        members: [userId],
        threshold: 1,
        state: OutputState.unspent.name,
        offset: offset,
        // The loop compares the page size with this limit.
        // ignore: avoid_redundant_argument_values
        limit: _kOutputLimit,
      )).data;
      sumOutputs(balances, outputs);
      if (outputs.length < _kOutputLimit) break;
      offset = outputs.last.sequence + 1;
    }

    if (balances.isNotEmpty) {
      // Also refreshes the prices of the tokens that are already stored.
      final tokens = (await client.tokenApi.fetchAssets(
        balances.keys.toList(),
      )).data;
      await database.tokenDao.insertSdkTokens(tokens);
      await _insertMissingChains(tokens.map((e) => e.chainId).toSet());
    }
    await database.tokenDao.replaceBalances(
      balances.map((key, value) => MapEntry(key, value.toString())),
    );

    final tokens = await database.tokenDao.getTokens();
    if (tokens.isNotEmpty) {
      DataBaseEventBus.instance.updateToken(tokens.map((e) => e.assetId));
    }
  }

  Future<void> _insertMissingChains(Set<String> chainIds) async {
    final chains = database.mixinDatabase.chains;
    final stored =
        await (database.mixinDatabase.selectOnly(chains)
              ..addColumns([chains.chainId])
              ..where(chains.chainId.isIn(chainIds)))
            .map((row) => row.read(chains.chainId)!)
            .get();
    if (stored.length == chainIds.length) return;
    final all = (await client.assetApi.getChains()).data;
    await Future.wait(all.map(database.chainDao.insertSdkChain));
  }

  Future<void> _syncSnapshots() async {
    final opponentIds = <String>{};
    var offset = AccountKeyValue.instance.safeSnapshotOffset;
    while (true) {
      final snapshots = (await client.tokenApi.getAllSnapshots(
        offset: offset,
        limit: _kSnapshotLimit,
      )).data;
      await database.safeSnapshotDao.insertSdkSnapshots(
        await _keepOpponents(snapshots),
      );
      opponentIds.addAll(
        snapshots.map((e) => e.opponentId).where((e) => e.isNotEmpty),
      );
      if (snapshots.isEmpty) break;
      offset = snapshots.last.createdAt;
      AccountKeyValue.instance.safeSnapshotOffset = offset;
      if (snapshots.length < _kSnapshotLimit) break;
    }
    if (opponentIds.isNotEmpty) await refreshUsers(opponentIds.toList());
  }

  // The list API can return a snapshot without the opponent that its
  // message had. Android keeps the stored opponent in that case.
  Future<List<SafeSnapshot>> _keepOpponents(List<SafeSnapshot> snapshots) =>
      Future.wait(
        snapshots.map((snapshot) async {
          if (snapshot.opponentId.isNotEmpty) return snapshot;
          final stored = await database.safeSnapshotDao
              .safeSnapshotById(snapshot.snapshotId)
              .getSingleOrNull();
          if (stored == null || stored.opponentId.isEmpty) return snapshot;
          return SafeSnapshot.fromJson(
            snapshot.toJson()..['opponent_id'] = stored.opponentId,
          );
        }),
      );
}

/// Runs [_run], or makes the running call run once more when it ends, so that
/// a run always starts after the latest call.
class _Coalesced {
  _Coalesced(this._name, this._run);

  final String _name;
  final Future<void> Function() _run;
  Future<void>? _running;
  var _again = false;

  Future<void> call() {
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    return _running = _loop().whenComplete(() => _running = null);
  }

  Future<void> _loop() async {
    do {
      _again = false;
      try {
        await _run();
      } catch (error, stacktrace) {
        e('WalletSync $_name: $error $stacktrace');
        return;
      }
    } while (_again);
  }
}

/// Adds the amount of each output to the balance of its kernel asset. An
/// output that holds an inscription is a collectible, not a balance.
void sumOutputs(
  Map<String, Decimal> balances,
  Iterable<SafeUtxoOutput> outputs,
) {
  for (final output in outputs) {
    if (output.inscriptionHash?.isNotEmpty ?? false) continue;
    final amount = Decimal.parse(output.amount);
    balances.update(
      output.asset,
      (value) => value + amount,
      ifAbsent: () => amount,
    );
  }
}
