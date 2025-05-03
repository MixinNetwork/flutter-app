import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../mixin_database.dart';

part 'chain_dao.g.dart';

extension ChainConverter on sdk.Chain {
  ChainsCompanion get asChainsCompanion => ChainsCompanion.insert(
    chainId: chainId,
    name: name,
    symbol: symbol,
    iconUrl: iconUrl,
    threshold: threshold,
  );
}

@DriftAccessor(include: {'../moor/dao/chain.drift'})
class ChainDao extends DatabaseAccessor<MixinDatabase> with _$ChainDaoMixin {
  ChainDao(super.db);

  Future<int> insertSdkChain(sdk.Chain chain) =>
      into(db.chains).insertOnConflictUpdate(chain.asChainsCompanion);

  SimpleSelectStatement<Chains, Chain> chain(String chainId) =>
      select(db.chains)
        ..where((t) => t.chainId.equals(chainId))
        ..limit(1);
}
