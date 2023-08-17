import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../constants/resources.dart';
import '../../../db/dao/conversation_dao.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../provider/conversation_provider.dart';
import '../conversation/conversation_page.dart';

class GroupsInCommonPage extends HookConsumerWidget {
  const GroupsInCommonPage(this.conversationState, {super.key});

  final ConversationState conversationState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = conversationState.userId;
    if (userId == null) return const SizedBox();

    return Scaffold(
      backgroundColor: context.theme.primary,
      appBar: MixinAppBar(
        title: Text(context.l10n.groupsInCommon),
      ),
      body: _ConversationList(userId: userId),
    );
  }
}

class _ConversationList extends HookConsumerWidget {
  const _ConversationList({
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationList = useMemoizedFuture(() {
      final selfId = context.accountServer.userId;
      return context.accountServer.database.conversationDao
          .findSameConversations(selfId, userId)
          .get();
    }, <GroupMinimal>[], keys: [userId]).data;

    if (conversationList == null) {
      return const Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (conversationList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              Resources.assetsImagesEmptyFileSvg,
              height: 80,
              width: 80,
              colorFilter: ColorFilter.mode(
                  context.theme.secondaryText, BlendMode.srcIn),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.noResults,
              style: TextStyle(
                color: context.theme.secondaryText,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: conversationList.length,
      itemBuilder: (context, index) {
        final conversation = conversationList[index];
        return _GroupConversationItemWidget(group: conversation);
      },
    );
  }
}

class _GroupConversationItemWidget extends StatelessWidget {
  const _GroupConversationItemWidget({
    required this.group,
  });

  final GroupMinimal group;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: ConversationPage.conversationItemHeight,
        child: InteractiveDecoratedBox(
          onTap: () {
            ConversationStateNotifier.selectConversation(
              context,
              group.conversationId,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  ConversationAvatarWidget(
                    size: ConversationPage.conversationItemAvatarSize,
                    conversationId: group.conversationId,
                    category: ConversationCategory.group,
                    groupIconUrl: group.groupIconUrl,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.groupName ?? '',
                            style: TextStyle(
                              color: context.theme.text,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            height: 20,
                            child: Text(
                              context.l10n.participantsCount(group.memberCount),
                              style: TextStyle(
                                color: context.theme.secondaryText,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
}
