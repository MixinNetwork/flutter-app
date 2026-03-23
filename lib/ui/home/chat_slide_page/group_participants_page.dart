import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../../constants/constants.dart';
import '../../../constants/icon_fonts.dart';
import '../../../constants/resources.dart';
import '../../../db/dao/participant_dao.dart';
import '../../../db/database_event_bus.dart';
import '../../../utils/extension/extension.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/conversation/badges_widget.dart';
import '../../../widgets/high_light_text.dart';
import '../../../widgets/menu.dart';
import '../../../widgets/search_text_field.dart';
import '../../../widgets/toast.dart';
import '../../../widgets/user/user_dialog.dart';
import '../../../widgets/user_selector/conversation_selector.dart';
import '../../provider/account_server_provider.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/database_provider.dart';
import '../../provider/ui_context_providers.dart';
import 'group_invite/group_invite_dialog.dart';

/// The participants of group.
final _groupParticipantsProvider = StreamProvider.autoDispose
    .family<List<ParticipantUser>, String>((ref, conversationId) {
      final database = ref.watch(databaseProvider).value;
      if (database == null) {
        return Stream.value(const <ParticipantUser>[]);
      }
      return database.participantDao
          .groupParticipantsByConversationId(conversationId)
          .watchWithStream(
            eventStreams: [
              DataBaseEventBus.instance.watchUpdateParticipantStream(
                conversationIds: [conversationId],
              ),
            ],
            duration: kDefaultThrottleDuration,
          );
    });

class GroupParticipantsPage extends HookConsumerWidget {
  const GroupParticipantsPage(this.conversationState, {super.key});

  final ConversationState conversationState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final accountServer = ref.read(accountServerProvider).requireValue;
    final conversationId = conversationState.conversationId;
    final participants =
        ref.watch(_groupParticipantsProvider(conversationId)).value ??
        const <ParticipantUser>[];

    // Find current user info to check if we have group manage permission.
    // Could be null if has been removed from group.
    final currentUser = useMemoized(
      () => participants.firstWhereOrNull(
        (e) => e.userId == accountServer.userId,
      ),
      [participants],
    );

    final controller = useTextEditingController();

    final hasParticipant = ref.watch(currentConversationHasParticipantProvider);
    return Scaffold(
      backgroundColor: theme.primary,
      appBar: MixinAppBar(
        title: Text(l10n.groupParticipants),
        actions: [
          if (currentUser?.role != null)
            _ActionAddParticipants(participants: participants),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchTextField(
              hintText: l10n.settingAuthSearchHint,
              autofocus: context.textFieldAutoGainFocus,
              controller: controller,
            ),
          ),
          if (hasParticipant)
            Expanded(
              child: _ParticipantList(
                filterKeyword: controller,
                currentUser: currentUser,
                participants: participants,
              ),
            )
          else
            const SizedBox(),
        ],
      ),
    );
  }
}

class _ParticipantList extends HookConsumerWidget {
  const _ParticipantList({
    required this.filterKeyword,
    required this.participants,
    required this.currentUser,
  });

  /// The keyword to filter participants of group.
  /// Empty indicates non filter.
  final ValueListenable<TextEditingValue> filterKeyword;

  final List<ParticipantUser> participants;

  final ParticipantUser? currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyword = useValueListenable(filterKeyword).text.trim();
    final filteredParticipants = useMemoized(() {
      if (keyword.isEmpty) {
        return participants;
      }
      return participants
          .where(
            (e) =>
                (e.fullName?.toLowerCase().contains(keyword.toLowerCase()) ??
                    false) ||
                e.identityNumber.contains(keyword),
          )
          .toList();
    }, [participants, keyword]);

    return ListView.builder(
      itemCount: filteredParticipants.length,
      padding: const EdgeInsets.only(top: 8),
      itemBuilder: (context, index) => _ParticipantTile(
        participant: filteredParticipants[index],
        currentUser: currentUser,
        keyword: keyword,
      ),
    );
  }
}

class _ParticipantTile extends HookConsumerWidget {
  const _ParticipantTile({
    required this.participant,
    required this.currentUser,
    required this.keyword,
  });

  final ParticipantUser participant;

  final ParticipantUser? currentUser;

