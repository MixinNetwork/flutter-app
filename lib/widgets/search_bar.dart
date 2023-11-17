import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../constants/constants.dart';
import '../constants/resources.dart';
import '../ui/home/home.dart';
import '../ui/provider/conversation_unseen_filter_enabled.dart';
import '../ui/provider/keyword_provider.dart';
import '../utils/extension/extension.dart';
import '../utils/hook.dart';
import 'action_button.dart';
import 'actions/actions.dart';
import 'dialog.dart';
import 'menu.dart';
import 'search_text_field.dart';
import 'toast.dart';
import 'user/user_dialog.dart';
import 'window/move_window.dart';

enum _ActionType {
  searchContact,
  createConversation,
  createGroup,
  createCircle,
}

class SearchBar extends HookConsumerWidget {
  const SearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final filterUnseen = ref.watch(conversationUnseenFilterEnabledProvider);

    return MoveWindow(
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 150),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: leading ?? const SizedBox(width: 16),
              ),
            ),
            Expanded(
              child: MoveWindowBarrier(
                child: FocusableActionDetector(
                  shortcuts: const {
                    SingleActivator(LogicalKeyboardKey.escape): EscapeIntent(),
                  },
                  actions: {
                    EscapeIntent: CallbackAction<EscapeIntent>(
                      onInvoke: (intent) {
                        ref.read(keywordProvider.notifier).state = '';
                        context.read<TextEditingController>().text = '';
                        context.read<FocusNode>().unfocus();
                      },
                    )
                  },
                  child: Builder(
                      builder: (context) => SearchTextField(
                            focusNode: context.read<FocusNode>(),
                            controller: context.read<TextEditingController>(),
                            onChanged: (keyword) => ref
                                .read(keywordProvider.notifier)
                                .state = keyword,
                            hintText: filterUnseen
                                ? context.l10n.searchUnread
                                // ignore: avoid-non-ascii-symbols
                                : '${context.l10n.search} (${Platform.isMacOS || Platform.isIOS ? '⌘' : 'Ctrl '}K)',
                          )),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ActionButton(
              name: Resources.assetsImagesFilterUnseenSvg,
              onTap: () => ref
                  .read(conversationUnseenFilterEnabledProvider.notifier)
                  .toggle(),
              color: filterUnseen ? context.theme.accent : context.theme.icon,
            ),
            const SizedBox(width: 4),
            CustomPopupMenuButton(
              itemBuilder: (context) => [
                CustomPopupMenuItem(
                  icon: Resources.assetsImagesContextMenuSearchUserSvg,
                  title: context.l10n.searchContact,
                  value: _ActionType.searchContact,
                ),
                CustomPopupMenuItem(
                  icon: Resources.assetsImagesContextMenuCreateConversationSvg,
                  title: context.l10n.createConversation,
                  value: _ActionType.createConversation,
                ),
                CustomPopupMenuItem(
                  icon: Resources.assetsImagesContextMenuCreateGroupSvg,
                  title: context.l10n.createGroup,
                  value: _ActionType.createGroup,
                ),
                CustomPopupMenuItem(
                  icon: Resources.assetsImagesCircleSvg,
                  title: context.l10n.createCircle,
                  value: _ActionType.createCircle,
                ),
              ],
              onSelected: (type) {
                switch (type) {
                  case _ActionType.searchContact:
                    showMixinDialog<String>(
                      context: context,
                      child: const _SearchUserDialog(),
                    );
                  case _ActionType.createConversation:
                    Actions.maybeInvoke(
                      context,
                      const CreateConversationIntent(),
                    );
                  case _ActionType.createGroup:
                    Actions.maybeInvoke(
                      context,
                      const CreateGroupConversationIntent(),
                    );
                  case _ActionType.createCircle:
                    Actions.maybeInvoke(
                      context,
                      const CreateCircleIntent(),
                    );
                }
              },
              icon: Resources.assetsImagesIcAddSvg,
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _SearchIntent extends Intent {
  const _SearchIntent();
}

class _SearchUserDialog extends HookConsumerWidget {
  const _SearchUserDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIdentityNumber = context.account?.identityNumber;

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
        showToastFailed(ToastError(context.l10n.userNotFound));
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
                          hintText: context.l10n.addPeopleSearchHint,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp('[0-9+]')),
                            LengthLimitingTextInputFormatter(
                              kDefaultTextInputLimit,
                            ),
                          ],
                        ),
                      ),
                      if (currentIdentityNumber?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            context.l10n.myMixinId(currentIdentityNumber!),
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
