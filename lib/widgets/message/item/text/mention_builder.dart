import 'package:flutter/widgets.dart';
import '../../../../utils/load_balancer_utils.dart';

import 'mention_data.dart';

class MentionBuilder extends StatelessWidget {
  const MentionBuilder({
    Key? key,
    required this.mentionString,
    required this.builder,
  }) : super(key: key);

  final String? mentionString;
  final AsyncWidgetBuilder<Map<String, String>> builder;

  static final Map<String, Map<String, String>> _mentionCache = {};

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, String>>(
        future: mentionsConverter(mentionString),
        initialData: _mentionCache[mentionString] ?? {},
        builder: builder,
      );

  static Future<Map<String, String>> mentionsConverter(
      String? mentionString) async {
    if (mentionString == null) return {};
    _mentionCache[mentionString] ??= <String, String>{
      for (var item in List<MentionData>.of(
          // ignore: avoid_dynamic_calls
          (await jsonDecodeWithIsolate(mentionString))
              .map((e) => MentionData.fromJson(e))))
        item.identityNumber: item.fullName
    };
    return _mentionCache[mentionString]!;
  }
}
