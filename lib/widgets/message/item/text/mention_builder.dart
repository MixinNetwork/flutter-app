import 'package:ecache/ecache.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../../../../db/dao/users_dao.dart';
import '../../../../db/mixin_database.dart';
import '../../../../ui/home/bloc/conversation_cubit.dart';
import '../../../../utils/hook.dart';
import '../../../../utils/reg_exp_utils.dart';
import '../../../brightness_observer.dart';
import '../../../high_light_text.dart';

class MentionCache {
  MentionCache(this._userDao);

  final UserDao _userDao;

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
      Set<String?> _contents) async {
    final map = <String, MentionUser>{};
    final noCacheContents = <String>{};

    final contents =
        _contents.where((element) => element != null).cast<String>().toSet();

    for (var element in contents) {
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
          mentionNumberRegExp.allMatches(e).map((e) => e[1]!),
        ),
      ),
    );

    var userIds = <String>{
      for (final item in noCacheContentUserIdMap.values) ...item
    };

    if (userIds.isEmpty) {
      for (var e in noCacheContents) {
        _contentMentionLruCache.set(e.hashCode, {});
      }
    } else {
      userIds = userIds
          .where((element) => _userLruCache.get(element) == null)
          .toSet();

      final list = await _userDao.userByIdentityNumbers(userIds.toList()).get();

      list
          .where((element) => element.fullName?.isNotEmpty ?? false)
          .forEach((element) {
        _userLruCache.set(element.identityNumber, element);
        map[element.identityNumber] = element;
      });

      for (var element in noCacheContentUserIdMap.entries) {
        _contentMentionLruCache.set(
          element.key.hashCode,
          Map.fromEntries(
            map.entries.where(
              (entry) => element.value.contains(entry.key),
            ),
          ),
        );
      }
    }

    return map;
  }

  String? replaceMention(String? s, Map<String, MentionUser> _mentionMap) {
    if (s == null || s.isEmpty) return null;

    final mentionMap =
        _mentionMap.map((key, value) => MapEntry(key.toLowerCase(), value));
    final pattern = "(${mentionMap.keys.map(RegExp.escape).join('|')})";

    if (pattern == '()') return s;

    return s.replaceAllMapped(RegExp(pattern, caseSensitive: false),
        (match) => mentionMap[match[0]!]!.fullName!);
  }
}

class MentionBuilder extends HookWidget {
  const MentionBuilder({
    Key? key,
    required this.content,
    required this.builder,
    this.generateHighlightTextSpan = true,
  }) : super(key: key);

  final String? content;
  final bool generateHighlightTextSpan;
  final Widget Function(
    BuildContext context,
    String? newContent,
    Iterable<HighlightTextSpan> highlightTextSpans,
  ) builder;

  @override
  Widget build(BuildContext context) {
    final mentionCache = context.read<MentionCache>();

    final mentionMap = useMemoizedFuture(
      () => mentionCache.checkMentionCache({content}),
      mentionCache.mentionCache(content),
      keys: [content],
    );

    final newContent = useMemoized(
      () => mentionCache.replaceMention(content, mentionMap),
      [content, mentionMap],
    );

    final highlightTextSpans = useMemoized(
      () {
        if (!generateHighlightTextSpan) return <HighlightTextSpan>[];

        return mentionMap.entries.map(
          (entry) => HighlightTextSpan(
            '@${entry.value.fullName}',
            style: TextStyle(
              color: BrightnessData.themeOf(context).accent,
            ),
            onTap: () => context.read<ConversationCubit>().selectUser(
                  entry.value.userId,
                  !entry.value.identityNumber.startsWith('7000'),
                ),
          ),
        );
      },
      [content, mentionMap],
    );

    return builder(
      context,
      newContent,
      highlightTextSpans,
    );
  }
}
