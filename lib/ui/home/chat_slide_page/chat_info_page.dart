import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/db/extension/conversation.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/message_bloc.dart';
import 'package:flutter_app/ui/home/chat_page.dart';
import 'package:flutter_app/ui/home/conversation_page.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator_cubit.dart';
import 'package:flutter_app/utils/hook.dart';
import 'package:flutter_app/widgets/action_button.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:flutter_app/widgets/dialog.dart';
import 'package:flutter_app/widgets/user_selector/conversation_selector.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/utils/list_utils.dart';
import 'package:tuple/tuple.dart';

import '../../../widgets/brightness_observer.dart';
import '../../../widgets/cell.dart';
import '../../../widgets/chat_bar.dart';
import '../../../widgets/toast.dart';

class ChatInfoPage extends HookWidget {
  const ChatInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final conversation = useBlocState<ConversationCubit, ConversationItem?>(
        when: (state) => state != null)!;

    final isGroupConversation = conversation.isGroupConversation;
    final muting = conversation.muteUntil?.isAfter(DateTime.now()) == true;

    final accountServer = context.read<AccountServer>();
    final userParticipant = useStream<Participant?>(
      useMemoized(
        () => accountServer.database.conversationDao
            .participantById(conversation.conversationId, accountServer.userId)
            .watchSingleOrNull(),
        [conversation.conversationId, accountServer.userId],
      ),
      initialData: null,
    ).data;

    final announcement = useStream<String?>(
            useMemoized(() => context
                .read<AccountServer>()
                .database
                .conversationDao
                .announcement(conversation.conversationId)
                .watchSingle()),
            initialData: null)
        .data;

