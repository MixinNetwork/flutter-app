import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../constants/resources.dart';
import '../../../db/dao/conversation_dao.dart';
import '../../../utils/hook.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../provider/account_server_provider.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/ui_context_providers.dart';
import '../conversation/conversation_page.dart';

class GroupsInCommonPage extends HookConsumerWidget {
  const GroupsInCommonPage(this.conversationState, {super.key});

  final ConversationState conversationState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = conversationState.userId;
    if (userId == null) return const SizedBox();
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);

    return Scaffold(
      backgroundColor: theme.primary,
      appBar: MixinAppBar(title: Text(l10n.groupsInCommon)),
      body: _ConversationList(userId: userId),
    );
  }
}

class _ConversationList extends HookConsumerWidget {
  const _ConversationList({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final conversationList = useMemoizedFuture(
      () {
        final accountServer = ref.read(accountServerProvider).requireValue;
        final selfId = accountServer.userId;
        return accountServer.database.conversationDao
            .findSameConversations(selfId, userId)
            .get();
      },
      <GroupMinimal>[],
      keys: [userId],
    ).data;

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
                theme.secondaryText,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noResults,
              style: TextStyle(
                color: theme.secondaryText,
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

class _GroupConversationItemWidget extends ConsumerWidget {
  const _GroupConversationItemWidget({required this.group});

  final GroupMinimal group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    return SizedBox(
      height: ConversationPage.conversationItemHeight,
      child: InteractiveDecoratedBox(
        onTap: () {
          ConversationStateNotifier.selectConversation(
            ref.container,
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
                            color: theme.text,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(
                          height: 20,
                          child: Text(
                            l10n.participantsCount(group.memberCount),
                            style: TextStyle(
                              color: theme.secondaryText,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
