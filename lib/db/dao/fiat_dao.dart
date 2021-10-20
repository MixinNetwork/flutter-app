import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;
import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'fiat_dao.g.dart';

@UseDao(tables: [Fiat])
class FiatDao extends DatabaseAccessor<MixinDatabase> with _$FiatDaoMixin {
  FiatDao(MixinDatabase db) : super(db);

  Future<void> insertAllSdkFiat(List<sdk.Fiat> fiats) async {
    await db.delete(db.fiats).go();
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        db.fiats,
        fiats
            .map((fiat) => FiatsCompanion.insert(
                  code: fiat.code,
                  rate: fiat.rate,
                ))
            .toList(),
      );
    });
  }
}
