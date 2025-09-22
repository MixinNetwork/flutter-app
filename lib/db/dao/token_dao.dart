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
