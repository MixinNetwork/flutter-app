import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../mixin_database.dart';

part 'fiat_dao.g.dart';

@DriftAccessor()
class FiatDao extends DatabaseAccessor<MixinDatabase> with _$FiatDaoMixin {
  FiatDao(super.db);

  Future<void> insertAllSdkFiat(List<sdk.Fiat> fiats) async {
    await db.delete(db.fiats).go();
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        db.fiats,
        fiats
            .map(
              (fiat) => FiatsCompanion.insert(code: fiat.code, rate: fiat.rate),
            )
            .toList(),
      );
    });
  }
}
