import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../constants/resources.dart';
import '../../../db/database_event_bus.dart';
import '../../../utils/extension/extension.dart';
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
import '../../provider/account_server_provider.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/database_provider.dart';
import '../../provider/ui_context_providers.dart';
import '../chat/chat_bar.dart';
import '../chat/chat_page.dart';
import '../providers/home_scope_providers.dart';
import 'shared_apps_page.dart';

final _conversationAnnouncementProvider = StreamProvider.autoDispose
    .family<String?, String>((ref, conversationId) {
      final database = ref.watch(databaseProvider).value;
      if (database == null) {
        return Stream.value(null);
      }
      return database.conversationDao
          .announcement(conversationId)
          .watchSingleWithStream(
            eventStreams: [
              DataBaseEventBus.instance.watchUpdateConversationStream([
                conversationId,
              ]),
            ],
            duration: kVerySlowThrottleDuration,
          );
    });

class ChatInfoPage extends HookConsumerWidget {
  const ChatInfoPage(this.conversationState, {super.key});

  final ConversationState conversationState;

  String get conversationId => conversationState.conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final l10n = ref.watch(localizationProvider);
    final createdAt = useMemoized(() {
      final item = conversationState.conversation;
      if (item == null) return null;
      if (!item.isGroupConversation) return null;

      return item.createdAt;
    });

    final accountServer = ref.read(accountServerProvider).requireValue;
    final database = ref.read(databaseProvider).requireValue;

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

    final announcement = ref
        .watch(_conversationAnnouncementProvider(conversationId))
        .value;
    if (!conversationState.isLoaded) return const SizedBox();

