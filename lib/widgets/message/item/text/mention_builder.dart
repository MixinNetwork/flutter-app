import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../ui/provider/mention_cache_provider.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/hook.dart';
import '../../../high_light_text.dart';
import '../../../user/user_dialog.dart';

class MentionBuilder extends HookConsumerWidget {
  const MentionBuilder({
    super.key,
    required this.content,
    required this.builder,
    this.generateHighlightTextSpan = true,
  });

  final String? content;
  final bool generateHighlightTextSpan;
  final Widget Function(
    BuildContext context,
    String? newContent,
    Iterable<HighlightTextSpan> highlightTextSpans,
  ) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentionCache = ref.read(mentionCacheProvider);

    final mentionMap = useMemoizedFuture(
      () => mentionCache.checkMentionCache({content}),
      mentionCache.mentionCache(content),
      keys: [content],
    ).requireData;

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
              color: context.theme.accent,
            ),
            onTap: () => showUserDialog(context, entry.value.userId),
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
