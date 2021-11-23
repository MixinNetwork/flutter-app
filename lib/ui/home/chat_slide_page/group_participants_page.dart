import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../constants/resources.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/extension/extension.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/high_light_text.dart';
import '../../../widgets/menu.dart';
import '../../../widgets/search_text_field.dart';
import '../../../widgets/toast.dart';
import '../../../widgets/user/user_dialog.dart';
import '../../../widgets/user_selector/conversation_selector.dart';
import '../bloc/conversation_cubit.dart';
import '../conversation_page.dart';
import 'group_invite/group_invite_dialog.dart';

/// The participants of group.
class GroupParticipantsPage extends HookWidget {
  const GroupParticipantsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final conversationId = useMemoized(() {
      final conversationId =
          context.read<ConversationCubit>().state?.conversationId;
      assert(conversationId != null);
      return conversationId!;
    });

    final participants = useStream(useMemoized(() {
          final dao = context.database.participantDao;
          return dao
              .groupParticipantsByConversationId(conversationId)
              .watchThrottle();
        }, [conversationId])).data ??
        const <ParticipantUser>[];

    // Find current user info to check if we have group manage permission.
    // Could be null if has been removed from group.
    final currentUser = useMemoized(
      () => participants
          .firstWhereOrNull((e) => e.userId == context.accountServer.userId),
      [participants],
    );

    final controller = useTextEditingController();

    return Scaffold(
      backgroundColor: context.theme.primary,
      appBar: MixinAppBar(
        title: Text(context.l10n.groupParticipants),
        actions: [
          if (currentUser?.role != null)
            _ActionAddParticipants(participants: participants)
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchTextField(
              hintText: context.l10n.groupSearchParticipants,
              autofocus: context.textFieldAutoGainFocus,
              controller: controller,
            ),
          ),
          Expanded(
            child: _ParticipantList(
              filterKeyword: controller,
              currentUser: currentUser,
              participants: participants,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantList extends HookWidget {
  const _ParticipantList({
    Key? key,
    required this.filterKeyword,
    required this.participants,
    required this.currentUser,
  }) : super(key: key);

  /// The keyword to filter participants of group.
  /// Empty indicates non filter.
  final ValueListenable<TextEditingValue> filterKeyword;

  final List<ParticipantUser> participants;

  final ParticipantUser? currentUser;

  @override
  Widget build(BuildContext context) {
    final keyword = useValueListenable(filterKeyword).text.trim();
    final filteredParticipants = useMemoized(() {
      if (keyword.isEmpty) {
        return participants;
      }
      return participants
          .where((e) =>
              (e.fullName?.toLowerCase().contains(keyword.toLowerCase()) ??
                  false) ||
              e.identityNumber.contains(keyword))
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

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.participant,
    Key? key,
    required this.currentUser,
    required this.keyword,
  }) : super(key: key);

  final ParticipantUser participant;

  final ParticipantUser? currentUser;

  final String keyword;

  @override
  Widget build(BuildContext context) => _ParticipantMenuEntry(
        participant: participant,
        currentUser: currentUser,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          leading: AvatarWidget(
            size: 50,
            avatarUrl: participant.avatarUrl,
            userId: participant.userId,
            name: participant.fullName ?? '?',
          ),
          title: Row(
            children: [
              Flexible(
                child: HighlightText(
                  participant.fullName ?? '?',
                  style: TextStyle(
                    color: context.theme.text,
                    fontSize: 16,
                  ),
                  highlightTextSpans: [
                    HighlightTextSpan(
                      keyword,
                      style: TextStyle(
                        color: context.theme.accent,
                      ),
                    )
                  ],
                ),
              ),
              VerifiedOrBotWidget(
                isBot: participant.appId != null,
                verified: participant.isVerified,
              ),
            ],
          ),
          onTap: () {
            showUserDialog(context, participant.userId);
          },
          trailing: _RoleWidget(role: participant.role),
        ),
      );
}

class _ParticipantMenuEntry extends StatelessWidget {
  const _ParticipantMenuEntry({
    Key? key,
    required this.child,
    required this.participant,
    required this.currentUser,
  }) : super(key: key);

  final ParticipantUser participant;
  final ParticipantUser? currentUser;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final self = participant.userId == context.accountServer.userId;
    if (self) {
      return child;
    }

    return ContextMenuPortalEntry(
      buildMenus: () {
        final menus = [
          ContextMenu(
            title:
                context.l10n.groupPopMenuMessage(participant.fullName ?? '?'),
            onTap: () {
              ConversationCubit.selectUser(
                context,
                participant.userId,
              );
            },
          ),
        ];
        if (currentUser?.role == ParticipantRole.owner) {
          if (participant.role != ParticipantRole.admin) {
            menus.add(ContextMenu(
              title: context.l10n.groupPopMenuMakeAdmin,
              onTap: () => runFutureWithToast(
                context,
                context.accountServer.updateParticipantRole(
                    context.read<ConversationCubit>().state!.conversationId,
                    participant.userId,
                    ParticipantRole.admin),
              ),
            ));
          } else {
            menus.add(ContextMenu(
              title: context.l10n.groupPopMenuDismissAdmin,
              onTap: () => runFutureWithToast(
                  context,
                  context.accountServer.updateParticipantRole(
                      context.read<ConversationCubit>().state!.conversationId,
                      participant.userId,
                      null)),
            ));
          }
        }

        if (currentUser?.role != null && participant.role == null ||
            currentUser?.role == ParticipantRole.owner) {
          menus.add(ContextMenu(
            isDestructiveAction: true,
            title: context.l10n
                .groupPopMenuRemoveParticipants(participant.fullName ?? '?'),
            onTap: () => runFutureWithToast(
                context,
                context.accountServer.removeParticipant(
                    context.read<ConversationCubit>().state!.conversationId,
                    participant.userId)),
          ));
        }
        return menus;
      },
      child: child,
    );
  }
}

class _RoleWidget extends StatelessWidget {
  const _RoleWidget({Key? key, required this.role}) : super(key: key);
  final ParticipantRole? role;

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case ParticipantRole.owner:
        return _RoleLabel(context.l10n.groupOwner);
      case ParticipantRole.admin:
        return _RoleLabel(context.l10n.groupAdmin);
      default:
        return Container(width: 0);
    }
  }
}

class _RoleLabel extends StatelessWidget {
  const _RoleLabel(this.label, {Key? key}) : super(key: key);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          color: context.theme.secondaryText,
          fontSize: 14,
        ),
      );
}

