import 'dart:convert';

import 'package:drift/drift.dart';

import '../enum/message_category.dart';
import '../utils/extension/extension.dart';
import '../widgets/message/item/action_card/action_card_data.dart';
import 'converter/millis_date_converter.dart';
import 'mixin_database.dart' show Message;
import 'util/open_database.dart';
import 'util/util.dart';

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

  Future<List<String>> getAllMessageIds() => (select(messagesMetas)
        ..orderBy([
          (t) => OrderingTerm(expression: t.messageId, mode: OrderingMode.desc),
        ]))
      .map((e) => e.messageId)
      .get();

  Future<void> insertFts(Message message, [String? generatedContent]) async {
    String? content;
    if (generatedContent != null) {
      content = generatedContent;
    } else if (message.category.isText || message.category.isPost) {
      content = message.content;
    } else if (message.category.isData) {
      content = message.name;
    } else if (message.category.isContact) {
      content = message.name;
    } else if (message.category == MessageCategory.appCard) {
      final appCard = AppCardData.fromJson(
          jsonDecode(message.content!) as Map<String, dynamic>);
      content = '${appCard.title} ${appCard.description}';
    }

    if (content == null || content.isEmpty) {
      return;
    }

    // check if the message is already in the fts table
    final fts = await (select(messagesMetas)
          ..where((tbl) => tbl.messageId.equals(message.messageId)))
        .getSingleOrNull();
    if (fts != null) {
      // d('Message ${message.messageId} already in metas table');
      return;
    }

    final ftsContent = content.joinWhiteSpace();
    final rowId =
        await into(messagesFts).insert(MessagesFt(content: ftsContent));
    await into(messagesMetas).insert(
      MessagesMeta(
        docId: rowId,
        messageId: message.messageId,
        conversationId: message.conversationId,
        category: message.category,
        userId: message.userId,
        createdAt: message.createdAt,
      ),
    );
  }

  Future<void> deleteByMessageId(String messageId) async {
    await _deleteFtsByMessageId(messageId);
    await (delete(messagesMetas)
          ..where((tbl) => tbl.messageId.equals(messageId)))
        .go();
  }

  /// query the fts table.
  /// [anchorMessageId]. only return message after this message.
  /// return messageId list.
  Future<List<String>> fuzzySearchMessage({
    required String query,
    required int limit,
    required List<String> conversationIds,
    String? userId,
    List<String>? categories,
    String? anchorMessageId,
  }) {
    final keywordFts5 = query.trim().escapeFts5();

    Expression<bool> where(MessagesMetas m) {
      Expression<bool> where = ignoreWhere;
      if (conversationIds.isNotEmpty) {
        where = where & m.conversationId.isIn(conversationIds);
      }
      if (userId != null) {
        where = where & m.userId.equals(userId);
      }
      if (categories != null) {
        where = where & m.category.isIn(categories);
      }
      return where;
    }

    if (anchorMessageId == null) {
      return _fuzzySearchAllMessage(keywordFts5, where, limit).get();
    } else {
      return _fuzzySearchAllMessageWithAnchor(
        query,
        anchorMessageId,
        where,
        limit,
      ).get();
    }
  }
}
