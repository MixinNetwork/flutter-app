import 'dart:async';

import 'package:ecache/ecache.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../db/dao/user_dao.dart';
import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';
import '../../utils/extension/extension.dart';
import '../../utils/reg_exp_utils.dart';
import 'database_provider.dart';

class MentionCache {
  MentionCache(this._userDao, {DataBaseEventBus? eventBus}) {
    final userDao = _userDao;
    if (userDao == null) return;

    _updateUserSubscription = (eventBus ?? DataBaseEventBus.instance)
        .updateUserIdsStream
        .listen((
          userIds,
        ) {
          unawaited(
            _refreshUsers(userIds).catchError((
              Object error,
              StackTrace stackTrace,
            ) {
              e('mention user cache refresh failed: $error');
            }),
          );
        });
  }

  final UserDao? _userDao;

  StreamSubscription<List<String>>? _updateUserSubscription;

  final _contentMentionLruCache = LruCache<String, List<String>>(
    storage: SimpleStorage(),
    capacity: 1024 * 4,
  );
  final _userLruCache = LruCache<String, MentionUser>(
    storage: SimpleStorage(),
    capacity: 1024 * 8,
  );
  final _cachedUserIds = <String>{};

  Map<String, MentionUser> mentionCache(String? content) {
    if (content == null) return {};
    return _cachedIdentityNumbers(_identityNumbersForContent(content));
  }

  Future<Map<String, MentionUser>> checkMentionCache(
    Set<String?> _contents,
  ) async {
    final userNumbers = <String>{
      for (final content in _contents.nonNulls)
        ..._identityNumbersForContent(content),
    };
    return checkIdentityNumbers(userNumbers);
  }

  String? replaceMention(String? s, Map<String, MentionUser> _mentionMap) {
    if (s == null || s.isEmpty) return s;

    final mentionMap = _mentionMap.map(
      (key, value) => MapEntry(key.toLowerCase(), value),
    );
    final pattern = "(${mentionMap.keys.map(RegExp.escape).join('|')})";

    if (pattern == '()') return s;

    return s.replaceAllMapped(
      RegExp(pattern, caseSensitive: false),
      (match) => mentionMap[match[0]!]!.fullName!,
    );
  }

  MentionUser? identityNumberCache(String identityNumber) =>
      _userLruCache.get(identityNumber);

  void cacheUsers(Iterable<User> users) {
    cacheMentionUsers(users.map(_mentionUserFromUser));
  }

  void cacheMentionUsers(Iterable<MentionUser> users) {
    for (final user in users) {
      if (user.fullName?.isNotEmpty != true) {
        _userLruCache.remove(user.identityNumber);
        _cachedUserIds.remove(user.userId);
        continue;
      }
      _userLruCache.set(user.identityNumber, user);
      _cachedUserIds.add(user.userId);
    }
  }

  Future<void> _refreshUsers(Iterable<String> userIds) async {
    final userDao = _userDao;
    if (userDao == null) return;

    final cachedUserIds = userIds.where(_cachedUserIds.contains).toSet();
    if (cachedUserIds.isEmpty) return;

    cacheMentionUsers(await userDao.mentionUsersByUserIds(cachedUserIds));
  }

  void dispose() {
    unawaited(_updateUserSubscription?.cancel());
    _updateUserSubscription = null;
  }

  Future<Map<String, MentionUser>> checkIdentityNumbers(
    Set<String> identityNumbers,
  ) async {
    final toChecks = identityNumbers
        .where((element) => _userLruCache.get(element) == null)
        .toSet();

    final map = _cachedIdentityNumbers(identityNumbers);

    final userDao = _userDao;
    if (toChecks.isEmpty || userDao == null) return map;

    final list = await userDao.userByIdentityNumbers(toChecks.toList()).get();

    cacheMentionUsers(list);
    map.addAll(_cachedIdentityNumbers(toChecks));

    return map;
  }

  List<String> _identityNumbersForContent(String content) {
    final cache = _contentMentionLruCache.get(content);
    if (cache != null) return cache;

    final identityNumbers = mentionNumberRegExp
        .allMatchesAndSort(content)
        .map((e) => e[1]!)
        .toSet()
        .toList(growable: false);
    _contentMentionLruCache.set(content, identityNumbers);
    return identityNumbers;
  }

  Map<String, MentionUser> _cachedIdentityNumbers(
    Iterable<String> identityNumbers,
  ) => Map.fromEntries(
    identityNumbers
        .map(_userLruCache.get)
        .nonNulls
        .map((user) => MapEntry(user.identityNumber, user)),
  );

  MentionUser _mentionUserFromUser(User user) => MentionUser(
    userId: user.userId,
    identityNumber: user.identityNumber,
    fullName: user.fullName,
  );
}

final mentionCacheProvider = Provider((ref) {
  final mentionCache = MentionCache(
    ref.watch(databaseProvider.select((value) => value.valueOrNull?.userDao)),
  );
  ref.onDispose(mentionCache.dispose);
  return mentionCache;
});