    final isGroupConversation = conversationState.isGroup ?? false;
    final muting = conversationState.conversation?.isMute == true;
    final isOwnerOrAdmin =
        userParticipant?.role == ParticipantRole.owner ||
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
              color: theme.icon,
              onTap: () =>
                  ref.read(chatSideControllerProvider.notifier).onPopPage(),
            ),
        ],
        backgroundColor: theme.popUp,
      ),
      backgroundColor: theme.popUp,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            GestureDetector(
              onLongPress: () {
                final copy = HardwareKeyboard.instance.logicalKeysPressed
                    .contains(LogicalKeyboardKey.altLeft);
                if (copy) {
                  Clipboard.setData(
                    ClipboardData(
                      text: 'mixin://conversations/$conversationId',
                    ),
                  );
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
            if (isGroupConversation && !isExited)
              CellGroup(
                child: CellItem(
                  title: Text(l10n.groupParticipants),
                  onTap: () => ref
                      .read(chatSideControllerProvider.notifier)
                      .pushPage(
                        ChatSideController.participants,
                      ),
                ),
              ),
            if (!isGroupConversation)
              CellGroup(
                child: CellItem(
                  title: Text(l10n.shareContact),
                  onTap: () async {
                    final result = await showConversationSelector(
                      context: context,
                      singleSelect: true,
                      title: l10n.shareContact,
                      onlyContact: false,
                      action: CustomPopupMenuButton(
                        alignment: Alignment.bottomCenter,
                        color: theme.icon,
                        icon: Resources.assetsImagesInviteShareSvg,
                        itemBuilder: (context) => [
                          CustomPopupMenuItem(
                            icon: Resources.assetsImagesContextMenuCopySvg,
                            title: l10n.copyLink,
                            value: null,
                          ),
                        ],
                        onSelected: (_) async {
                          final userId = conversationState.userId;
                          if (userId == null) {
                            e(
                              'can not share contact, userId is null $conversationState',
                            );
                            return;
                          }

                          final user = await database.userDao
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

                    await runFutureWithToast(
                      accountServer.sendContactMessage(
                        conversationState.userId!,
                        conversationState.name,
                        result.first.encryptCategory!,
                        conversationId: conversationId,
                        recipientId: result.first.userId,
                      ),
                    );
                  },
                ),
              ),
            CellGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CellItem(
                    title: Text(l10n.sharedMedia),
                    onTap: () => ref
                        .read(chatSideControllerProvider.notifier)
                        .pushPage(
                          ChatSideController.sharedMedia,
                        ),
                  ),
                  if (conversationState.userId != null)
                    _SharedApps(userId: conversationState.userId!),
                  CellItem(
                    title: Text(
                      l10n.searchConversation,
                      maxLines: 1,
                    ),
                    onTap: () => ref
                        .read(chatSideControllerProvider.notifier)
                        .pushPage(
                          ChatSideController.searchMessageHistory,
                        ),
                  ),
                ],
              ),
            ),
            if (!(isGroupConversation && isExited))
              CellGroup(
                child: CellItem(
                  title: Text(l10n.disappearingMessage),
                  description: Text(
                    expireIn.formatAsConversationExpireIn(
                      localization: l10n,
                    ),
                    style: TextStyle(
                      color: theme.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  trailing: canModifyExpireIn ? const Arrow() : null,
                  onTap: !canModifyExpireIn
                      ? null
                      : () => ref
                            .read(chatSideControllerProvider.notifier)
                            .pushPage(
                              ChatSideController.disappearMessages,
                            ),
                ),
              ),
            if (isGroupConversation && isOwnerOrAdmin)
              CellGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Builder(
                      builder: (context) {
                        final announcementTitle = announcement?.isEmpty ?? true
                            ? l10n.addGroupDescription
                            : l10n.editGroupDescription;
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
                              accountServer.editGroup(
                                conversationId,
                                announcement: result,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            CellGroup(
              child: Column(
                children: [
                  if (!(isGroupConversation && isExited))
                    CellItem(
                      title: Text(
                        muting ? l10n.unmute : l10n.mute,
                      ),
                      description: muting
                          ? Text(
                              DateFormat('yyyy/MM/dd, hh:mm a').format(
                                conversationState.conversation!.validMuteUntil!
                                    .toLocal(),
                              ),
                              style: TextStyle(
                                color: theme.secondaryText,
                                fontSize: 14,
                              ),
                            )
                          : null,
                      trailing: null,
                      onTap: () async {
                        if (muting) {
                          await runFutureWithToast(
                            accountServer.unMuteConversation(
                              conversationId: isGroupConversation
                                  ? conversationId
                                  : null,
                              userId: isGroupConversation
                                  ? null
                                  : conversationState.userId,
                            ),
                          );
                          return;
                        }

                        final result = await showMixinDialog<int?>(
                          context: context,
                          child: const MuteDialog(),
                        );
                        if (result == null) return;

                        await runFutureWithToast(
                          accountServer.muteConversation(
                            result,
                            conversationId: isGroupConversation
                                ? conversationId
                                : null,
                            userId: isGroupConversation
                                ? null
                                : conversationState.userId,
                          ),
                        );
                      },
                    ),
                  if (!isGroupConversation ||
                      (isGroupConversation && isOwnerOrAdmin))
                    CellItem(
                      title: Text(l10n.editName),
                      trailing: null,
                      onTap: () async {
                        final name = await showMixinDialog<String>(
                          context: context,
                          child: EditDialog(
                            editText: conversationState.name ?? '',
                            title: Text(l10n.editName),
                            positiveAction: l10n.change,
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
                                  conversationState.userId!,
                                  name!,
                                ),
                        );
                      },
                    ),
                ],
              ),
            ),
            if (!isGroupConversation)
              CellGroup(
                child: CellItem(
                  title: Text(l10n.groupsInCommon),
                  onTap: () => ref
                      .read(chatSideControllerProvider.notifier)
                      .pushPage(
                        ChatSideController.groupsInCommon,
                      ),
                ),
              ),
            if (conversationState.app?.creatorId != null)
              CellGroup(
                child: CellItem(
                  title: Text(l10n.developer),
                  trailing: null,
                  onTap: () => showUserDialog(
                    context,
                    ref.container,
                    conversationState.app?.creatorId,
                  ),
                ),
              ),
            CellGroup(
              child: CellItem(
                title: Text(l10n.editConversations),
                onTap: () => ref
                    .read(chatSideControllerProvider.notifier)
                    .pushPage(
                      ChatSideController.circles,
                    ),
              ),
            ),
            CellGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (conversationState.relationship ==
                      UserRelationship.blocking)
                    CellItem(
                      title: Text(l10n.unblock),
                      color: theme.red,
                      trailing: null,
                      onTap: () async {
                        final result = await showConfirmMixinDialog(
                          context,
                          l10n.unblock,
                        );
                        if (result == null) return;
                        await runFutureWithToast(
                          accountServer.unblockUser(conversationState.userId!),
                        );
                      },
                    ),
                  if (!isGroupConversation && !conversationState.isStranger!)
                    Builder(
                      builder: (context) {
                        final title = conversationState.isBot
                            ? l10n.removeBot
                            : l10n.removeContact;
                        return CellItem(
                          title: Text(title),
                          color: theme.red,
                          trailing: null,
                          onTap: () async {
                            final result = await showConfirmMixinDialog(
                              context,
                              title,
                            );
                            if (result == null) return;
                            await runFutureWithToast(
                              accountServer.removeUser(
                                conversationState.userId!,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  if (conversationState.isStranger!)
                    CellItem(
                      title: Text(l10n.block),
                      color: theme.red,
                      trailing: null,
                      onTap: () async {
                        final result = await showConfirmMixinDialog(
                          context,
                          l10n.block,
                        );
                        if (result == null) return;
                        await runFutureWithToast(
                          accountServer.blockUser(conversationState.userId!),
                        );
                      },
                    ),
                  CellItem(
                    title: Text(l10n.clearChat),
                    color: theme.red,
                    trailing: null,
                    onTap: () async {
                      final result = await showConfirmMixinDialog(
                        context,
                        l10n.clearChat,
                      );
                      if (result == null) return;
                      await accountServer.deleteMessagesByConversationId(
                        conversationId,
                      );
                      ref.read(messageControllerProvider.notifier).reload();
                    },
                  ),
                  if (isGroupConversation)
                    if (!isExited)
                      CellItem(
                        title: Text(l10n.exitGroup),
                        color: theme.red,
                        trailing: null,
                        onTap: () async {
                          final result = await showConfirmMixinDialog(
                            context,
                            l10n.exitGroup,
                          );
                          if (result == null) return;
                          await runFutureWithToast(
                            accountServer.exitGroup(conversationId),
                          );

                          await ConversationStateNotifier.selectConversation(
                            ref.container,
                            context,
                            conversationId,
                          );
                        },
                      )
                    else
                      CellItem(
                        title: Text(l10n.deleteGroup),
                        color: theme.red,
                        trailing: null,
                        onTap: () async {
                          final result = await showConfirmMixinDialog(
                            context,
                            l10n.deleteGroup,
                          );
                          if (result == null) return;
                          await accountServer.deleteMessagesByConversationId(
                            conversationId,
                          );
                          await accountServer.deleteConversation(
                            conversationId,
                          );
                          ref.read(conversationProvider.notifier).unselected();
                        },
                      ),
                ],
              ),
            ),
            if (!isGroupConversation)
              CellGroup(
                child: CellItem(
                  title: Text(l10n.report),
                  color: theme.red,
                  trailing: null,
                  onTap: () async {
                    final result = await showConfirmMixinDialog(
                      context,
                      l10n.reportAndBlock,
                    );
                    if (result == null) return;
                    final userId = conversationState.userId;
                    if (userId == null) return;

                    await runFutureWithToast(accountServer.report(userId));
                  },
                ),
              ),
            if (createdAt != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  l10n.createdAt(DateFormat.yMMMd().format(createdAt)),
                  style: TextStyle(
                    color: theme.secondaryText,
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
    final theme = ref.watch(brightnessThemeDataProvider);
    final textStream = useMemoized(() {
      final database = ref.read(databaseProvider).requireValue;
      if (isGroup) {
        return database.conversationDao
            .announcement(conversationId)
            .watchSingleWithStream(
              eventStreams: [
                DataBaseEventBus.instance.watchUpdateConversationStream([
                  conversationId,
                ]),
              ],
              duration: kVerySlowThrottleDuration,
            );
      }
      return database.userDao
          .biographyByIdentityNumber(userId!)
          .watchSingleWithStream(
            eventStreams: [
              DataBaseEventBus.instance.watchUpdateUserStream([userId!]),
            ],
            duration: kVerySlowThrottleDuration,
          );
    }, [conversationId, userId, isGroup]);

    final text = useStream(textStream, initialData: '').data!;
    if (text.isEmpty) return const SizedBox();

    return MoreExtendedText(
      text,
      style: TextStyle(
        color: theme.text,
        fontSize: fontSize,
      ),
    );
  }
}

/// Button to add strange to contacts.
///
/// if conversation is not stranger, show nothing.
class _AddToContactsButton extends ConsumerWidget {
  _AddToContactsButton(this.conversation) : assert(conversation.isLoaded);
  final ConversationState conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final l10n = ref.watch(localizationProvider);
    final accountServer = ref.read(accountServerProvider).requireValue;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: conversation.isStranger!
          ? Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: theme.statusBackground,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 7,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                ),
                onPressed: () {
                  final username =
                      conversation.user?.fullName ??
                      conversation.conversation?.validName;
                  assert(
                    username != null,
                    'ContactsAdd: username should not be null.',
                  );
                  assert(
                    conversation.isGroup != true,
                    'ContactsAdd conversation should not be a group.',
                  );
                  runFutureWithToast(
                    accountServer.addUser(
                      conversation.userId!,
                      username,
                    ),
                  );
                },
                child: Text(
                  conversation.isBot
                      ? l10n.addBotWithPlus
                      : l10n.addContactWithPlus,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.accent,
                  ),
                ),
              ),
            )
          : const SizedBox(height: 0),
    );
  }
}

class _SharedApps extends HookConsumerWidget {
  const _SharedApps({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    useMemoized(() {
      ref.read(accountServerProvider).requireValue.loadFavoriteApps(userId);
    }, [userId]);
    final data = ref.watch(sharedAppsProvider(userId)).value ?? const [];
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: data.isEmpty
          ? const SizedBox()
          : CellItem(
              title: Text(l10n.shareApps),
              trailing: OverlappedAppIcons(apps: data),
              onTap: () => ref
                  .read(chatSideControllerProvider.notifier)
                  .pushPage(
                    ChatSideController.sharedApps,
                  ),
            ),
    );
  }
}
