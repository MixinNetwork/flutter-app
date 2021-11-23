import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../constants/resources.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/cell.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/more_extended_text.dart';
import '../../../widgets/toast.dart';
import '../../../widgets/user/user_dialog.dart';
import '../../../widgets/user_selector/conversation_selector.dart';
import '../bloc/conversation_cubit.dart';
import '../bloc/message_bloc.dart';
import '../chat/chat_bar.dart';
import '../chat/chat_page.dart';
import '../conversation_page.dart';

class ChatInfoPage extends HookWidget {
  const ChatInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final conversationId = useMemoized(() {
      final conversationId =
          context.read<ConversationCubit>().state?.conversationId;
      assert(conversationId != null);
      return conversationId!;
    });

    final conversation = useBlocState<ConversationCubit, ConversationState?>(
      when: (state) =>
          state?.isLoaded == true && state?.conversationId == conversationId,
    )!;

    final accountServer = context.accountServer;
    final userParticipant = useStream<Participant?>(
      useMemoized(
        () => accountServer.database.participantDao
            .participantById(conversationId, accountServer.userId)
            .watchSingleOrNullThrottle(),
        [conversationId, accountServer.userId],
      ),
      initialData: null,
    ).data;

    useEffect(() {
      if (conversation.isGroup == true) {
        accountServer.refreshGroup(conversationId);
      } else if (conversation.userId != null) {
        accountServer.refreshUsers([conversation.userId!], force: true);
      }
    }, [conversationId]);

    final announcement = useStream<String?>(
            useMemoized(() => context.database.conversationDao
                .announcement(conversationId)
                .watchSingleThrottle()),
            initialData: null)
        .data;
    if (!conversation.isLoaded) return const SizedBox();

    final isGroupConversation = conversation.isGroup!;
    final muting = conversation.conversation?.isMute == true;
    final isOwnerOrAdmin = userParticipant?.role == ParticipantRole.owner ||
        userParticipant?.role == ParticipantRole.admin;

