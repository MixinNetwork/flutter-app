import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../constants/resources.dart';
import '../../../db/database_event_bus.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/logger.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/cell.dart';
import '../../../widgets/conversation/mute_dialog.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/menu.dart';
import '../../../widgets/more_extended_text.dart';
import '../../../widgets/toast.dart';
import '../../../widgets/user/user_dialog.dart';
import '../../../widgets/user_selector/conversation_selector.dart';
import '../../provider/conversation_provider.dart';
import '../bloc/message_bloc.dart';
import '../chat/chat_bar.dart';
import '../chat/chat_page.dart';
import 'shared_apps_page.dart';

class ChatInfoPage extends HookConsumerWidget {
  const ChatInfoPage(
    this.conversationState, {
    super.key,
  });

  final ConversationState conversationState;

  String get conversationId => conversationState.conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createdAt = useMemoized(() {
      final item = conversationState.conversation;
      if (item == null) return null;
      if (!item.isGroupConversation) return null;

      return item.createdAt;
    });

    final accountServer = context.accountServer;

    final userParticipant = conversationState.participant;

    useEffect(() {
      accountServer.refreshConversation(conversationId);
    }, [conversationId]);

    final userId = conversationState.userId;

    useEffect(() {
      if (conversationState.isGroup == true) return;
      if (userId == null) return;

      accountServer.refreshUsers([userId], force: true);
    }, [userId]);

    final announcement = useMemoizedStream<String?>(
      () => context.database.conversationDao
          .announcement(conversationId)
          .watchSingleWithStream(
        eventStreams: [
          DataBaseEventBus.instance
              .watchUpdateConversationStream([conversationId])
        ],
        duration: kVerySlowThrottleDuration,
      ),
      keys: [conversationId],
    ).data;
    if (!conversationState.isLoaded) return const SizedBox();

    final isGroupConversation = conversationState.isGroup ?? false;
    final muting = conversationState.conversation?.isMute == true;
    final isOwnerOrAdmin = userParticipant?.role == ParticipantRole.owner ||
        userParticipant?.role == ParticipantRole.admin;

    final expireIn =
        conversationState.conversation?.expireDuration ?? Duration.zero;

    final canModifyExpireIn =
        !isGroupConversation || (isGroupConversation && isOwnerOrAdmin);

