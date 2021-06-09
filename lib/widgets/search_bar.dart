import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:provider/provider.dart';

import '../account/account_server.dart';
import '../bloc/keyword_cubit.dart';
import '../bloc/simple_cubit.dart';
import '../constants/resources.dart';
import '../db/mixin_database.dart';
import '../generated/l10n.dart';
import '../ui/home/bloc/conversation_cubit.dart';
import '../utils/hook.dart';
import 'action_button.dart';
import 'avatar_view/avatar_view.dart';
import 'brightness_observer.dart';
import 'dialog.dart';
import 'menu.dart';
import 'search_text_field.dart';
import 'toast.dart';
import 'user_selector/conversation_selector.dart';
import 'window/move_window.dart';

class SearchBar extends StatelessWidget {
  const SearchBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => MoveWindow(
        child: ColoredBox(
          color: BrightnessData.themeOf(context).primary,
          child: Row(
            children: [
              const SizedBox(width: 20),
              Expanded(
                child: MoveWindowBarrier(
                  child: SearchTextField(
                    focusNode: context.read<FocusNode>(),
                    controller: context.read<TextEditingController>(),
                    onChanged: (keyword) =>
                        context.read<KeywordCubit>().emit(keyword),
                    hintText: Localization.of(context).search,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ContextMenuPortalEntry(
                buildMenus: () => [
                  ContextMenu(
                    title: Localization.of(context).createConversation,
                    onTap: () async {
                      final list = await showConversationSelector(
                        context: context,
                        singleSelect: true,
                        title: Localization.of(context).createConversation,
                        onlyContact: true,
                      );
                      if (list.isEmpty ||
                          (list.first.userId?.isEmpty ?? true)) {
                        return;
                      }
                      final userId = list.first.userId!;

                      await ConversationCubit.selectUser(
                        context,
                        userId,
                      );
                    },
                  ),
                  ContextMenu(
                    title: Localization.of(context).createGroupConversation,
                    onTap: () async {
                      final result = await showConversationSelector(
                        context: context,
                        singleSelect: false,
                        title: Localization.of(context).createGroupConversation,
                        onlyContact: true,
                      );
                      if (result.isEmpty) return;
                      final userIds = [
                        context.read<AccountServer>().userId,
                        ...result.where((e) => e.userId != null).map(
                              (e) => e.userId!,
                            )
                      ];

                      final name = await showMixinDialog<String>(
                        context: context,
                        child: _NewConversationConfirm(userIds),
                      );
                      if (name?.isEmpty ?? true) return;

                      await runFutureWithToast(
                        context,
                        context
                            .read<AccountServer>()
                            .createGroupConversation(name!, userIds),
                      );
                    },
                  ),
                  ContextMenu(
                    title: Localization.of(context).createCircle,
                    onTap: () async {
                      final list = await showConversationSelector(
                        context: context,
                        singleSelect: false,
                        title: Localization.of(context).createCircle,
                        onlyContact: false,
                      );

                      if (list.isEmpty) return;

                      final name = await showMixinDialog<String>(
                        context: context,
                        child: EditDialog(
                          title: Text(Localization.of(context).circles),
                          hintText: Localization.of(context).editCircleName,
                        ),
                      );

                      if (name?.isEmpty ?? true) return;

                      await runFutureWithToast(
                        context,
                        context.read<AccountServer>().createCircle(
                              name!,
                              list
                                  .map(
                                    (e) => CircleConversationRequest(
                                      action: CircleConversationAction.add,
                                      conversationId: e.conversationId,
                                      userId: e.userId,
                                    ),
                                  )
                                  .toList(),
                            ),
                      );
                    },
                  ),
                ],
                child: Builder(
                  builder: (context) => MoveWindowBarrier(
                    child: ActionButton(
                      name: Resources.assetsImagesIcAddSvg,
                      size: 16,
                      onTapUp: (event) => context
                          .read<OffsetCubit>()
                          .emit(event.globalPosition),
                      padding: const EdgeInsets.all(8),
                      color: BrightnessData.themeOf(context).icon,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      );
}

class _NewConversationConfirm extends HookWidget {
  const _NewConversationConfirm(
    this.userIds, {
    Key? key,
  }) : super(key: key);

  final List<String> userIds;

  @override
  Widget build(BuildContext context) {
    final users = useMemoizedFuture(
      () => context
          .read<AccountServer>()
          .database
          .userDao
          .usersByIn(userIds.sublist(0, min(4, userIds.length)))
          .get(),
      <User>[],
    );

    final textEditingController = useTextEditingController();
    final textEditingValue = useValueListenable(textEditingController);
    return AlertDialogLayout(
      title: Text(Localization.of(context).group),
      titleMarginBottom: 24,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: SizedBox(
              height: 60,
              width: 60,
              child: AvatarPuzzlesWidget(users, 60),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Localization.of(context).participantsCount(userIds.length),
            style: TextStyle(
              fontSize: 14,
              color: BrightnessData.themeOf(context).secondaryText,
            ),
          ),
          const SizedBox(height: 48),
          DialogTextField(
            textEditingController: textEditingController,
            hintText: '',
          ),
        ],
      ),
      actions: [
        MixinButton(
            backgroundTransparent: true,
            onTap: () => Navigator.pop(context),
            child: Text(Localization.of(context).cancel)),
        MixinButton(
          disable: textEditingValue.text.isEmpty,
          onTap: () => Navigator.pop(context, textEditingController.text),
          child: Text(Localization.of(context).create),
        ),
      ],
    );
  }
}
