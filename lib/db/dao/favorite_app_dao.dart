import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../mixin_database.dart';

part 'favorite_app_dao.g.dart';

@DriftAccessor(tables: [FavoriteApp])
class FavoriteAppDao extends DatabaseAccessor<MixinDatabase>
    with _$FavoriteAppDaoMixin {
  FavoriteAppDao(MixinDatabase db) : super(db);

  Future<void> deleteByAppIdAndUserId(String appId, String userId) =>
      db.deleteFavoriteAppByAppIdAndUserId(appId, userId);

  Future<void> deleteByUserId(String userId) =>
      db.deleteFavoriteAppByUserId(userId);

  Future<void> insertFavoriteApps(
      String userId, List<sdk.FavoriteApp> apps) async {
    await deleteByUserId(userId);
    final list = apps
        .map((app) => FavoriteAppsCompanion.insert(
              appId: app.appId,
              userId: app.userId,
              createdAt: app.createdAt,
            ))
        .toList();
    return batch(
        (batch) => batch.insertAllOnConflictUpdate(db.favoriteApps, list));
  }

  Selectable<App> getFavoriteAppsByUserId(String userId) =>
      db.getFavoriteAppByUserId(userId);
}
