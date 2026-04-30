import 'package:drift/drift.dart';

import '../ai_database.dart';

part 'ai_image_ocr_dao.g.dart';

@DriftAccessor()
class AiImageOcrDao extends DatabaseAccessor<AiDatabase>
    with _$AiImageOcrDaoMixin {
  AiImageOcrDao(super.db);

  Future<ImageOcrResult?> resultByMessageId(String messageId) =>
      (select(db.imageOcrResults)..where(
            (tbl) => tbl.messageId.equals(messageId),
          ))
          .getSingleOrNull();

  Future<void> upsertResult(ImageOcrResultsCompanion row) =>
      into(db.imageOcrResults).insertOnConflictUpdate(row);
}
