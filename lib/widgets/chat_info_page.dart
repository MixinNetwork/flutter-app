import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/utils/hook.dart';
import 'package:flutter_app/widgets/action_button.dart';
import 'package:flutter_app/widgets/dialog.dart';
import 'package:flutter_app/widgets/user_selector/conversation_selector.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_app/db/extension/conversation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/generated/l10n.dart';

import 'Toast.dart';
import 'brightness_observer.dart';
import 'cell.dart';
import 'chat_bar.dart';

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
                            final name = await showMixinDialog<String>(
                              context: context,
                              child: EditNameDialog(
                                  name: context
                                          .read<ConversationCubit>()
                                          .state
                                          ?.name ??
                                      ''),
                            );

                            // todo edit contact name;
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                CellGroup(
                  child: CellItem(
                    title: Localization.of(context).circles,
                    onTap: () {},
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
                            final conversationId = context.read<ConversationCubit>().state?.conversationId;
                            if(conversationId == null) return;
                            showToastLoading(context);
                            try {
                              await context.read<AccountServer>().exitGroup(conversationId);
                            } catch (e) {
                              return showToastFailed(context);
                            }
                            showToastSuccessful(context);
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
