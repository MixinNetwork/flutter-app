import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:window_manager/window_manager.dart';

import '../../account/account_server.dart';
import '../../ui/home/bloc/multi_auth_cubit.dart';
import '../../ui/home/bloc/slide_category_cubit.dart';
import '../../ui/home/conversation/conversation_hotkey.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/uri_utils.dart';
import '../actions/actions.dart';

abstract class ConversationMenuHandle {
  Stream<bool> get isMuted;

  Stream<bool> get isPinned;

  void mute();

  void unmute();

  void showSearch();

  void pin();

  void unPin();

  void toggleSideBar();

  void delete();
}

class MacMenuBarCubitState with EquatableMixin {
  const MacMenuBarCubitState({
    this.conversationMenuHandle,
  });

  final ConversationMenuHandle? conversationMenuHandle;

  @override
  List<Object?> get props => [conversationMenuHandle];
}

class MacMenuBarCubit extends Cubit<MacMenuBarCubitState> {
  MacMenuBarCubit() : super(const MacMenuBarCubitState());

  void attach(ConversationMenuHandle handle) {
    emit(MacMenuBarCubitState(conversationMenuHandle: handle));
  }

  void unAttach(ConversationMenuHandle handle) {
    if (state.conversationMenuHandle == handle) {
      emit(const MacMenuBarCubitState());
    }
  }
}

class MacosMenuBar extends StatelessWidget {
  const MacosMenuBar({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isMacOS) {
      return child;
    }
    return _Menus(child: child);
  }
}

