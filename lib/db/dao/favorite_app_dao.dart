import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../database_event_bus.dart';
import '../mixin_database.dart';

part 'favorite_app_dao.g.dart';

@DriftAccessor(include: {'../moor/dao/favorite_app.drift'})
class FavoriteAppDao extends DatabaseAccessor<MixinDatabase>
    with _$FavoriteAppDaoMixin {
  FavoriteAppDao(super.db);

  Future<void> insertFavoriteApps(
    String userId,
    List<sdk.FavoriteApp> apps,
  ) async {
    await _deleteFavoriteAppByUserId(userId);
    final list =
        apps
            .map(
              (app) => FavoriteAppsCompanion.insert(
                appId: app.appId,
                userId: app.userId,
                createdAt: app.createdAt,
              ),
            )
            .toList();
    await batch(
      (batch) => batch.insertAllOnConflictUpdate(db.favoriteApps, list),
    );

    DataBaseEventBus.instance.updateFavoriteApp(apps.map((e) => e.appId));
  }
}
