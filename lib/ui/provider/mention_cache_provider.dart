import 'package:ecache/ecache.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../db/dao/user_dao.dart';
import '../../utils/extension/extension.dart';
import '../../utils/reg_exp_utils.dart';
import 'database_provider.dart';

class MentionCache {
  MentionCache(this._userDao);

  final UserDao? _userDao;

  final _contentMentionLruCache = LruCache<int, Map<String, MentionUser>>(
    storage: SimpleStorage(),
    capacity: 1024 * 4,
  );
  final _userLruCache = LruCache<String, MentionUser>(
    storage: SimpleStorage(),
    capacity: 1024,
  );

  Map<String, MentionUser> mentionCache(String? content) {
    if (content == null) return {};
    return _contentMentionLruCache.get(content.hashCode) ?? {};
  }

  Future<Map<String, MentionUser>> checkMentionCache(
    Set<String?> _contents,
  ) async {
    final userDao = _userDao;
    if (userDao == null) return {};

    final map = <String, MentionUser>{};
    final noCacheContents = <String>{};

    final contents = _contents.nonNulls.toSet();

    for (final element in contents) {
      final cache = _contentMentionLruCache.get(element.hashCode);
      if (cache != null) {
        map.addAll(cache);
      } else {
        noCacheContents.add(element);
      }
    }

    if (noCacheContents.isEmpty) return map;

    final noCacheContentUserIdMap = Map.fromEntries(
      noCacheContents.map(
        (e) => MapEntry(
          e,
          mentionNumberRegExp.allMatchesAndSort(e).map((e) => e[1]!),
        ),
      ),
    );

    var userNumbers = <String>{
      for (final item in noCacheContentUserIdMap.values) ...item,
    };

    if (userNumbers.isEmpty) {
      for (final e in noCacheContents) {
        _contentMentionLruCache.set(e.hashCode, {});
      }
    } else {
      userNumbers = userNumbers
          .where((element) => _userLruCache.get(element) == null)
          .toSet();

      final list = await userDao
          .userByIdentityNumbers(userNumbers.toList())
          .get();

      list.where((element) => element.fullName?.isNotEmpty ?? false).forEach((
        element,
      ) {
        _userLruCache.set(element.identityNumber, element);
        map[element.identityNumber] = element;
      });

      for (final element in noCacheContentUserIdMap.entries) {
        element.value.forEach((String element) {
          if (map[element] != null) return;
          final mentionUser = _userLruCache.get(element);
          if (mentionUser == null) return;
          map[element] = mentionUser;
        });

        _contentMentionLruCache.set(
          element.key.hashCode,
          Map.fromEntries(
            map.entries.where((entry) => element.value.contains(entry.key)),
          ),
        );
      }
    }

    return map;
  }

  String? replaceMention(String? s, Map<String, MentionUser> _mentionMap) {
    if (s == null || s.isEmpty) return null;

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

  Future<Map<String, MentionUser>> checkIdentityNumbers(
    Set<String> identityNumbers,
  ) async {
    final userDao = _userDao;
    if (userDao == null) return {};

    final toChecks = identityNumbers
        .where((element) => _userLruCache.get(element) == null)
        .toSet();

    final mentionUsers = identityNumbers.map(_userLruCache.get).nonNulls;
    final map = Map.fromIterables(
      mentionUsers.map((e) => e.identityNumber),
      mentionUsers,
    );

    if (toChecks.isEmpty) return map;

    final list = await userDao.userByIdentityNumbers(toChecks.toList()).get();

    list.where((element) => element.fullName?.isNotEmpty ?? false).forEach((
      element,
    ) {
      _userLruCache.set(element.identityNumber, element);
      map[element.identityNumber] = element;
    });

    return map;
  }
}

final mentionCacheProvider = Provider.autoDispose(
  (ref) => MentionCache(
    ref.watch(databaseProvider.select((value) => value.valueOrNull?.userDao)),
  ),
);
