import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../db/database.dart';
import '../../db/fts_database.dart';
import '../../db/mixin_database.dart';
import '../home/bloc/slide_category_cubit.dart';

final databaseProvider = FutureProvider.family.autoDispose<Database, String>(
  (ref, identityNumber) async {
    i('connect to database: $identityNumber');
    final mixinDatabase =
        await connectToDatabase(identityNumber, fromMainIsolate: true);
    final db = Database(
      mixinDatabase,
      await FtsDatabase.connect(identityNumber, fromMainIsolate: true),
    );
    ref.onDispose(() {
      i('dispose database: $identityNumber');
      db.dispose();
    });
    // Do a database query, to ensure database has properly initialized.
    await mixinDatabase.conversationDao
        .conversationCountByCategory(SlideCategoryType.chats);
    return db;
  },
);