    final isExited = userParticipant == null;
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
            GestureDetector(
              onLongPress: () {
                final copy = HardwareKeyboard.instance.logicalKeysPressed
                    .contains(LogicalKeyboardKey.altLeft);
                if (copy) {
                  Clipboard.setData(ClipboardData(
                      text: 'mixin://conversations/$conversationId'));
                }
              },
              child: ConversationAvatar(
                conversationState: conversationState,
                size: 90,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConversationName(
                conversationState: conversationState,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            ConversationIDOrCount(
              conversationState: conversationState,
              fontSize: 12,
            ),
            _AddToContactsButton(conversationState),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 36),
              child: ConversationBio(
                conversationId: conversationId,
                userId: conversationState.userId,
                isGroup: conversationState.isGroup!,
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
                      action: CustomPopupMenuButton(
                        alignment: Alignment.bottomCenter,
                        color: context.theme.icon,
                        icon: Resources.assetsImagesInviteShareSvg,
                        itemBuilder: (context) => [
                          CustomPopupMenuItem(
                            icon: Resources.assetsImagesContextMenuCopySvg,
                            title: context.l10n.copyLink,
                            value: null,
                          ),
                        ],
                        onSelected: (_) async {
                          final userId = conversationState.userId;
                          if (userId == null) {
                            e('can not share contact, userId is null $conversationState');
                            return;
                          }

                          final user = await context.database.userDao
                              .userById(userId)
                              .getSingleOrNull();

                          if (user == null) {
                            e('can not find user $userId');
                            return;
                          }

                          final codeUrl = user.codeUrl;
                          if (codeUrl == null) {
                            e('can not find codeUrl $codeUrl');
                            return;
                          }

                          i('share contact ${user.userId} $codeUrl');
                          await Clipboard.setData(ClipboardData(text: codeUrl));
                        },
                      ),
                    );

                    if (result == null || result.isEmpty) return;
                    final conversationId = result.first.conversationId;

                    await runFutureWithToast(accountServer.sendContactMessage(
                      conversationState.userId!,
                      conversationState.name,
                      result.first.encryptCategory!,
                      conversationId: conversationId,
                      recipientId: result.first.userId,
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
                  if (conversationState.userId != null)
                    _SharedApps(userId: conversationState.userId!),
                  CellItem(
                    title: Text(
                      context.l10n.searchConversation,
                      maxLines: 1,
                    ),
                    onTap: () => context
                        .read<ChatSideCubit>()
                        .pushPage(ChatSideCubit.searchMessageHistory),
                  ),
                ],
              ),
            ),
            if (!(isGroupConversation && isExited))
              CellGroup(
                child: CellItem(
                  title: Text(context.l10n.disappearingMessage),
                  description: Text(
                    expireIn.formatAsConversationExpireIn(
                      localization: context.l10n,
                    ),
                    style: TextStyle(
                      color: context.theme.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  trailing: canModifyExpireIn ? const Arrow() : null,
                  onTap: !canModifyExpireIn
                      ? null
                      : () => context
                          .read<ChatSideCubit>()
                          .pushPage(ChatSideCubit.disappearMessages),
                ),
              ),
            if (isGroupConversation && isOwnerOrAdmin)
              CellGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Builder(builder: (context) {
                      final announcementTitle = announcement?.isEmpty ?? true
                          ? context.l10n.addGroupDescription
                          : context.l10n.editGroupDescription;
                      return CellItem(
                        title: Text(announcementTitle),
                        onTap: () async {
                          final result = await showMixinDialog<String>(
                            context: context,
                            child: EditDialog(
                              title: Text(announcementTitle),
                              editText: announcement ?? '',
                              maxLines: 7,
                              maxLength: 512,
                            ),
                          );
                          if (result == null) return;

                          await runFutureWithToast(
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
                  if (!(isGroupConversation && isExited))
                    CellItem(
                      title: Text(
                          muting ? context.l10n.unmute : context.l10n.mute),
                      description: muting
                          ? Text(
                              DateFormat('yyyy/MM/dd, hh:mm a').format(
                                  conversationState
                                      .conversation!.validMuteUntil!
                                      .toLocal()),
                              style: TextStyle(
                                color: context.theme.secondaryText,
                                fontSize: 14,
                              ),
                            )
                          : null,
                      trailing: null,
                      onTap: () async {
                        if (muting) {
                          await runFutureWithToast(
                            context.accountServer.unMuteConversation(
                              conversationId:
                                  isGroupConversation ? conversationId : null,
                              userId: isGroupConversation
                                  ? null
                                  : conversationState.userId,
                            ),
                          );
                          return;
                        }

                        final result = await showMixinDialog<int?>(
                            context: context, child: const MuteDialog());
                        if (result == null) return;

                        await runFutureWithToast(
                            context.accountServer.muteConversation(
                          result,
                          conversationId:
                              isGroupConversation ? conversationId : null,
                          userId: isGroupConversation
                              ? null
                              : conversationState.userId,
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
                            editText: conversationState.name ?? '',
                            title: Text(context.l10n.editName),
                            positiveAction: context.l10n.change,
                            maxLength: 40,
                          ),
                        );
                        if (name?.isEmpty ?? true) return;

                        await runFutureWithToast(
                          isGroupConversation
                              ? accountServer.editGroup(
                                  conversationState.conversationId,
                                  name: name,
                                )
                              : accountServer.editContactName(
                                  conversationState.userId!, name!),
                        );
                      },
                    ),
                ],
              ),
            ),
            if (!isGroupConversation)
              CellGroup(
                child: CellItem(
                  title: Text(context.l10n.groupsInCommon),
                  onTap: () => context
                      .read<ChatSideCubit>()
                      .pushPage(ChatSideCubit.groupsInCommon),
                ),
              ),
            if (conversationState.app?.creatorId != null)
              CellGroup(
                child: CellItem(
                  title: Text(context.l10n.developer),
                  trailing: null,
                  onTap: () =>
                      showUserDialog(context, conversationState.app?.creatorId),
                ),
              ),
            CellGroup(
              child: CellItem(
                title: Text(context.l10n.editConversations),
                onTap: () => context
                    .read<ChatSideCubit>()
                    .pushPage(ChatSideCubit.circles),
              ),
            ),
            CellGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (conversationState.relationship ==
                      UserRelationship.blocking)
                    CellItem(
                      title: Text(context.l10n.unblock),
                      color: context.theme.red,
                      trailing: null,
                      onTap: () async {
                        final result = await showConfirmMixinDialog(
                          context,
                          context.l10n.unblock,
                        );
                        if (result == null) return;
                        await runFutureWithToast(
                          accountServer.unblockUser(conversationState.userId!),
                        );
                      },
                    ),
                  if (!isGroupConversation && !conversationState.isStranger!)
                    Builder(builder: (context) {
                      final title = conversationState.isBot
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
                          if (result == null) return;
                          await runFutureWithToast(
                            accountServer.removeUser(conversationState.userId!),
                          );
                        },
                      );
                    }),
                  if (conversationState.isStranger!)
                    CellItem(
                      title: Text(context.l10n.block),
                      color: context.theme.red,
                      trailing: null,
                      onTap: () async {
                        final result = await showConfirmMixinDialog(
                          context,
                          context.l10n.block,
                        );
                        if (result == null) return;
                        await runFutureWithToast(
                          accountServer.blockUser(conversationState.userId!),
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
                      if (result == null) return;
                      await accountServer
                          .deleteMessagesByConversationId(conversationId);
                      context.read<MessageBloc>().reload();
                    },
                  ),
                  if (isGroupConversation)
                    if (!isExited)
                      CellItem(
                        title: Text(context.l10n.exitGroup),
                        color: context.theme.red,
                        trailing: null,
                        onTap: () async {
                          final result = await showConfirmMixinDialog(
                            context,
                            context.l10n.exitGroup,
                          );
                          if (result == null) return;
                          await runFutureWithToast(
                            accountServer.exitGroup(conversationId),
                          );

                          await ConversationStateNotifier.selectConversation(
                            context,
                            conversationId,
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
                          if (result == null) return;
                          await accountServer
                              .deleteMessagesByConversationId(conversationId);
                          await context.database.conversationDao
                              .deleteConversation(conversationId);
                          ref.read(conversationProvider.notifier).unselected();
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
                      context.l10n.reportAndBlock,
                    );
                    if (result == null) return;
                    final userId = conversationState.userId;
                    if (userId == null) return;

                    await runFutureWithToast(
                      accountServer.report(userId),
                    );
                  },
                ),
              ),
            if (createdAt != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  context.l10n.created(DateFormat.yMMMd().format(createdAt)),
                  style: TextStyle(
                    color: context.theme.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ConversationBio extends HookConsumerWidget {
  const ConversationBio({
    required this.conversationId,
    required this.userId,
    required this.isGroup,
    super.key,
    this.fontSize = 14,
  });

  final double fontSize;
  final String conversationId;
  final String? userId;
  final bool isGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textStream = useMemoized(() {
      final database = context.database;
      if (isGroup) {
        return database.conversationDao
            .announcement(conversationId)
            .watchSingleWithStream(
          eventStreams: [
            DataBaseEventBus.instance
                .watchUpdateConversationStream([conversationId])
          ],
          duration: kVerySlowThrottleDuration,
        );
      }
      return database.userDao
          .biographyByIdentityNumber(userId!)
          .watchSingleWithStream(
        eventStreams: [
          DataBaseEventBus.instance.watchUpdateUserStream([userId!])
        ],
        duration: kVerySlowThrottleDuration,
      );
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

/// Button to add strange to contacts.
///
/// if conversation is not stranger, show nothing.
class _AddToContactsButton extends StatelessWidget {
  _AddToContactsButton(
    this.conversation,
  ) : assert(conversation.isLoaded);
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
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                  ),
                  onPressed: () {
                    final username = conversation.user?.fullName ??
                        conversation.conversation?.validName;
                    assert(username != null,
                        'ContactsAdd: username should not be null.');
                    assert(conversation.isGroup != true,
                        'ContactsAdd conversation should not be a group.');
                    runFutureWithToast(context.accountServer.addUser(
                      conversation.userId!,
                      username,
                    ));
                  },
                  child: Text(
                    conversation.isBot
                        ? context.l10n.addBotWithPlus
                        : context.l10n.addContactWithPlus,
                    style: TextStyle(fontSize: 12, color: context.theme.accent),
                  ),
                ),
              )
            : const SizedBox(height: 0),
      );
}

class _SharedApps extends HookConsumerWidget {
  const _SharedApps({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useMemoized(() {
      context.accountServer.loadFavoriteApps(userId);
    }, [userId]);

    final apps = useMemoizedStream(
        () => context.database.favoriteAppDao
            .getFavoriteAppsByUserId(userId)
            .watchWithStream(
                eventStreams: [DataBaseEventBus.instance.updateAppIdStream],
                duration: kVerySlowThrottleDuration),
        keys: [userId]);

    final data = apps.data ?? const [];
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: data.isEmpty
          ? const SizedBox()
          : CellItem(
              title: Text(context.l10n.shareApps),
              trailing: OverlappedAppIcons(apps: data),
              onTap: () => context
                  .read<ChatSideCubit>()
                  .pushPage(ChatSideCubit.sharedApps),
            ),
    );
  }
}
