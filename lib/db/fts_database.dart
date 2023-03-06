import 'package:drift/drift.dart';

import 'converter/millis_date_converter.dart';
import 'util/open_database.dart';

part 'fts_database.g.dart';

@DriftDatabase(
  include: {
    'moor/fts.drift',
  },
)
class FtsDatabase extends _$FtsDatabase {
  FtsDatabase(super.e);

  FtsDatabase._connect(super.c) : super.connect();

  /// Connect to the database.
  static Future<FtsDatabase> connect(
    String identityNumber, {
    bool fromMainIsolate = false,
  }) async {
    final connect = await openDatabaseConnection(
      identityNumber: identityNumber,
      dbName: 'fts',
      readCount: 4,
      fromMainIsolate: fromMainIsolate,
    );
    return FtsDatabase._connect(connect);
  }

  @override
  int get schemaVersion => 1;
}
