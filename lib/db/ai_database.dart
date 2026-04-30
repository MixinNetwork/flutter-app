import 'package:drift/drift.dart';

import 'converter/millis_date_converter.dart';
import 'dao/ai_chat_message_dao.dart';
import 'dao/ai_image_ocr_dao.dart';
import 'util/open_database.dart';

part 'ai_database.g.dart';

@DriftDatabase(
  include: {'moor/ai.drift'},
  daos: [AiChatMessageDao, AiImageOcrDao],
)
class AiDatabase extends _$AiDatabase {
  AiDatabase(super.e);

  static Future<AiDatabase> connect(
    String identityNumber, {
    bool fromMainIsolate = false,
  }) async {
    final queryExecutor = await openQueryExecutor(
      identityNumber: identityNumber,
      dbName: 'ai',
      readCount: 4,
      fromMainIsolate: fromMainIsolate,
    );
    return AiDatabase(queryExecutor);
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(imageOcrResults);
      }
    },
  );
}
