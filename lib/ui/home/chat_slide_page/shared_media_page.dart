import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../utils/extension/extension.dart';
import '../../../widgets/app_bar.dart';
import '../bloc/conversation_cubit.dart';
import 'share_media/file_page.dart';
import 'share_media/media_page.dart';
import 'share_media/post_page.dart';

class SharedMediaPage extends HookWidget {
  const SharedMediaPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final conversationId = useMemoized(() {
      final conversationId =
          context.read<ConversationCubit>().state?.conversationId;
      assert(conversationId != null);
      return conversationId!;
    });

    final selectedIndex = useState(0);
    return Scaffold(
      backgroundColor: context.theme.primary,
      appBar: MixinAppBar(
        title: Text(context.l10n.sharedMedia),
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) =>
                  IndexedStack(
                index: selectedIndex.value,
                children: [
                  MediaPage(
                    conversationId: conversationId,
                    maxHeight: constraints.maxHeight,
                  ),
                  PostPage(
                    conversationId: conversationId,
                    maxHeight: constraints.maxHeight,
                  ),
                  FilePage(
                    conversationId: conversationId,
                    maxHeight: constraints.maxHeight,
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              context.l10n.media,
              context.l10n.post,
              context.l10n.file,
            ]
                .asMap()
                .entries
                .map(
                  (e) => Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => selectedIndex.value = e.key,
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 14,
                            color: e.key == selectedIndex.value
                                ? context.theme.accent
                                : context.theme.secondaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
