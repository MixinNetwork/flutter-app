import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../mixin_database.dart';

part 'token_dao.g.dart';

@DriftAccessor(include: {'../moor/dao/token.drift'})
class TokenDao extends DatabaseAccessor<MixinDatabase> with _$TokenDaoMixin {
  TokenDao(super.attachedDatabase);

  Future<void> insertSdkToken(sdk.Token token) =>
      into(db.tokens).insertOnConflictUpdate(token.asTokensCompanion);
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
      );
}
