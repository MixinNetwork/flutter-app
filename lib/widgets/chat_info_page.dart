import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/db/extension/conversation.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/chat_page.dart';
import 'package:flutter_app/ui/home/slide_page.dart';
import 'package:flutter_app/utils/color_utils.dart';
import 'package:flutter_app/utils/hook.dart';
import 'package:flutter_app/widgets/action_button.dart';
import 'package:flutter_app/widgets/dialog.dart';
import 'package:flutter_app/widgets/user_selector/conversation_selector.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/utils/list_utils.dart';
import 'package:tuple/tuple.dart';

import 'app_bar.dart';
import 'brightness_observer.dart';
import 'cell.dart';
import 'chat_bar.dart';
import 'toast.dart';

class ChatInfoPage extends HookWidget {
  const ChatInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isGroupConversation =
        useBlocStateConverter<ConversationCubit, ConversationItem?, bool?>(
              converter: (state) => state?.isGroupConversation,
              when: (state) => state != null,
            ) ??
            false;
    final muteUntil =
        useBlocStateConverter<ConversationCubit, ConversationItem?, DateTime?>(
      converter: (state) => state?.muteUntil,
      when: (state) => state != null,
    );
    final muting = muteUntil?.isAfter(DateTime.now()) == true;

    return Column(
      children: [
        Container(
          height: 64,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 8),
          child: ActionButton(
            name: Resources.assetsImagesIcCloseSvg,
            onTap: () => Navigator.pop(context),
          ),
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
                        final conversation =
                            context.read<ConversationCubit>().state;
                        if (conversation == null) return;

                        final result = await showConversationSelector(
                          context: context,
                          singleSelect: true,
                          title: Localization.of(context).shareContact,
                          onlyContact: false,
                        );

                        if (result.isEmpty) return;
                        final conversationId = result[0].item1;

                        await context.read<AccountServer>().sendContactMessage(
                              conversation.ownerId!,
                              conversation.name ?? '',
                              conversationId: conversationId,
                              recipientId: conversationId,
                            );
                      },
                    ),
                  ),
                const SizedBox(height: 10),
                CellGroup(
                  child: CellItem(
                    title: Localization.of(context).sharedMedia,
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 10),
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
                                    .format(muteUntil!),
                                style: TextStyle(
                                  color: BrightnessData.themeOf(context)
                                      .secondaryText,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                        trailing: null,
                        onTap: () {
                          // if(muting)
                        },
                      ),
                      if (!isGroupConversation)
                        CellItem(
                          title: Localization.of(context).editName,
                          onTap: () async {
                            final conversation =
                                context.read<ConversationCubit>().state;
                            if (conversation == null ||
                                (conversation.ownerId?.isEmpty ?? true)) return;

                            final name = await showMixinDialog<String>(
                              context: context,
                              child:
                                  EditNameDialog(name: conversation.name ?? ''),
                            );
                            if (name?.isEmpty ?? true) return;

                            await runFutureWithToast(
                              context,
                              context.read<AccountServer>().editContactName(
                                  conversation.ownerId!, name!),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                CellGroup(
                  child: CellItem(
                    title: Localization.of(context).circles,
                    description: const _CircleNames(),
                    onTap: () {
                      final conversation =
                          context.read<ConversationCubit>().state;
                      if (conversation == null) return;

                      context.read<ChatSideCubit>().pushPage(
                            ChatSideCubit.circles,
                            arguments: Tuple2<String, String>(
                              conversation.validName,
                              conversation.conversationId,
                            ),
                          );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                CellGroup(
                  child: Column(
                    children: [
                      CellItem(
                        title: Localization.of(context).clearChat,
                        color: BrightnessData.themeOf(context).red,
                        trailing: null,
                        onTap: () {},
                      ),
                      if (isGroupConversation)
                        CellItem(
                          title: Localization.of(context).exitGroup,
                          color: BrightnessData.themeOf(context).red,
                          trailing: null,
                          onTap: () async {
                            final conversationId = context
                                .read<ConversationCubit>()
                                .state
                                ?.conversationId;
                            if (conversationId == null) return;

                            await runFutureWithToast(
                              context,
                              context
                                  .read<AccountServer>()
                                  .exitGroup(conversationId),
                            );
                          },
                        )
                      else
                        CellItem(
                          title: Localization.of(context).removeContact,
                          color: BrightnessData.themeOf(context).red,
                          trailing: null,
                          onTap: () {},
                        ),
                    ],
                  ),
                ),
                if (!isGroupConversation) const SizedBox(height: 10),
                if (!isGroupConversation)
                  CellGroup(
                    child: CellItem(
                      title: Localization.of(context).report,
                      color: BrightnessData.themeOf(context).red,
                      trailing: null,
                      onTap: () {},
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

class EditNameDialog extends HookWidget {
  const EditNameDialog({
    Key? key,
    this.name = '',
  }) : super(key: key);

  final String name;

  @override
  Widget build(BuildContext context) {
    final textEditingController = useTextEditingController.call(text: name);
    final textEditingValue = useValueListenable(textEditingController);
    return AlertDialogLayout(
      title: Text(Localization.of(context).editName),
      content: DialogTextField(
          textEditingController: textEditingController,
          hintText: Localization.of(context).conversationName),
      actions: [
        MixinButton(
            backgroundTransparent: true,
            child: Text(Localization.of(context).cancel),
            onTap: () => Navigator.pop(context)),
        MixinButton(
          child: Text(Localization.of(context).create),
          disable: textEditingValue.text.isEmpty,
          onTap: () => Navigator.pop(context, textEditingController.text),
        ),
      ],
    );
  }
}

class CircleManagerPage extends HookWidget {
  const CircleManagerPage({
    Key? key,
    required this.name,
    required this.conversationId,
  }) : super(key: key);

  final String name;
  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final circles = useStream<List<ConversationCircleManagerItem>>(
      useMemoized(
        () => context
            .read<AccountServer>()
            .database
            .circlesDao
            .circleByConversationId(conversationId)
            .watch(),
        [conversationId],
      ),
      initialData: [],
    ).data as List<ConversationCircleManagerItem>;
    final otherCircles = useStream<List<ConversationCircleManagerItem>>(
      useMemoized(
        () => context
            .read<AccountServer>()
            .database
            .circlesDao
            .otherCircleByConversationId(conversationId)
            .watch(),
        [conversationId],
      ),
      initialData: [],
    ).data as List<ConversationCircleManagerItem>;

    return Scaffold(
      appBar: MixinAppBar(
        title: Text(Localization.of(context).circleTitle(name)),
        actions: [
          MixinButton(
            child: SvgPicture.asset(
              Resources.assetsImagesIcAddSvg,
              width: 16,
              height: 16,
            ),
            backgroundTransparent: true,
            onTap: () async {
              final conversation = context.read<ConversationCubit>().state;
              if (conversation?.conversationId.isEmpty ?? true) return;

              final name = await showMixinDialog<String>(
                context: context,
                child: const EditCircleNameDialog(),
              );

              await runFutureWithToast(
                context,
                context
                    .read<AccountServer>()
                    .createCircle(name!, [conversation!.conversationId]),
              );
            },
          ),
        ],
      ),
      backgroundColor: BrightnessData.themeOf(context).background,
      body: ListView(
        children: <Widget>[
          if (circles.isNotEmpty)
            ...circles
                .map(
                  (e) => _CircleManagerItem(
                    name: e.name,
                    count: e.count,
                    circleId: e.circleId,
                    selected: true,
                  ),
                )
                .toList(),
          if (circles.isNotEmpty && otherCircles.isNotEmpty)
            const SizedBox(height: 10),
          if (otherCircles.isNotEmpty)
            ...otherCircles
                .map(
                  (e) => _CircleManagerItem(
                    name: e.name,
                    count: e.count,
                    circleId: e.circleId,
                    selected: false,
                  ),
                )
                .toList(),
        ],
      ),
    );
  }
}

class _CircleManagerItem extends StatelessWidget {
  const _CircleManagerItem({
    Key? key,
    required this.name,
    required this.count,
    required this.circleId,
    required this.selected,
  }) : super(key: key);

  final String name;
  final int count;
  final String circleId;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        height: 80,
        color: BrightnessData.themeOf(context).primary,
        child: Row(
          children: [
            GestureDetector(
              child: Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SvgPicture.asset(
                  selected
                      ? Resources.assetsImagesCircleRemoveSvg
                      : Resources.assetsImagesCircleAddSvg,
                  height: 16,
                  width: 16,
                ),
              ),
              onTap: () async {
                final conversation = context.read<ConversationCubit>().state;
                if (conversation?.conversationId.isEmpty ?? true) return;

                if (selected) {
                  await runFutureWithToast(
                    context,
                    context.read<AccountServer>().circleRemoveConversation(
                        circleId, conversation!.conversationId),
                  );
                  return;
                }

                await runFutureWithToast(
                  context,
                  context.read<AccountServer>().circleAddConversation(
                      circleId, conversation!.conversationId),
                );
              },
            ),
            const SizedBox(width: 4),
            ClipOval(
              child: Container(
                color: BrightnessData.dynamicColor(
                  context,
                  const Color.fromRGBO(246, 247, 250, 1),
                  darkColor: const Color.fromRGBO(245, 247, 250, 1),
                ),
                height: 50,
                width: 50,
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  Resources.assetsImagesCircleSvg,
                  width: 18,
                  height: 18,
                  color: getCircleColorById(circleId),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: BrightnessData.themeOf(context).text,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  Localization.of(context).conversationCount(count),
                  style: TextStyle(
                    color: BrightnessData.themeOf(context).secondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