class _ActionAddParticipants extends StatelessWidget {
  const _ActionAddParticipants({
    Key? key,
    required this.participants,
  }) : super(key: key);

  final List<ParticipantUser> participants;

  @override
  Widget build(BuildContext context) => ContextMenuPortalEntry(
        buildMenus: () => [
          ContextMenu(
            title: context.l10n.groupAdd,
            onTap: () async {
              final result = await showConversationSelector(
                context: context,
                singleSelect: false,
                title: context.l10n.groupAdd,
                onlyContact: true,
              );
              if (result == null || result.isEmpty) return;

              final userIds = [
                context.accountServer.userId,
                ...result.where((e) => e.userId != null).map(
                      (e) => e.userId!,
                    )
              ];
              final conversationId =
                  context.read<ConversationCubit>().state?.conversationId;
              assert(conversationId != null);
              await runFutureWithToast(
                context,
                Future.wait(userIds.map((userId) => context.accountServer
                    .addParticipant(conversationId!, [userId]))),
              );
            },
          ),
          ContextMenu(
            title: context.l10n.groupInvite,
            onTap: () {
              final conversationCubit = context.read<ConversationCubit>().state;
              assert(conversationCubit != null);
              showGroupInviteByLinkDialog(context,
                  conversationId: conversationCubit!.conversationId);
            },
          ),
        ],
        child: Builder(
            builder: (context) => ActionButton(
                  name: Resources.assetsImagesIcAddSvg,
                  color: context.theme.icon,
                  onTapUp: (event) =>
                      context.sendMenuPosition(event.globalPosition),
                )),
      );
}
