@TestOn('linux || mac-os')
library;

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_app/db/ai_database.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/provider/database_provider.dart';
import 'package:flutter_app/ui/provider/user_cache_provider.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _TestDatabaseOpener extends DatabaseOpener {
  _TestDatabaseOpener(Database database) {
    state = AsyncValue.data(database);
  }
}

void main() {
  setUpAll(EventBus.initialize);

  test('updates cached user when user table changes', () async {
    final database = Database(
      MixinDatabase(NativeDatabase.memory()),
      FtsDatabase(NativeDatabase.memory()),
      AiDatabase(NativeDatabase.memory()),
    );
    addTearDown(database.dispose);

    await database.userDao.insert(
      const User(userId: 'sender', identityNumber: '7001', fullName: 'Sender'),
    );

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWith((ref) => _TestDatabaseOpener(database)),
      ],
    );
    addTearDown(container.dispose);

    await pumpEventQueue();
    expect(container.read(userCacheProvider('sender'))?.avatarUrl, isNull);

    final updated = Completer<String>();
    final subscription = container.listen<User?>(
      userCacheProvider('sender'),
      (_, user) {
        final avatarUrl = user?.avatarUrl;
        if (avatarUrl != null && !updated.isCompleted) {
          updated.complete(avatarUrl);
        }
      },
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await database.userDao.insert(
      const User(
        userId: 'sender',
        identityNumber: '7001',
        fullName: 'Sender',
        avatarUrl: 'https://example.com/avatar.png',
      ),
    );

    await expectLater(
      updated.future.timeout(const Duration(seconds: 1)),
      completion('https://example.com/avatar.png'),
    );
  });

  test('reloads fresh user after listeners detach', () async {
    final database = Database(
      MixinDatabase(NativeDatabase.memory()),
      FtsDatabase(NativeDatabase.memory()),
      AiDatabase(NativeDatabase.memory()),
    );
    addTearDown(database.dispose);

    await database.userDao.insert(
      const User(userId: 'sender', identityNumber: '7001', fullName: 'Sender'),
    );

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWith((ref) => _TestDatabaseOpener(database)),
      ],
    );
    addTearDown(container.dispose);
    final databaseSubscription = container.listen(
      databaseProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(databaseSubscription.close);

    final subscription = container.listen<User?>(
      userCacheProvider('sender'),
      (_, _) {},
      fireImmediately: true,
    );
    await pumpEventQueue();
    expect(container.read(userCacheProvider('sender'))?.avatarUrl, isNull);

    subscription.close();
    await pumpEventQueue();

    await database.mixinDatabase
        .into(database.mixinDatabase.users)
        .insertOnConflictUpdate(
          const User(
            userId: 'sender',
            identityNumber: '7001',
            fullName: 'Sender',
            avatarUrl: 'https://example.com/avatar.png',
          ),
        );

    final fresh = Completer<String>();
    container.listen<User?>(
      userCacheProvider('sender'),
      (_, user) {
        final avatarUrl = user?.avatarUrl;
        if (avatarUrl != null && !fresh.isCompleted) {
          fresh.complete(avatarUrl);
        }
      },
      fireImmediately: true,
    );

    await expectLater(
      fresh.future.timeout(const Duration(seconds: 1)),
      completion('https://example.com/avatar.png'),
    );
  });
}
