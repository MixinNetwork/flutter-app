import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../extension/db.dart';
import '../mixin_database.dart';
import '../vo/inscription.dart';

part 'inscription_item_dao.g.dart';

@DriftAccessor(include: {'../moor/dao/inscription_item.drift'})
class InscriptionItemDao extends DatabaseAccessor<MixinDatabase>
    with _$InscriptionItemDaoMixin {
  InscriptionItemDao(super.attachedDatabase);

  Future<InscriptionItem?> findInscriptionByHash(String hash) =>
      (select(inscriptionItems)
        ..where((tbl) => tbl.inscriptionHash.equals(hash))).getSingleOrNull();

  Future<InscriptionItem> insertSdkItem(sdk.InscriptionItem inscription) async {
    final dbItem = inscription.asDbItem;
    await into(inscriptionItems).insert(dbItem);
    return dbItem;
  }

  Future<void> insert(
    InscriptionItem inscription, {
    required bool updateIfConflict,
  }) => into(
    db.inscriptionItems,
  ).simpleInsert(inscription, updateIfConflict: updateIfConflict);

  Future<List<InscriptionItem>> getInscriptionItems({
    required int limit,
    required int offset,
  }) =>
      (select(db.inscriptionItems)
            ..orderBy([(t) => OrderingTerm.asc(t.rowId)])
            ..limit(limit, offset: offset))
          .get();
}

extension _InscriptionItemExt on sdk.InscriptionItem {
  InscriptionItem get asDbItem => InscriptionItem(
    inscriptionHash: inscriptionHash,
    collectionHash: collectionHash,
    sequence: sequence,
    contentType: contentType,
    contentUrl: contentURL,
    createdAt: createdAt,
    updatedAt: updatedAt,
    occupiedAt: occupiedAt,
    occupiedBy: occupiedBy,
  );
}
