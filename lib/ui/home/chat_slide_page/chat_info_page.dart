import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';

import '../../../account/account_server.dart';
import '../../../constants/resources.dart';
import '../../../db/extension/conversation.dart';
import '../../../db/mixin_database.dart';
import '../../../generated/l10n.dart';
import '../../../utils/hook.dart';
import '../../../utils/list_utils.dart';
import '../../../utils/string_extension.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/brightness_observer.dart';
import '../../../widgets/cell.dart';
import '../../../widgets/chat_bar.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/interacter_decorated_box.dart';
import '../../../widgets/toast.dart';
import '../../../widgets/user_selector/conversation_selector.dart';
import '../bloc/conversation_cubit.dart';
import '../bloc/message_bloc.dart';
import '../chat_page.dart';
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

    final accountServer = context.read<AccountServer>();
    final userParticipant = useStream<Participant?>(
      useMemoized(
        () => accountServer.database.conversationDao
            .participantById(conversationId, accountServer.userId)
            .watchSingleOrNull(),
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
            useMemoized(() => context
                .read<AccountServer>()
                .database
                .conversationDao
                .announcement(conversationId)
                .watchSingle()),
            initialData: null)
        .data;
    if (!conversation.isLoaded) return const SizedBox();

    final isGroupConversation = conversation.isGroup!;
    final muting = conversation.conversation?.isMute == true;

    return Scaffold(
      appBar: MixinAppBar(
        actions: [
          if (ModalRoute.of(context)?.canPop != true)
            ActionButton(
              name: Resources.assetsImagesIcCloseSvg,
              color: BrightnessData.themeOf(context).icon,
              onTap: () => context.read<ChatSideCubit>().onPopPage(),
            ),
        ],
        backgroundColor: BrightnessData.themeOf(context).popUp,
      ),
      backgroundColor: BrightnessData.themeOf(context).popUp,
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
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            if (isGroupConversation)
              CellGroup(
                child: CellItem(
                  title: Text(
                    Localization.of(context).groupParticipants,
                  ),
                  onTap: () => context
                      .read<ChatSideCubit>()
                      .pushPage(ChatSideCubit.participants),
                ),
              ),
            if (!isGroupConversation)
              CellGroup(
                child: CellItem(
                  title: Text(Localization.of(context).shareContact),
                  onTap: () async {
                    final result = await showConversationSelector(
                      context: context,
                      singleSelect: true,
                      title: Localization.of(context).shareContact,
                      onlyContact: false,
                    );

                    if (result.isEmpty) return;
                    final conversationId = result[0].conversationId;

                    assert(!(result[0].isGroup && result[0].userId != null),
                        'group conversation should not contains userId!');

                    await runFutureWithToast(
                        context,
                        accountServer.sendContactMessage(
                          conversation.userId!,
                          conversation.name!,
                          isPlain(result.first.isGroup, result.first.isBot),
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
                    title: Text(Localization.of(context).sharedMedia),
                    onTap: () => context
                        .read<ChatSideCubit>()
                        .pushPage(ChatSideCubit.sharedMedia),
                  ),
                  CellItem(
                    title: Text(
                      Localization.of(context).searchMessageHistory,
                      maxLines: 1,
                    ),
                    onTap: () => context
                        .read<ChatSideCubit>()
                        .pushPage(ChatSideCubit.searchMessageHistory),
                  ),
                ],
              ),
            ),
            if (isGroupConversation &&
                (userParticipant?.role == ParticipantRole.owner ||
                    userParticipant?.role == ParticipantRole.admin))
              CellGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Builder(builder: (context) {
                      final announcementTitle = announcement?.isEmpty ?? true
                          ? Localization.of(context).addAnnouncement
                          : Localization.of(context).editAnnouncement;
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
                            context.read<AccountServer>().editGroupAnnouncement(
                                  conversationId,
                                  result,
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
                    title: Text(muting
                        ? Localization.of(context).unMute
                        : Localization.of(context).muted),
                    description: muting
                        ? Text(
                            DateFormat('yyyy/MM/dd, hh:mm a').format(
                                conversation.conversation!.validMuteUntil!
                                    .toLocal()),
                            style: TextStyle(
                              color:
                                  BrightnessData.themeOf(context).secondaryText,
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
                          context.read<AccountServer>().unMuteConversation(
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
                          context.read<AccountServer>().muteConversation(
                                result,
                                conversationId: isGroup ? conversationId : null,
                                userId: isGroup ? null : conversation.userId,
                              ));
                    },
                  ),
                  if (!isGroupConversation)
                    CellItem(
                      title: Text(Localization.of(context).editName),
                      trailing: null,
                      onTap: () async {
                        final name = await showMixinDialog<String>(
                          context: context,
                          child: EditDialog(
                            editText: conversation.name ?? '',
                            title: Text(Localization.of(context).editName),
                            hintText: Localization.of(context).conversationName,
                            positiveAction: Localization.of(context).change,
                          ),
                        );
                        if (name?.isEmpty ?? true) return;

                        await runFutureWithToast(
                          context,
                          accountServer.editContactName(
                              conversation.userId!, name!),
                        );
                      },
                    ),
                ],
              ),
            ),
            CellGroup(
              child: CellItem(
                title: Text(Localization.of(context).circles),
                description: const _CircleNames(),
                onTap: () => context.read<ChatSideCubit>().pushPage(
                      ChatSideCubit.circles,
                      // arguments: Tuple2<String, String>(
                      //   conversation.name!,
                      //   conversationId,
                      // ),
                    ),
              ),
            ),
            CellGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (conversation.relationship == UserRelationship.blocking)
                    CellItem(
                      title: Text(Localization.of(context).unblock),
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
                          accountServer.unblockUser(conversation.userId!),
                        );
                      },
                    ),
                  if (!isGroupConversation && !conversation.isStranger!)
                    Builder(builder: (context) {
                      final title = conversation.isBot!
                          ? Localization.of(context).removeBot
                          : Localization.of(context).removeContact;
                      return CellItem(
                        title: Text(title),
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
                            accountServer.removeUser(conversation.userId!),
                          );
                        },
                      );
                    }),
                  if (conversation.isStranger!)
                    CellItem(
                      title: Text(Localization.of(context).block),
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
                          accountServer.blockUser(conversation.userId!),
                        );
                      },
                    ),
                  CellItem(
                    title: Text(Localization.of(context).clearChat),
                    color: BrightnessData.themeOf(context).red,
                    trailing: null,
                    onTap: () async {
                      final result = await showConfirmMixinDialog(
                        context,
                        Localization.of(context).clearChat,
                      );
                      if (!result) return;

                      await accountServer.database.messagesDao
                          .deleteMessageByConversationId(conversationId);
                      context.read<MessageBloc>().reload();
                    },
                  ),
                  if (conversation.isGroup!)
                    if (userParticipant != null)
                      CellItem(
                        title: Text(Localization.of(context).exitGroup),
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
                            accountServer.exitGroup(conversationId),
                          );
                        },
                      )
                    else
                      CellItem(
                        title: Text(Localization.of(context).deleteGroup),
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
                              .deleteMessageByConversationId(conversationId);
                          await context
                              .read<AccountServer>()
                              .database
                              .conversationDao
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
                  title: Text(Localization.of(context).report),
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

class _CircleNames extends HookWidget {
  const _CircleNames();

  @override
  Widget build(BuildContext context) {
    final conversationId =
        useBlocStateConverter<ConversationCubit, ConversationState?, String?>(
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
        ).data ??
        [];

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
    final expand = useState(false);

    final textStream = useMemoized(() {
      final database = context.read<AccountServer>().database;
      if (isGroup) {
        return database.conversationDao
            .announcement(conversationId)
            .watchSingle();
      }
      return database.userDao.biography(userId!).watchSingle();
    }, [
      conversationId,
      userId,
      isGroup,
    ]);

    final text = useStream(textStream, initialData: '').data;
    if (text?.isEmpty == true) return const SizedBox();

    return ExtendedText(
      expand.value ? text! : text!.overflow,
      style: TextStyle(
        color: BrightnessData.themeOf(context).text,
        fontSize: fontSize,
      ),
      maxLines: expand.value ? null : 3,
      overflow: TextOverflow.fade,
      textAlign: TextAlign.center,
      overflowWidget: TextOverflowWidget(
        child: InteractableDecoratedBox(
          onTap: () {
            expand.value = true;
          },
          child: Text(
            Localization.of(context).more,
            style: TextStyle(
              color: BrightnessData.themeOf(context).accent,
            ),
          ),
        ),
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
                    backgroundColor: BrightnessData.themeOf(context).background,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    fixedSize: const Size.fromHeight(30),
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
                        context.read<AccountServer>().addUser(
                              conversation.userId!,
                              username,
                            ));
                  },
                  child: Text(
                    conversation.isBot!
                        ? Localization.of(context).conversationAddBot
                        : Localization.of(context).conversationAddContact,
                    style: TextStyle(
                        fontSize: 12,
                        color: BrightnessData.themeOf(context).accent),
                  ),
                ),
              )
            : const SizedBox(height: 0),
      );
}
