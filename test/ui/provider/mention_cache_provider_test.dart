import 'package:drift/native.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/provider/database_provider.dart';
import 'package:flutter_app/ui/provider/mention_cache_provider.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('replaceMention preserves empty content', () {
    final mentionCache = MentionCache(null);

    expect(mentionCache.replaceMention('', {}), '');
  });

  test(
    'checkMentionCache reflects user name updates for cached content',
    () async {
      EventBus.initialize();

      final database = MixinDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      final mentionCache = MentionCache(database.userDao);
      addTearDown(mentionCache.dispose);

      const content = 'hello @7001';

      await database.userDao.insert(
        const User(userId: 'user-1', identityNumber: '7001', fullName: 'Alice'),
      );

      expect(
        (await mentionCache.checkMentionCache({content}))['7001']?.fullName,
        'Alice',
      );

      await database.userDao.insert(
        const User(userId: 'user-1', identityNumber: '7001', fullName: 'Bob'),
      );
      await pumpEventQueue();

      expect(
        (await mentionCache.checkMentionCache({content}))['7001']?.fullName,
        'Bob',
      );

      await database.userDao.insert(
        const User(userId: 'user-1', identityNumber: '7001', fullName: ''),
      );
      await pumpEventQueue();

      expect((await mentionCache.checkMentionCache({content}))['7001'], isNull);
    },
  );

  test('cacheUsers makes mention users synchronously available', () {
    final mentionCache = MentionCache(null)
      ..cacheUsers([
        const User(
          userId: 'user-1',
          identityNumber: '7001',
          fullName: 'Alice',
        ),
      ]);

    expect(mentionCache.identityNumberCache('7001')?.fullName, 'Alice');
    expect(mentionCache.mentionCache('hello @7001')['7001']?.fullName, 'Alice');
  });

  test(
    'mentionCacheProvider preserves cache across read-only consumers',
    () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWith((ref) => DatabaseOpener()),
        ],
      );
      addTearDown(container.dispose);

      final first = container.read(mentionCacheProvider)
        ..cacheUsers([
          const User(
            userId: 'user-1',
            identityNumber: '7001',
            fullName: 'Alice',
          ),
        ]);

      await container.pump();

      final second = container.read(mentionCacheProvider);

      expect(identical(first, second), isTrue);
      expect(second.mentionCache('hello @7001')['7001']?.fullName, 'Alice');
    },
  );
}