    return Column(
      children: [
        MixinAppBar(
          actions: [
            ActionButton(
              name: Resources.assetsImagesIcCloseSvg,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 8),
                const ConversationAvatar(size: 90),
                const SizedBox(height: 10),
                const ConversationName(fontSize: 18),
                const SizedBox(height: 4),
                const ConversationIDOrCount(fontSize: 12),
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 36),
                  child: const ConversationBio(fontSize: 14),
                ),
                const SizedBox(height: 32),
                if (!isGroupConversation)
                  CellGroup(
                    child: CellItem(
                      title: Localization.of(context).shareContact,
                      onTap: () async {
                        final result = await showConversationSelector(
                          context: context,
                          singleSelect: true,
                          title: Localization.of(context).shareContact,
                          onlyContact: false,
                        );

                        if (result.isEmpty) return;
                        final conversationId = result[0].item1;

                        await accountServer.sendContactMessage(
                          conversation.ownerId!,
                          conversation.name ?? '',
                          conversationId: conversationId,
                          recipientId: conversationId,
                        );
                      },
                    ),
                  ),
                CellGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CellItem(
                        title: Localization.of(context).sharedMedia,
                        onTap: () {
                          // todo
                        },
                      ),
                      CellItem(
                        title: Localization.of(context).searchMessageHistory,
                        onTap: () => context
                            .read<ChatSideCubit>()
                            .pushPage(ChatSideCubit.searchMessageHistory),
                      ),
                    ],
                  ),
                ),
                if (conversation.isGroupConversation &&
                    (userParticipant?.role == ParticipantRole.owner ||
                        userParticipant?.role == ParticipantRole.admin))
                  CellGroup(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Builder(builder: (context) {
                          final announcementTitle =
                              announcement?.isEmpty ?? true
                                  ? Localization.of(context).addAnnouncement
                                  : Localization.of(context).editAnnouncement;
                          return CellItem(
                            title: announcementTitle,
                            onTap: () async {
                              final result = await showMixinDialog<String>(
                                context: context,
                                child: EditDialog(
                                  title: Text(announcementTitle),
                                ),
                              );
                              if (result == null) return;

                              await runFutureWithToast(
                                context,
                                context
                                    .read<AccountServer>()
                                    .editGroupAnnouncement(
                                      conversation.conversationId,
                                      result,
                                    ),
                              );
                            },
                          );
                        }),
                        if (!isGroupConversation)
                          CellItem(
                            title: Localization.of(context).editName,
                            onTap: () async {
                              final name = await showMixinDialog<String>(
                                context: context,
                                child: EditDialog(
                                  editText: conversation.name ?? '',
                                  title:
                                      Text(Localization.of(context).editName),
                                  hintText:
                                      Localization.of(context).conversationName,
                                ),
                              );
                              if (name?.isEmpty ?? true) return;

                              await runFutureWithToast(
                                context,
                                accountServer.editContactName(
                                    conversation.ownerId!, name!),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                CellGroup(
                  child: Column(
                    children: [
                      CellItem(
                        title: muting
                            ? Localization.of(context).unMute
                            : Localization.of(context).muted,
                        description: muting
                            ? Text(
                                DateFormat('yyyy/MM/dd, hh:mm a')
                                    .format(conversation.muteUntil!),
                                style: TextStyle(
                                  color: BrightnessData.themeOf(context)
                                      .secondaryText,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                        trailing: null,
                        onTap: () async {
                          if (muting)
                            return await runFutureWithToast(
                                context,
                                context
                                    .read<AccountServer>()
                                    .unMuteUser(conversation.ownerId!));

                          final result = await showMixinDialog<int?>(
                              context: context, child: const MuteDialog());
                          if (result == null) return;

                          await runFutureWithToast(
                              context,
                              context
                                  .read<AccountServer>()
                                  .muteUser(conversation.ownerId!, result));
                        },
                      ),
                    ],
                  ),
                ),
                CellGroup(
                  child: CellItem(
                    title: Localization.of(context).circles,
                    description: const _CircleNames(),
                    onTap: () => context.read<ChatSideCubit>().pushPage(
                          ChatSideCubit.circles,
                          arguments: Tuple2<String, String>(
                            conversation.validName,
                            conversation.conversationId,
                          ),
                        ),
                  ),
                ),
                CellGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (conversation.relationship ==
                          UserRelationship.blocking)
                        CellItem(
                          title: Localization.of(context).unblock,
                          color: BrightnessData.themeOf(context).red,
                          trailing: null,
                          onTap: () async {
                            final result = await showConfirmMixinDialog(
                              context,
                              Localization.of(context).unblock,
                            );
                            if (!result) return;

                            await runFutureWithToast(
                              context,
                              accountServer.unblockUser(conversation.ownerId!),
                            );
                          },
                        ),
                      if (conversation.relationship == UserRelationship.friend)
                        Builder(builder: (context) {
                          final title = conversation.isBotConversation
                              ? Localization.of(context).removeBot
                              : Localization.of(context).removeContact;
                          return CellItem(
                            title: title,
                            color: BrightnessData.themeOf(context).red,
                            trailing: null,
                            onTap: () async {
                              final result = await showConfirmMixinDialog(
                                context,
                                title,
                              );
                              if (!result) return;

                              await runFutureWithToast(
                                context,
                                accountServer.removeUser(conversation.ownerId!),
                              );
                            },
                          );
                        }),
                      if (conversation.isStrangerConversation)
                        CellItem(
                          title: Localization.of(context).block,
                          color: BrightnessData.themeOf(context).red,
                          trailing: null,
                          onTap: () async {
                            final result = await showConfirmMixinDialog(
                              context,
                              Localization.of(context).block,
                            );
                            if (!result) return;

                            await runFutureWithToast(
                              context,
                              accountServer.blockUser(conversation.ownerId!),
                            );
                          },
                        ),
                      CellItem(
                        title: Localization.of(context).clearChat,
                        color: BrightnessData.themeOf(context).red,
                        trailing: null,
                        onTap: () async {
                          final result = await showConfirmMixinDialog(
                            context,
                            Localization.of(context).clearChat,
                          );
                          if (!result) return;

                          await accountServer.database.messagesDao
                              .deleteMessageByConversationId(
                                  conversation.conversationId);
                          context.read<MessageBloc>().reload();
                        },
                      ),
                      if (conversation.isGroupConversation)
                        if (userParticipant != null)
                          CellItem(
                            title: Localization.of(context).exitGroup,
                            color: BrightnessData.themeOf(context).red,
                            trailing: null,
                            onTap: () async {
                              final result = await showConfirmMixinDialog(
                                context,
                                Localization.of(context).exitGroup,
                              );
                              if (!result) return;

                              await runFutureWithToast(
                                context,
                                accountServer
                                    .exitGroup(conversation.conversationId),
                              );
                            },
                          )
                        else
                          CellItem(
                            title: Localization.of(context).deleteGroup,
                            color: BrightnessData.themeOf(context).red,
                            trailing: null,
                            onTap: () async {
                              final result = await showConfirmMixinDialog(
                                context,
                                Localization.of(context).deleteGroup,
                              );
                              if (!result) return;

                              await context
                                  .read<AccountServer>()
                                  .database
                                  .messagesDao
                                  .deleteMessageByConversationId(
                                      conversation.conversationId);
                              await context
                                  .read<AccountServer>()
                                  .database
                                  .conversationDao
                                  .deleteConversation(
                                    conversation.conversationId,
                                  );
                              if (context
                                      .read<ConversationCubit>()
                                      .state
                                      ?.conversationId ==
                                  conversation.conversationId) {
                                context.read<ConversationCubit>().emit(null);
                                context
                                    .read<ResponsiveNavigatorCubit>()
                                    .clear();
                              }
                            },
                          ),
                    ],
                  ),
                ),
                if (!isGroupConversation)
                  CellGroup(
                    child: CellItem(
                      title: Localization.of(context).report,
                      color: BrightnessData.themeOf(context).red,
                      trailing: null,
                      onTap: () async {
                        final result = await showConfirmMixinDialog(
                          context,
                          Localization.of(context).reportWarning,
                        );
                        if (!result) return;

                        await runFutureWithToast(
                          context,
                          accountServer.report(conversation.conversationId),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleNames extends HookWidget {
  const _CircleNames();

  @override
  Widget build(BuildContext context) {
    final conversationId =
        useBlocStateConverter<ConversationCubit, ConversationItem?, String?>(
      converter: (state) => state?.conversationId,
      when: (conversationId) => conversationId != null,
    );

    final circleNames = useStream<List<String>>(
      useMemoized(
        () => context
            .read<AccountServer>()
            .database
            .circlesDao
            .circlesNameByConversationId(conversationId ?? '')
            .watch()
            .where((event) => event.isNotEmpty),
        [conversationId],
      ),
      initialData: [],
    ).data as List<String>;

    if (circleNames.isEmpty) return const SizedBox();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: circleNames
          .map(
            (e) => Container(
              decoration: ShapeDecoration(
                shape: StadiumBorder(
                  side: BorderSide(
                    color: BrightnessData.themeOf(context).secondaryText,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                e,
                style: TextStyle(
                  color: BrightnessData.themeOf(context).secondaryText,
                ),
              ),
            ),
          )
          .cast<Widget>()
          .toList()
          .joinList(const SizedBox(width: 8)),
    );
  }
}

class ConversationBio extends HookWidget {
  const ConversationBio({
    Key? key,
    this.fontSize = 14,
  }) : super(key: key);

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final conversation = useBlocState<ConversationCubit, ConversationItem?>(
        when: (state) => state != null)!;

    final textStream = useMemoized(() {
      final database = context.read<AccountServer>().database;
      if (conversation.isGroupConversation)
        return database.conversationDao
            .announcement(conversation.conversationId)
            .watchSingle();
      return database.userDao
          .biography(conversation.ownerIdentityNumber)
          .watchSingle();
    });

    final snapshot = useStream(textStream, initialData: '');
    if (snapshot.data?.isEmpty == true) return const SizedBox();

    return Text(
      snapshot.data!,
      style: TextStyle(
        color: BrightnessData.themeOf(context).text,
        fontSize: fontSize,
      ),
    );
  }
}
