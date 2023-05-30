import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../bloc/keyword_cubit.dart';
import '../constants/constants.dart';
import '../constants/resources.dart';
import '../ui/home/bloc/conversation_filter_unseen_cubit.dart';
import '../ui/home/home.dart';
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

class SearchBar extends HookWidget {
  const SearchBar({super.key});

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

    final filterUnseen = useBlocState<ConversationFilterUnseenCubit, bool>();

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
                        context.read<KeywordCubit>().emit('');
                        context.read<TextEditingController>().text = '';
                        context.read<FocusNode>().unfocus();
                      },
                    )
                  },
                  child: Builder(
                      builder: (context) => SearchTextField(
                            focusNode: context.read<FocusNode>(),
                            controller: context.read<TextEditingController>(),
                            onChanged: (keyword) =>
                                context.read<KeywordCubit>().emit(keyword),
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
              onTap: () =>
                  context.read<ConversationFilterUnseenCubit>().toggle(),
              color: filterUnseen ? context.theme.accent : context.theme.icon,
            ),
            const SizedBox(width: 4),
            ContextMenuPortalEntry(
              buildMenus: () => [
                ContextMenu(
                  icon: Resources.assetsImagesContextMenuSearchUserSvg,
                  title: context.l10n.searchContact,
                  onTap: () => showMixinDialog<String>(
                    context: context,
                    child: const _SearchUserDialog(),
                  ),
                ),
                ContextMenu(
                  icon: Resources.assetsImagesContextMenuCreateConversationSvg,
                  title: context.l10n.createConversation,
                  onTap: () {
                    Actions.maybeInvoke(
                      context,
                      const CreateConversationIntent(),
                    );
                  },
                ),
                ContextMenu(
                  icon: Resources.assetsImagesContextMenuCreateGroupSvg,
                  title: context.l10n.createGroup,
                  onTap: () async {
                    Actions.maybeInvoke(
                      context,
                      const CreateGroupConversationIntent(),
                    );
                  },
                ),
                ContextMenu(
                  icon: Resources.assetsImagesCircleSvg,
                  title: context.l10n.createCircle,
                  onTap: () async {
                    Actions.maybeInvoke(
                      context,
                      const CreateCircleIntent(),
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

class _SearchIntent extends Intent {
  const _SearchIntent();
}

class _SearchUserDialog extends HookWidget {
  const _SearchUserDialog();

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
