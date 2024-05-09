import 'package:drift/drift.dart';

import '../mixin_database.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

part 'inscription_collection_dao.g.dart';

@DriftAccessor(include: {'../moor/dao/inscription_item.drift'})
class InscriptionCollectionDao extends DatabaseAccessor<MixinDatabase>
    with _$InscriptionCollectionDaoMixin {
  InscriptionCollectionDao(super.attachedDatabase);

  Future<InscriptionCollection?> findCollectionByHash(String hash) async =>
      (select(inscriptionCollections)
            ..where((tbl) => tbl.collectionHash.equals(hash)))
          .getSingleOrNull();

  Future<InscriptionCollection> insertSdkCollection(
      sdk.InscriptionCollection collection) async {
    final item = collection.asDbItem;
    await into(inscriptionCollections).insert(item);
    return item;
  }
}

extension _InscriptionCollectionExt on sdk.InscriptionCollection {
  InscriptionCollection get asDbItem => InscriptionCollection(
        collectionHash: collectionHash,
        supply: supply,
        unit: unit,
        symbol: symbol,
        name: name,
        iconUrl: iconUrl,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
