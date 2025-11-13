import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../extension/db.dart';
import '../mixin_database.dart';

part 'inscription_collection_dao.g.dart';

@DriftAccessor(include: {'../moor/dao/inscription_collection.drift'})
class InscriptionCollectionDao extends DatabaseAccessor<MixinDatabase>
    with _$InscriptionCollectionDaoMixin {
  InscriptionCollectionDao(super.attachedDatabase);

  Future<InscriptionCollection?> findCollectionByHash(String hash) async =>
      (select(
        inscriptionCollections,
      )..where((tbl) => tbl.collectionHash.equals(hash))).getSingleOrNull();

  Future<InscriptionCollection> insertSdkCollection(
    sdk.InscriptionCollection collection,
  ) async {
    final item = collection.asDbItem;
    await into(inscriptionCollections).insert(item);
    return item;
  }

  Future<void> insert(
    InscriptionCollection collection, {
    required bool updateIfConflict,
  }) => into(
    db.inscriptionCollections,
  ).simpleInsert(collection, updateIfConflict: updateIfConflict);

  Future<List<InscriptionCollection>> getInscriptionCollections({
    required int limit,
    required int offset,
  }) =>
      (select(db.inscriptionCollections)
            ..orderBy([(t) => OrderingTerm.asc(t.rowId)])
            ..limit(limit, offset: offset))
          .get();
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