  final String keyword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return _ParticipantMenuEntry(
      participant: participant,
      currentUser: currentUser,
      child: Material(
        color: theme.primary,
        child: InkWell(
          onTap: () {
            showUserDialog(context, ref.container, participant.userId);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              children: [
                AvatarWidget(
                  size: 50,
                  avatarUrl: participant.avatarUrl,
                  userId: participant.userId,
                  name: participant.fullName,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: CustomText(
                              participant.fullName ?? '?',
                              style: TextStyle(
                                color: theme.text,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textMatchers: [
                                EmojiTextMatcher(),
                                KeyWordTextMatcher(
                                  keyword,
                                  style: TextStyle(
                                    color: theme.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          BadgesWidget(
                            isBot: participant.appId != null,
                            verified: participant.isVerified,
                            membership: participant.membership,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        participant.identityNumber,
                        style: TextStyle(
                          color: theme.secondaryText,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _RoleWidget(role: participant.role),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ParticipantMenuEntry extends HookConsumerWidget {
  const _ParticipantMenuEntry({
    required this.child,
    required this.participant,
    required this.currentUser,
  });

  final ParticipantUser participant;
  final ParticipantUser? currentUser;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final accountServer = ref.read(accountServerProvider).requireValue;
    final self = participant.userId == accountServer.userId;
    if (self) {
      return child;
    }

    return CustomContextMenuWidget(
      desktopMenuWidgetBuilder: CustomDesktopMenuWidgetBuilder(),
      menuProvider: (request) => MenusWithSeparator(
        childrens: [
          [
            MenuAction(
              image: MenuImage.icon(IconFonts.chat),
              title: l10n.groupPopMenuMessage(
                participant.fullName ?? '?',
              ),
              callback: () {
                ConversationStateNotifier.selectUser(
                  ref.container,
                  context,
                  participant.userId,
                );
              },
            ),
          ],
          if (currentUser?.role == ParticipantRole.owner)
            [
              if (participant.role != ParticipantRole.admin)
                MenuAction(
                  image: MenuImage.icon(IconFonts.manageUser),
                  title: l10n.makeGroupAdmin,
                  callback: () {
                    final conversationId = ref.read(
                      currentConversationIdProvider,
                    );
                    if (conversationId == null) return;

                    runFutureWithToast(
                      accountServer.updateParticipantRole(
                        conversationId,
                        participant.userId,
                        ParticipantRole.admin,
                      ),
                    );
                  },
                )
              else
                MenuAction(
                  image: MenuImage.icon(IconFonts.stop),
                  title: l10n.dismissAsAdmin,
                  callback: () {
                    final conversationId = ref.read(
                      currentConversationIdProvider,
                    );
                    if (conversationId == null) return;

                    runFutureWithToast(
                      accountServer.updateParticipantRole(
                        conversationId,
                        participant.userId,
                        null,
                      ),
                    );
                  },
                ),
            ],
          [
            if (currentUser?.role != null && participant.role == null ||
                currentUser?.role == ParticipantRole.owner)
              MenuAction(
                image: MenuImage.icon(IconFonts.delete),
                title: l10n.groupPopMenuRemove(
                  participant.fullName ?? '?',
                ),
                callback: () {
                  final conversationId = ref.read(
                    currentConversationIdProvider,
                  );
                  if (conversationId == null) return;

                  runFutureWithToast(
                    accountServer.removeParticipant(
                      conversationId,
                      participant.userId,
                    ),
                  );
                },
              ),
          ],
        ],
      ),
      child: child,
    );
  }
}

class _RoleWidget extends ConsumerWidget {
  const _RoleWidget({required this.role});

  final ParticipantRole? role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    switch (role) {
      case ParticipantRole.owner:
        return _RoleLabel(l10n.owner);
      case ParticipantRole.admin:
        return _RoleLabel(l10n.admin);
      case null:
        return Container(width: 0);
    }
  }
}

class _RoleLabel extends ConsumerWidget {
  const _RoleLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return Text(
      label,
      style: TextStyle(
        color: theme.secondaryText,
        fontSize: 14,
      ),
    );
  }
}

enum _ActionType { addParticipants, inviteByLink }

class _ActionAddParticipants extends HookConsumerWidget {
  const _ActionAddParticipants({required this.participants});

  final List<ParticipantUser> participants;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    return CustomPopupMenuButton(
      itemBuilder: (context) => [
        CustomPopupMenuItem(
          icon: Resources.assetsImagesContextMenuSearchUserSvg,
          title: l10n.addParticipants,
          value: _ActionType.addParticipants,
        ),
        CustomPopupMenuItem(
          icon: Resources.assetsImagesContextMenuLinkSvg,
          title: l10n.inviteToGroupViaLink,
          value: _ActionType.inviteByLink,
        ),
      ],
      onSelected: (action) async {
        switch (action) {
          case _ActionType.addParticipants:
            {
              final result = await showConversationSelector(
                context: context,
                singleSelect: false,
                title: l10n.addParticipants,
                onlyContact: true,
                maxSelect: kMaxGroupParticipants - participants.length,
              );
              if (result == null || result.isEmpty) return;

              final userIds = result.map((e) => e.userId).nonNulls.toList();
              final conversationId = ref.read(currentConversationIdProvider);
              if (conversationId == null) return;

              await runFutureWithToast(
                ref
                    .read(accountServerProvider)
                    .requireValue
                    .addParticipant(conversationId, userIds),
              );
              break;
            }
          case _ActionType.inviteByLink:
            {
              final conversationId = ref.read(currentConversationIdProvider);
              if (conversationId == null) return;

              await showGroupInviteByLinkDialog(
                context,
                conversationId: conversationId,
              );
              break;
            }
        }
      },
      icon: Resources.assetsImagesIcAddSvg,
    );
  }
}
