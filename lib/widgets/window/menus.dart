import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../ui/home/conversation/conversation_hotkey.dart';
import '../../ui/provider/account/account_server_provider.dart';
import '../../ui/provider/menu_handle_provider.dart';
import '../../ui/provider/slide_category_provider.dart';
import '../../utils/device_transfer/device_transfer_dialog.dart';
import '../../utils/event_bus.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/uri_utils.dart';
import '../actions/actions.dart';
import '../auth.dart';

class MacosMenuBar extends HookConsumerWidget {
  const MacosMenuBar({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isMacOS) {
      return child;
    }
    return _Menus(child: child);
  }
}

class _Menus extends HookConsumerWidget {
  const _Menus({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signed =
        ref.watch(accountServerProvider.select((value) => value.hasValue));

    final handle = ref.watch(macMenuBarProvider);

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

    final hasPasscode = useMemoizedStream(
          () => handle?.hasPasscode ?? const Stream<bool>.empty(),
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

    final menus = [
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
                      ref
                          .read(slideCategoryStateProvider.notifier)
                          .select(SlideCategoryType.setting);
                    }
                  : null,
            ),
          ]),
          PlatformMenuItemGroup(members: [
            PlatformMenuItem(
              label: context.l10n.lock,
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyL,
                meta: true,
                shift: true,
              ),
              onSelected: hasPasscode
                  ? () => EventBus.instance.fire(LockEvent.lock)
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
            if (kDebugMode)
              PlatformMenuItemGroup(members: [
                PlatformMenuItem(
                  label: 'chat backup and restore',
                  onSelected: signed
                      ? () {
                          showDeviceTransferDialog(context);
                        }
                      : null,
                )
              ]),
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
            onSelected: () => openUri(context, 'https://mixin.one/pages/terms'),
          ),
          PlatformMenuItem(
            label: context.l10n.privacyPolicy,
            onSelected: () =>
                openUri(context, 'https://mixin.one/pages/privacy'),
          ),
        ],
      ),
    ];

    useEffect(() {
      WidgetsBinding.instance.platformMenuDelegate.setMenus(menus);
    }, [menus]);

    return child;
  }
}
