import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../mixin_database.dart';

part 'inscription_item_dao.g.dart';

@DriftAccessor(include: {'../moor/dao/inscription_collection.drift'})
class InscriptionItemDao extends DatabaseAccessor<MixinDatabase>
    with _$InscriptionItemDaoMixin {
  InscriptionItemDao(super.attachedDatabase);

  Future<InscriptionItem?> findInscriptionByHash(String hash) =>
      (select(inscriptionItems)
            ..where((tbl) => tbl.inscriptionHash.equals(hash)))
          .getSingleOrNull();

  Future<InscriptionItem> insertSdkItem(sdk.InscriptionItem inscription) async {
    final dbItem = inscription.asDbItem;
    await into(inscriptionItems).insert(dbItem);
    return dbItem;
  }
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
