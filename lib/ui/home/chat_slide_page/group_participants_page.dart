import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';

import '../../../account/account_server.dart';
import '../../../db/mixin_database.dart';
import '../../../generated/l10n.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/avatar_view/avatar_view.dart';
import '../../../widgets/brightness_observer.dart';
import '../bloc/conversation_cubit.dart';

/**
 * 群组成员列表。
 */
class GroupParticipantsPage extends HookWidget {
  const GroupParticipantsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final conversationId =
        context.read<ConversationCubit>().state?.conversationId;
    assert(conversationId != null);
    if (conversationId == null) {
      return _InternalError();
    }

    final participants = context.read<AccountServer>().database.participantsDao;
    return Scaffold(
      backgroundColor: BrightnessData.themeOf(context).primary,
      appBar: MixinAppBar(
        title: Text(Localization.of(context).groupParticipants),
      ),
      body: StreamBuilder<List<ParticipantUser>>(
          stream: participants.watchParticipants(conversationId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }
            final data = snapshot.requireData;
            return ListView.builder(
                itemCount: data.length,
                itemBuilder: (BuildContext context, int index) =>
                    _ParticipantTile(participant: data[index]));
          }),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant, Key? key})
      : super(key: key);

  final ParticipantUser participant;

  @override
  Widget build(BuildContext context) => ListTile(
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
        onTap: () {
          debugPrint("on click: ${participant.fullName}");
        },
        trailing: _RoleWidget(role: participant.role),
      );
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

class _InternalError extends StatelessWidget {
  const _InternalError({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container();
}