class _Menus extends HookWidget {
  const _Menus({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final authAvailable =
        useBlocState<MultiAuthCubit, MultiAuthState>().current != null;
    AccountServer? accountServer;
    try {
      accountServer = context.read<AccountServer?>();
    } catch (_) {}
    final signed = authAvailable && accountServer != null;

    final menuCubit = useBloc<MacMenuBarCubit>(MacMenuBarCubit.new);

    final handle = useBlocStateConverter<MacMenuBarCubit, MacMenuBarCubitState,
        ConversationMenuHandle?>(
      converter: (state) => state.conversationMenuHandle,
      bloc: menuCubit,
    );

    final muted = useMemoizedStream(
          () => handle?.isMuted ?? const Stream<bool>.empty(),
          keys: [handle],
        ).data ??
        false;

    final pinned = useMemoizedStream(
          () => handle?.isPinned ?? const Stream<bool>.empty(),
          keys: [handle],
        ).data ??
        false;

    PlatformMenu buildConversationMenu() => PlatformMenu(
          label: context.l10n.conversation,
          menus: [
            if (muted)
              PlatformMenuItem(
                label: context.l10n.unmute,
                onSelected: handle?.unmute,
              )
            else
              PlatformMenuItem(
                label: context.l10n.mute,
                onSelected: handle?.mute,
              ),
            PlatformMenuItem(
              label: context.l10n.search,
              onSelected: handle?.showSearch,
            ),
            PlatformMenuItem(
              label: context.l10n.deleteChat,
              onSelected: handle?.delete,
            ),
            if (pinned)
              PlatformMenuItem(
                label: context.l10n.unpin,
                onSelected: handle?.unPin,
              )
            else
              PlatformMenuItem(
                label: context.l10n.pinTitle,
                onSelected: handle?.pin,
              ),
            PlatformMenuItem(
              label: context.l10n.toggleChatInfo,
              onSelected: handle?.toggleSideBar,
            ),
          ],
        );

    const methodChannel = MethodChannel('mixin_desktop/platform_menus');

    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'Mixin',
          menus: [
            PlatformMenuItemGroup(members: [
              PlatformMenuItem(
                label: '${context.l10n.about} Mixin',
                onSelected: () => methodChannel.invokeMethod('showAbout'),
              ),
            ]),
            PlatformMenuItemGroup(members: [
              PlatformMenuItem(
                label: context.l10n.preferences,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.comma,
                  meta: true,
                ),
                onSelected: signed
                    ? () {
                        windowManager.show();
                        context
                            .read<SlideCategoryCubit>()
                            .select(SlideCategoryType.setting);
                      }
                    : null,
              ),
            ]),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: context.l10n.quickSearch,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyK,
                    meta: true,
                  ),
                  onSelected: signed
                      ? () {
                          Actions.invoke<ToggleCommandPaletteIntent>(
                            context,
                            const ToggleCommandPaletteIntent(),
                          );
                        }
                      : null,
                ),
                PlatformMenuItem(
                  label: context.l10n.hideMixin,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyH,
                    meta: true,
                  ),
                  onSelected: windowManager.hide,
                ),
                PlatformMenuItem(
                  label: context.l10n.showMixin,
                  onSelected: windowManager.show,
                ),
              ],
            ),
            PlatformMenuItem(
              label: context.l10n.quitMixin,
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyQ,
                meta: true,
              ),
              onSelected: () => exit(0),
            ),
          ],
        ),
        PlatformMenu(
          label: context.l10n.file,
          menus: [
            PlatformMenuItemGroup(members: [
              PlatformMenuItem(
                label: context.l10n.createConversation,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyN,
                  meta: true,
                ),
                onSelected: signed
                    ? () {
                        windowManager.show();
                        Actions.invoke<CreateConversationIntent>(
                          context,
                          const CreateConversationIntent(),
                        );
                      }
                    : null,
              ),
              PlatformMenuItem(
                label: context.l10n.createGroup,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyN,
                  shift: true,
                  meta: true,
                ),
                onSelected: signed
                    ? () {
                        windowManager.show();
                        Actions.invoke<CreateGroupConversationIntent>(
                          context,
                          const CreateGroupConversationIntent(),
                        );
                      }
                    : null,
              ),
              PlatformMenuItem(
                label: context.l10n.createCircle,
                onSelected: signed
                    ? () {
                        windowManager.show();
                        Actions.invoke<CreateCircleIntent>(
                          context,
                          const CreateCircleIntent(),
                        );
                      }
                    : null,
              ),
              PlatformMenuItemGroup(members: [
                PlatformMenuItem(
                  label: context.l10n.closeWindow,
                  onSelected: windowManager.close,
                )
              ]),
            ]),
          ],
        ),
        buildConversationMenu(),
        PlatformMenu(
          label: context.l10n.window,
          menus: [
            PlatformMenuItem(
              label: context.l10n.minimize,
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyM,
                meta: true,
              ),
              onSelected: windowManager.minimize,
            ),
            PlatformMenuItem(
              label: context.l10n.zoom,
              onSelected: () async => !await windowManager.isMaximized()
                  ? windowManager.maximize()
                  : windowManager.restore(),
            ),
            PlatformMenuItemGroup(members: [
              PlatformMenuItem(
                label: context.l10n.previousConversation,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.arrowUp,
                  meta: true,
                ),
                onSelected: signed
                    ? () {
                        Actions.maybeInvoke(
                          context,
                          const PreviousConversationIntent(),
                        );
                      }
                    : null,
              ),
              PlatformMenuItem(
                label: context.l10n.nextConversation,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.arrowDown,
                  meta: true,
                ),
                onSelected: signed
                    ? () {
                        Actions.maybeInvoke(
                            context, const NextConversationIntent());
                      }
                    : null,
              ),
            ]),
            PlatformMenuItemGroup(members: [
              PlatformMenuItem(
                label: 'Mixin',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyO,
                  meta: true,
                ),
                onSelected: windowManager.show,
              ),
            ]),
            PlatformMenuItemGroup(members: [
              PlatformMenuItem(
                label: context.l10n.bringAllToFront,
                onSelected: windowManager.show,
              ),
            ]),
            PlatformMenuItem(
              label: 'Mixin',
              onSelected: windowManager.show,
            ),
          ],
        ),
        PlatformMenu(
          label: context.l10n.help,
          menus: [
            PlatformMenuItem(
              label: context.l10n.helpCenter,
              onSelected: () =>
                  openUri(context, 'https://mixinmessenger.zendesk.com'),
            ),
            PlatformMenuItem(
              label: context.l10n.termsOfService,
              onSelected: () =>
                  openUri(context, 'https://mixin.one/pages/terms'),
            ),
            PlatformMenuItem(
              label: context.l10n.privacyPolicy,
              onSelected: () =>
                  openUri(context, 'https://mixin.one/pages/privacy'),
            ),
          ],
        ),
      ],
      child: BlocProvider.value(value: menuCubit, child: child),
    );
  }
}
