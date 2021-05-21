import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_app/widgets/search_text_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';

import '../../../account/account_server.dart';
import '../../../db/mixin_database.dart';
import '../../../generated/l10n.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/brightness_observer.dart';
import '../../../widgets/menu.dart';
import '../../../utils/hook.dart';
import '../bloc/conversation_cubit.dart';

/**
 * The participants of group.
 */
class GroupParticipantsPage extends HookWidget {
  const GroupParticipantsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final conversationId =
        context.read<ConversationCubit>().state?.conversationId;
    assert(conversationId != null);
    if (conversationId == null) {
      return _InternalErrorLayout();
    }
    final filterCubit = useBloc(() => _ParticipantFilterCubit());
    return Scaffold(
      backgroundColor: BrightnessData.themeOf(context).primary,
      appBar: MixinAppBar(
        title: Text(Localization.of(context).groupParticipants),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchTextField(
              onChanged: (text) => filterCubit.emit(text),
            ),
          ),
          BlocProvider.value(
            value: filterCubit,
            child: Expanded(child: _ParticipantList(conversationId)),
          ),
        ],
      ),
    );
  }
}

// Type parameter <String?> : The key to filter Participants.
class _ParticipantFilterCubit extends Cubit<String> {
  _ParticipantFilterCubit() : super("");
}

class _ParticipantList extends HookWidget {
  const _ParticipantList(this.conversationId, {Key? key}) : super(key: key);

  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final participants = useStream(useMemoized(() {
      final dao = context.read<AccountServer>().database.participantsDao;
      return dao.watchParticipants(conversationId);
    }));
    if (!participants.hasData) {
      return _InternalErrorLayout();
    }
    final participantList =
        List.of(participants.data ?? const <ParticipantUser>[]);

    final me = participantList
        .firstWhere((e) => e.userId == context.read<AccountServer>().userId);

    final keyword = useBlocState<_ParticipantFilterCubit, String>().trim();
    if (keyword.isNotEmpty) {
      participantList.retainWhere((e) =>
          (e.fullName?.contains(keyword) ?? false) ||
          e.identityNumber.contains(keyword));
    }

    return ListView.builder(
      itemCount: participantList.length,
      itemBuilder: (context, index) => _ParticipantTile(
        participant: participantList[index],
        me: me,
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile(
      {required this.participant, Key? key, required this.me})
      : super(key: key);

  final ParticipantUser participant;

  final ParticipantUser me;

  @override
  Widget build(BuildContext context) {
    final self = participant.userId == me.userId;
    return _ParticipantMenuEntry(
      participant: participant,
      me: me,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: AvatarWidget(
          size: 50,
          avatarUrl: participant.avatarUrl,
          userId: participant.userId,
          name: participant.fullName ?? "?",
        ),
        title: Text(
          participant.fullName ?? "?",
          style: Theme.of(context).textTheme.bodyText1,
        ),
        subtitle: Text(
          participant.identityNumber,
          style: Theme.of(context).textTheme.caption,
        ),
        onTap: () {
          // skip self
          if (self) {
            return;
          }
          context.read<ConversationCubit>().selectUser(participant.userId);
        },
        onLongPress: () {},
        trailing: _RoleWidget(role: participant.role),
      ),
    );
  }
}

class _ParticipantMenuEntry extends StatelessWidget {
  final ParticipantUser participant;
  final ParticipantUser me;

  final Widget child;

  const _ParticipantMenuEntry({
    Key? key,
    required this.child,
    required this.participant,
    required this.me,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final self = participant.userId == context.read<AccountServer>().userId;
    if (self) {
      return child;
    }

    return ContextMenuPortalEntry(
      child: child,
      buildMenus: () {
        final menus = [
          ContextMenu(
            title: Localization.of(context)
                .groupPopMenuMessage(participant.fullName ?? "?"),
            onTap: () {
              context.read<ConversationCubit>().selectUser(participant.userId);
            },
          ),
        ];
        if (me.role == ParticipantRole.owner) {
          if (participant.role != ParticipantRole.admin) {
            menus.add(
              ContextMenu(
                title: Localization.of(context).groupPopMenuMakeAdmin,
                onTap: () {
                  // TODO make admin
                },
              ),
            );
          } else {
            menus.add(ContextMenu(
              title: Localization.of(context).groupPopMenuDismissAdmin,
              onTap: () {
                // TODO remove admin
              },
            ));
          }
        }

        if (me.role != null && participant.role == null ||
            me.role == ParticipantRole.owner) {
          menus.add(ContextMenu(
            title: Localization.of(context)
                .groupPopMenuRemoveParticipants(participant.fullName ?? "?"),
            onTap: () {
              // TODO remove participant.
            },
          ));
        }
        return menus;
      },
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
        return _RoleLabel(Localization.of(context).groupOwner);
      case ParticipantRole.admin:
        return _RoleLabel(Localization.of(context).groupAdmin);
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
        style: Theme.of(context).textTheme.caption,
      );
}

// TODO error layout.
class _InternalErrorLayout extends StatelessWidget {
  const _InternalErrorLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container();
}