    return Scaffold(
      appBar: MixinAppBar(
        actions: [
          if (ModalRoute.of(context)?.canPop != true)
            ActionButton(
              name: Resources.assetsImagesIcCloseSvg,
              color: context.theme.icon,
              onTap: () => context.read<ChatSideCubit>().onPopPage(),
            ),
        ],
        backgroundColor: context.theme.popUp,
      ),
      backgroundColor: context.theme.popUp,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            ConversationAvatar(
              conversationState: conversation,
              size: 90,
            ),
            const SizedBox(height: 10),
            ConversationName(
              conversationState: conversation,
              fontSize: 18,
              overflow: false,
            ),
            const SizedBox(height: 4),
            ConversationIDOrCount(
              conversationState: conversation,
              fontSize: 12,
            ),
            _AddToContactsButton(conversation),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 36),
              child: ConversationBio(
                conversationId: conversationId,
                userId: conversation.userId,
                isGroup: conversation.isGroup!,
              ),
            ),
            const SizedBox(height: 32),
            if (isGroupConversation)
              CellGroup(
                child: CellItem(
                  title: Text(
                    context.l10n.groupParticipants,
                  ),
                  onTap: () => context
                      .read<ChatSideCubit>()
                      .pushPage(ChatSideCubit.participants),
                ),
              ),
            if (!isGroupConversation)
              CellGroup(
                child: CellItem(
                  title: Text(context.l10n.shareContact),
                  onTap: () async {
                    final result = await showConversationSelector(
                      context: context,
                      singleSelect: true,
                      title: context.l10n.shareContact,
                      onlyContact: false,
                    );

                    if (result == null || result.isEmpty) return;
                    final conversationId = result[0].conversationId;

                    await runFutureWithToast(
                        context,
                        accountServer.sendContactMessage(
                          conversation.userId!,
                          conversation.name!,
                          result[0].encryptCategory!,
                          conversationId: conversationId,
                          recipientId: result[0].userId,
                        ));
                  },
                ),
              ),
            CellGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CellItem(
                    title: Text(context.l10n.sharedMedia),
                    onTap: () => context
                        .read<ChatSideCubit>()
                        .pushPage(ChatSideCubit.sharedMedia),
                  ),
                  CellItem(
                    title: Text(
                      context.l10n.searchMessageHistory,
                      maxLines: 1,
                    ),
                    onTap: () => context
                        .read<ChatSideCubit>()
                        .pushPage(ChatSideCubit.searchMessageHistory),
                  ),
                ],
              ),
            ),
            if (isGroupConversation && isOwnerOrAdmin)
              CellGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Builder(builder: (context) {
                      final announcementTitle = announcement?.isEmpty ?? true
                          ? context.l10n.addAnnouncement
                          : context.l10n.editAnnouncement;
                      return CellItem(
                        title: Text(announcementTitle),
                        onTap: () async {
                          final result = await showMixinDialog<String>(
                            context: context,
                            child: EditDialog(
                              title: Text(announcementTitle),
                              editText: announcement ?? '',
                            ),
                          );
                          if (result == null) return;

                          await runFutureWithToast(
                            context,
                            context.accountServer.editGroup(
                              conversationId,
                              announcement: result,
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            CellGroup(
              child: Column(
                children: [
                  CellItem(
                    title:
                        Text(muting ? context.l10n.unMute : context.l10n.muted),
                    description: muting
                        ? Text(
                            DateFormat('yyyy/MM/dd, hh:mm a').format(
                                conversation.conversation!.validMuteUntil!
                                    .toLocal()),
                            style: TextStyle(
                              color: context.theme.secondaryText,
                              fontSize: 14,
                            ),
                          )
                        : null,
                    trailing: null,
                    onTap: () async {
                      final isGroup = conversation.isGroup ?? false;
                      if (muting) {
                        await runFutureWithToast(
                          context,
                          context.accountServer.unMuteConversation(
                            conversationId: isGroup ? conversationId : null,
                            userId: isGroup ? null : conversation.userId,
                          ),
                        );
                        return;
                      }

                      final result = await showMixinDialog<int?>(
                          context: context, child: const MuteDialog());
                      if (result == null) return;

                      await runFutureWithToast(
                          context,
                          context.accountServer.muteConversation(
                            result,
                            conversationId: isGroup ? conversationId : null,
                            userId: isGroup ? null : conversation.userId,
                          ));
                    },
                  ),
                  if (!isGroupConversation ||
                      (isGroupConversation && isOwnerOrAdmin))
                    CellItem(
                      title: Text(context.l10n.editName),
                      trailing: null,
                      onTap: () async {
                        final name = await showMixinDialog<String>(
                          context: context,
                          child: EditDialog(
                            editText: conversation.name ?? '',
                            title: Text(context.l10n.editName),
                            hintText: context.l10n.conversationName,
                            positiveAction: context.l10n.change,
                          ),
                        );
                        if (name?.isEmpty ?? true) return;

                        await runFutureWithToast(
                          context,
                          isGroupConversation
                              ? accountServer.editGroup(
                                  conversation.conversationId,
                                  name: name,
                                )
                              : accountServer.editContactName(
                                  conversation.userId!, name!),
                        );
                      },
                    ),
                ],
              ),
            ),
            if (conversation.app?.creatorId != null)
              CellGroup(
                child: CellItem(
                  title: Text(context.l10n.developer),
                  trailing: null,
                  onTap: () =>
                      showUserDialog(context, conversation.app?.creatorId),
                ),
              ),
            CellGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (conversation.relationship == UserRelationship.blocking)
                    CellItem(
                      title: Text(context.l10n.unblock),
                      color: context.theme.red,
                      trailing: null,
                      onTap: () async {
                        final result = await showConfirmMixinDialog(
                          context,
                          context.l10n.unblock,
                        );
                        if (!result) return;

                        await runFutureWithToast(
                          context,
                          accountServer.unblockUser(conversation.userId!),
                        );
                      },
                    ),
                  if (!isGroupConversation && !conversation.isStranger!)
                    Builder(builder: (context) {
                      final title = conversation.isBot!
                          ? context.l10n.removeBot
                          : context.l10n.removeContact;
                      return CellItem(
                        title: Text(title),
                        color: context.theme.red,
                        trailing: null,
                        onTap: () async {
                          final result = await showConfirmMixinDialog(
                            context,
                            title,
                          );
                          if (!result) return;

                          await runFutureWithToast(
                            context,
                            accountServer.removeUser(conversation.userId!),
                          );
                        },
                      );
                    }),
                  if (conversation.isStranger!)
                    CellItem(
                      title: Text(context.l10n.block),
                      color: context.theme.red,
                      trailing: null,
                      onTap: () async {
                        final result = await showConfirmMixinDialog(
                          context,
                          context.l10n.block,
                        );
                        if (!result) return;

                        await runFutureWithToast(
                          context,
                          accountServer.blockUser(conversation.userId!),
                        );
                      },
                    ),
                  CellItem(
                    title: Text(context.l10n.clearChat),
                    color: context.theme.red,
                    trailing: null,
                    onTap: () async {
                      final result = await showConfirmMixinDialog(
                        context,
                        context.l10n.clearChat,
                      );
                      if (!result) return;

                      await accountServer.database.messageDao
                          .deleteMessageByConversationId(conversationId);
                      context.read<MessageBloc>().reload();
                    },
                  ),
                  if (conversation.isGroup!)
                    if (userParticipant != null)
                      CellItem(
                        title: Text(context.l10n.exitGroup),
                        color: context.theme.red,
                        trailing: null,
                        onTap: () async {
                          final result = await showConfirmMixinDialog(
                            context,
                            context.l10n.exitGroup,
                          );
                          if (!result) return;

                          await runFutureWithToast(
                            context,
                            accountServer.exitGroup(conversationId),
                          );
                        },
                      )
                    else
                      CellItem(
                        title: Text(context.l10n.deleteGroup),
                        color: context.theme.red,
                        trailing: null,
                        onTap: () async {
                          final result = await showConfirmMixinDialog(
                            context,
                            context.l10n.deleteGroup,
                          );
                          if (!result) return;

                          await context.database.messageDao
                              .deleteMessageByConversationId(conversationId);
                          await context.database.conversationDao
                              .deleteConversation(
                            conversationId,
                          );
                          if (context
                                  .read<ConversationCubit>()
                                  .state
                                  ?.conversationId ==
                              conversationId) {
                            context.read<ConversationCubit>().unselected();
                          }
                        },
                      ),
                ],
              ),
            ),
            if (!isGroupConversation)
              CellGroup(
                child: CellItem(
                  title: Text(context.l10n.report),
                  color: context.theme.red,
                  trailing: null,
                  onTap: () async {
                    final result = await showConfirmMixinDialog(
                      context,
                      context.l10n.reportWarning,
                    );
                    if (!result) return;

                    await runFutureWithToast(
                      context,
                      accountServer.report(conversationId),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ConversationBio extends HookWidget {
  const ConversationBio({
    Key? key,
    this.fontSize = 14,
    required this.conversationId,
    required this.userId,
    required this.isGroup,
  }) : super(key: key);

  final double fontSize;
  final String conversationId;
  final String? userId;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    final textStream = useMemoized(() {
      final database = context.database;
      if (isGroup) {
        return database.conversationDao
            .announcement(conversationId)
            .watchSingleThrottle();
      }
      return database.userDao.biography(userId!).watchSingleThrottle();
    }, [
      conversationId,
      userId,
      isGroup,
    ]);

    final text = useStream(textStream, initialData: '').data!;
    if (text.isEmpty) return const SizedBox();

    return MoreExtendedText(
      text,
      style: TextStyle(
        color: context.theme.text,
        fontSize: fontSize,
      ),
    );
  }
}

///
/// Button to add strange to contacts.
///
/// if conversation is not stranger, show nothing.
///
class _AddToContactsButton extends StatelessWidget {
  _AddToContactsButton(this.conversation, {Key? key})
      : assert(conversation.isLoaded),
        super(key: key);
  final ConversationState conversation;

  @override
  Widget build(BuildContext context) => AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: conversation.isStranger!
            ? Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: context.theme.statusBackground,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    final username = conversation.user?.fullName ??
                        conversation.conversation?.validName;
                    assert(username != null,
                        'ContactsAdd: username should not be null.');
                    assert(conversation.isGroup != true,
                        'ContactsAdd conversation should not be a group.');
                    runFutureWithToast(
                        context,
                        context.accountServer.addUser(
                          conversation.userId!,
                          username,
                        ));
                  },
                  child: Text(
                    conversation.isBot!
                        ? context.l10n.conversationAddBot
                        : context.l10n.conversationAddContact,
                    style: TextStyle(fontSize: 12, color: context.theme.accent),
                  ),
                ),
              )
            : const SizedBox(height: 0),
      );
}
