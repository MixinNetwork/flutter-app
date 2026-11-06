import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../mixin_database.dart';

part 'token_dao.g.dart';

@DriftAccessor(include: {'../moor/dao/token.drift'})
class TokenDao extends DatabaseAccessor<MixinDatabase> with _$TokenDaoMixin {
  TokenDao(super.attachedDatabase);

  Selectable<Token> tokenById(String id) =>
      (select(db.tokens)..where((t) => t.assetId.equals(id)));

  Future<void> insertSdkToken(sdk.Token token) =>
      into(db.tokens).insertOnConflictUpdate(token.asTokensCompanion);

  Future<void> insertToken(Token token) =>
      into(db.tokens).insertOnConflictUpdate(token);

  Future<List<Token>> getTokens() => select(db.tokens).get();

  Future<void> insertSdkTokens(Iterable<sdk.Token> tokens) => batch(
    (batch) => batch.insertAllOnConflictUpdate(
      db.tokens,
      tokens.map((e) => e.asTokensCompanion),
    ),
  );

  Selectable<WalletTokenItem> walletTokenItems({required bool hidden}) =>
      walletTokens(
        (t, e, c) => e.hidden.equals(hidden) & e.balance.equals('0').not(),
      );

  Selectable<WalletTokenItem> walletTokenItem(String assetId) =>
      walletTokens((t, e, c) => t.assetId.equals(assetId));

  /// Sets the balance of each kernel asset in [balances], and sets the
  /// balance of every other kernel asset to zero.
  Future<void> replaceBalances(Map<String, String> balances) => transaction(
    () async {
      await (update(db.tokensExtra)
            ..where((t) => t.kernelAssetId.isNotIn(balances.keys)))
          .write(const TokensExtraCompanion(balance: Value('0')));
      await batch((batch) {
        for (final MapEntry(:key, :value) in balances.entries) {
          batch.insert(
            db.tokensExtra,
            TokensExtraCompanion.insert(kernelAssetId: key, balance: value),
            onConflict: DoUpdate(
              (_) => TokensExtraCompanion(balance: Value(value)),
            ),
          );
        }
      });
    },
  );

  Future<void> setHidden(String kernelAssetId, {required bool hidden}) =>
      (update(db.tokensExtra)
            ..where((t) => t.kernelAssetId.equals(kernelAssetId)))
          .write(TokensExtraCompanion(hidden: Value(hidden)));
}

extension TokenConverter on sdk.Token {
  TokensCompanion get asTokensCompanion => TokensCompanion.insert(
    assetId: assetId,
    kernelAssetId: asset,
    symbol: symbol,
    name: name,
    iconUrl: iconUrl,
    priceBtc: priceBtc,
    priceUsd: priceUsd,
    chainId: chainId,
    changeUsd: changeUsd,
    changeBtc: changeBtc,
    confirmations: confirmations,
    assetKey: assetKey,
    dust: dust,
    collectionHash: Value(collectionHash),
    precision: Value(precision),
  );
}
