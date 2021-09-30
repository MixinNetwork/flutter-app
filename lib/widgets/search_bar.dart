import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;

import '../bloc/keyword_cubit.dart';
import '../constants/resources.dart';
import '../db/mixin_database.dart';
import '../ui/home/bloc/conversation_cubit.dart';
import '../ui/home/home.dart';
import '../utils/extension/extension.dart';
import '../utils/hook.dart';
import 'action_button.dart';
import 'avatar_view/avatar_view.dart';
import 'dialog.dart';
import 'menu.dart';
import 'search_text_field.dart';
import 'toast.dart';
import 'user/user_dialog.dart';
import 'user_selector/conversation_selector.dart';
import 'window/move_window.dart';

class SearchBar extends HookWidget {
  const SearchBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasDrawer = context.watch<HasDrawerValueNotifier>();

    Widget? leading;
    if (hasDrawer.value) {
      leading = ActionButton(
        onTapUp: (event) => Scaffold.of(context).openDrawer(),
        child: Icon(
          Icons.menu,
          size: 20,
          color: context.theme.icon,
        ),
      );
    }

    return MoveWindow(
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 150),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: leading != null
                    ? Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: leading,
                      )
                    : const SizedBox(width: 20),
              ),
            ),
            Expanded(
              child: MoveWindowBarrier(
                child: SearchTextField(
                  focusNode: context.read<FocusNode>(),
                  controller: context.read<TextEditingController>(),
                  onChanged: (keyword) =>
                      context.read<KeywordCubit>().emit(keyword),
                  hintText: context.l10n.search,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ContextMenuPortalEntry(
              buildMenus: () => [
                ContextMenu(
                  title: context.l10n.searchUser,
                  onTap: () => showMixinDialog<String>(
                    context: context,
                    child: const _SearchUserDialog(),
                  ),
                ),
                ContextMenu(
                  title: context.l10n.createConversation,
                  onTap: () async {
                    final list = await showConversationSelector(
                      context: context,
                      singleSelect: true,
                      title: context.l10n.createConversation,
                      onlyContact: true,
                    );
                    if (list == null ||
                        list.isEmpty ||
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
                  title: context.l10n.createGroupConversation,
                  onTap: () async {
                    final result = await showConversationSelector(
                      context: context,
                      singleSelect: false,
                      title: context.l10n.createGroupConversation,
                      onlyContact: true,
                    );
                    if (result == null || result.isEmpty) return;
                    final userIds = result
                        .where((e) => e.userId != null)
                        .map(
                          (e) => e.userId!,
                        )
                        .toList();

                    final name = await showMixinDialog<String>(
                      context: context,
                      child: _NewConversationConfirm(
                          [context.accountServer.userId, ...userIds]),
                    );
                    if (name?.isEmpty ?? true) return;

                    await runFutureWithToast(
                      context,
                      context.accountServer
                          .createGroupConversation(name!, userIds),
                    );
                  },
                ),
                ContextMenu(
                  title: context.l10n.createCircle,
                  onTap: () async {
                    final name = await showMixinDialog<String>(
                      context: context,
                      child: EditDialog(
                        title: Text(context.l10n.circles),
                        hintText: context.l10n.editCircleName,
                      ),
                    );

                    if (name?.isEmpty ?? true) return;

                    final list = await showConversationSelector(
                      context: context,
                      singleSelect: false,
                      title: context.l10n.createCircle,
                      onlyContact: false,
                      allowEmpty: true,
                    );

                    if (list == null) return;

                    await runFutureWithToast(
                      context,
                      context.accountServer.createCircle(
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
                    onTapUp: (event) =>
                        context.sendMenuPosition(event.globalPosition),
                    color: context.theme.icon,
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
      () => context.database.userDao
          .usersByIn(userIds.sublist(0, min(4, userIds.length)))
          .get(),
      <User>[],
    ).requireData;

    final textEditingController = useTextEditingController();
    final textEditingValue = useValueListenable(textEditingController);
    return AlertDialogLayout(
      title: Text(context.l10n.groups),
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
            context.l10n.participantsCount(userIds.length),
            style: TextStyle(
              fontSize: 14,
              color: context.theme.secondaryText,
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
            child: Text(context.l10n.cancel)),
        MixinButton(
          disable: textEditingValue.text.isEmpty,
          onTap: () => Navigator.pop(context, textEditingController.text),
          child: Text(context.l10n.create),
        ),
      ],
    );
  }
}

class _SearchIntent extends Intent {
  const _SearchIntent();
}

class _SearchUserDialog extends HookWidget {
  const _SearchUserDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentIdentityNumber = context.multiAuthState.currentIdentityNumber;

    final textEditingController = useTextEditingController();
    final textEditingValueStream =
        useValueNotifierConvertSteam(textEditingController);
    final searchable = useMemoizedStream(() => textEditingValueStream.map(
                (event) =>
                    event.text.trim().length > 3 && event.composing.composed))
            .data ??
        false;

    final loading = useState(false);
    final resultUserId = useState<String?>(null);

    Future<void> search() async {
      if (!searchable) return;

      loading.value = true;
      try {
        final mixinResponse = await context.accountServer.client.userApi
            .search(textEditingController.text);
        await context.database.userDao.insertSdkUser(mixinResponse.data);
        resultUserId.value = mixinResponse.data.userId;
      } catch (e) {
        unawaited(
            showToastFailed(context, ToastError(context.l10n.userNotFound)));
      }

      loading.value = false;
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Builder(
        builder: (BuildContext context) {
          if (resultUserId.value?.isNotEmpty ?? false) {
            return UserDialog(
              userId: resultUserId.value!,
            );
          }

          return Stack(
            children: [
              Visibility(
                visible: !loading.value,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: AlertDialogLayout(
                  title: Text(context.l10n.addContact),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FocusableActionDetector(
                        autofocus: true,
                        shortcuts: {
                          if (searchable)
                            const SingleActivator(LogicalKeyboardKey.enter):
                                const _SearchIntent(),
                        },
                        actions: {
                          _SearchIntent: CallbackAction<Intent>(
                            onInvoke: (Intent intent) => search(),
                          ),
                        },
                        child: DialogTextField(
                          textEditingController: textEditingController,
                          hintText: context.l10n.searchUserHint,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp('[0-9+]'))
                          ],
                        ),
                      ),
                      if (currentIdentityNumber?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            context.l10n
                                .currentIdentityNumber(currentIdentityNumber!),
                            style: TextStyle(
                              color: context.theme.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    MixinButton(
                        backgroundTransparent: true,
                        onTap: () => Navigator.pop(context),
                        child: Text(context.l10n.cancel)),
                    MixinButton(
                      disable: !searchable,
                      onTap: search,
                      child: Text(context.l10n.search),
                    ),
                  ],
                ),
              ),
              if (loading.value)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    child:
                        CircularProgressIndicator(color: context.theme.accent),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
