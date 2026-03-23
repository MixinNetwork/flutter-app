import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../account/security_key_value.dart';
import '../../ui/home/conversation/conversation_hotkey.dart';
import '../../ui/provider/account_server_provider.dart';
import '../../ui/provider/slide_category_provider.dart';
import '../../ui/provider/ui_context_providers.dart';
import '../../utils/device_transfer/device_transfer_dialog.dart';
import '../../utils/event_bus.dart';
import '../../utils/uri_utils.dart';
import '../actions/actions.dart';
import '../auth.dart';

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

class MacMenuBarStateNotifier extends Notifier<ConversationMenuHandle?> {
  @override
  ConversationMenuHandle? build() => null;

  void attach(ConversationMenuHandle handle) {
    if (!Platform.isMacOS) return;
    Future(() => state = handle);
  }

  void unAttach(ConversationMenuHandle handle) {
    if (!Platform.isMacOS) return;
    if (state != handle) return;
    state = null;
  }
}

final macMenuBarProvider =
    NotifierProvider<MacMenuBarStateNotifier, ConversationMenuHandle?>(
      MacMenuBarStateNotifier.new,
    );

class MacosMenuBar extends ConsumerWidget {
  const MacosMenuBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isMacOS) {
      return child;
    }
    return _Menus(child: child);
  }
}

class _Menus extends ConsumerWidget {
  const _Menus({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final signed = ref.watch(
      accountServerProvider.select((value) => value.hasValue),
    );

    final handle = ref.watch(macMenuBarProvider);

    final muted = ref.watch(_macMenuMutedProvider).value ?? false;
    final pinned = ref.watch(_macMenuPinnedProvider).value ?? false;
    final hasPasscode =
        ref.watch(_macMenuHasPasscodeProvider(signed)).value ?? false;

    PlatformMenu buildConversationMenu() => PlatformMenu(
      label: l10n.conversation,
      menus: [
        if (muted)
          PlatformMenuItem(
            label: l10n.unmute,
            onSelected: handle?.unmute,
          )
        else
          PlatformMenuItem(label: l10n.mute, onSelected: handle?.mute),
        PlatformMenuItem(
          label: l10n.search,
          onSelected: handle?.showSearch,
        ),
        PlatformMenuItem(
          label: l10n.deleteChat,
          onSelected: handle?.delete,
        ),
        if (pinned)
          PlatformMenuItem(label: l10n.unpin, onSelected: handle?.unPin)
        else
          PlatformMenuItem(label: l10n.pinTitle, onSelected: handle?.pin),
        PlatformMenuItem(
          label: l10n.toggleChatInfo,
          onSelected: handle?.toggleSideBar,
        ),
      ],
    );

    const methodChannel = MethodChannel('mixin_desktop/platform_menus');

    final menus = [
      PlatformMenu(
        label: 'Mixin',
        menus: [
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: '${l10n.about} Mixin',
                onSelected: () => methodChannel.invokeMethod('showAbout'),
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: l10n.preferences,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.comma,
                  meta: true,
                ),
                onSelected: signed
                    ? () {
                        windowManager.show();
                        ref
                            .read(slideCategoryProvider.notifier)
                            .select(SlideCategoryType.setting);
                      }
                    : null,
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: l10n.lock,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyL,
                  meta: true,
                  shift: true,
                ),
                onSelected: hasPasscode
                    ? () => EventBus.instance.fire(LockEvent.lock)
                    : null,
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: l10n.quickSearch,
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
                label: l10n.hideMixin,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyH,
                  meta: true,
                ),
                onSelected: windowManager.hide,
              ),
              PlatformMenuItem(
                label: l10n.showMixin,
                onSelected: windowManager.show,
              ),
            ],
          ),
          PlatformMenuItem(
            label: l10n.quitMixin,
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyQ,
              meta: true,
            ),
            onSelected: () => exit(0),
          ),
        ],
      ),
      PlatformMenu(
        label: l10n.file,
        menus: [
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: l10n.createConversation,
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
                label: l10n.createGroup,
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
              if (kDebugMode)
                PlatformMenuItemGroup(
                  members: [
                    PlatformMenuItem(
                      label: 'chat backup and restore',
                      onSelected: signed
                          ? () {
                              showDeviceTransferDialog(context);
                            }
                          : null,
                    ),
                  ],
                ),
              PlatformMenuItem(
                label: l10n.createCircle,
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
              PlatformMenuItemGroup(
                members: [
                  PlatformMenuItem(
                    label: l10n.closeWindow,
                    onSelected: windowManager.close,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      buildConversationMenu(),
      PlatformMenu(
        label: l10n.window,
        menus: [
          PlatformMenuItem(
            label: l10n.minimize,
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyM,
              meta: true,
            ),
            onSelected: windowManager.minimize,
          ),
          PlatformMenuItem(
            label: l10n.zoom,
            onSelected: () async => !await windowManager.isMaximized()
                ? windowManager.maximize()
                : windowManager.restore(),
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: l10n.previousConversation,
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
                label: l10n.nextConversation,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.arrowDown,
                  meta: true,
                ),
                onSelected: signed
                    ? () {
                        Actions.maybeInvoke(
                          context,
                          const NextConversationIntent(),
                        );
                      }
                    : null,
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: 'Mixin',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyO,
                  meta: true,
                ),
                onSelected: windowManager.show,
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: l10n.bringAllToFront,
                onSelected: windowManager.show,
              ),
            ],
          ),
          PlatformMenuItem(label: 'Mixin', onSelected: windowManager.show),
        ],
      ),
      PlatformMenu(
        label: l10n.help,
        menus: [
          PlatformMenuItem(
            label: l10n.helpCenter,
            onSelected: () => openUri(
              context,
              'https://support.mixin.one/',
              container: ref.container,
            ),
          ),
          PlatformMenuItem(
            label: l10n.termsOfService,
            onSelected: () => openUri(
              context,
              'https://mixin.one/pages/terms',
              container: ref.container,
            ),
          ),
          PlatformMenuItem(
            label: l10n.privacyPolicy,
            onSelected: () => openUri(
              context,
              'https://mixin.one/pages/privacy',
              container: ref.container,
            ),
          ),
        ],
      ),
    ];

    WidgetsBinding.instance.platformMenuDelegate.setMenus(menus);

    return child;
  }
}

final _macMenuMutedProvider = StreamProvider.autoDispose<bool>((ref) {
  final handle = ref.watch(macMenuBarProvider);
  return handle?.isMuted ?? Stream.value(false);
});

final _macMenuPinnedProvider = StreamProvider.autoDispose<bool>((ref) {
  final handle = ref.watch(macMenuBarProvider);
  return handle?.isPinned ?? Stream.value(false);
});

final _macMenuHasPasscodeProvider = StreamProvider.autoDispose
    .family<bool, bool>((ref, signed) {
      if (!signed) {
        return Stream.value(false);
      }
      return SecurityKeyValue.instance.watchHasPasscode();
    });
