import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../account/account_server.dart';
import '../../ui/home/bloc/multi_auth_cubit.dart';
import '../../ui/home/bloc/slide_category_cubit.dart';
import '../../ui/home/command_palette_wrapper.dart';
import '../../ui/home/conversation/conversation_hotkey.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/uri_utils.dart';

class MacosMenuBar extends StatelessWidget {
  const MacosMenuBar({
    Key? key,
    required this.child,
  }) : super(key: key);

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
  const _Menus({Key? key, required this.child}) : super(key: key);

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
    return PlatformMenuBar(
      body: child,
      menus: [
        PlatformMenu(
          label: 'Mixin',
          menus: [
            PlatformMenuItemGroup(members: [
              PlatformMenuItem(
                label: '${context.l10n.about} Mixin',
                onSelected: () {
                  appWindow.show();
                  showAboutDialog(context: context);
                },
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
                        appWindow.show();
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
                  onSelected: () {
                    Actions.invoke<ToggleCommandPaletteIntent>(
                      context,
                      const ToggleCommandPaletteIntent(),
                    );
                  },
                ),
                PlatformMenuItem(
                  label: context.l10n.hideMixin,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyH,
                    meta: true,
                  ),
                  onSelected: () {
                    appWindow.hide();
                  },
                ),
                PlatformMenuItem(
                  label: context.l10n.showMixin,
                  onSelected: () {
                    appWindow.show();
                  },
                ),
              ],
            ),
            PlatformMenuItem(
              label: context.l10n.quitMixin,
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyQ,
                meta: true,
              ),
              onSelected: () {
                exit(0);
              },
            ),
          ],
        ),
        PlatformMenu(
          label: context.l10n.window,
          menus: [
            PlatformMenuItem(
              label: context.l10n.minimize,
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyM,
                meta: true,
              ),
              onSelected: () {
                appWindow.minimize();
              },
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
            PlatformMenuItem(
              label: 'Mixin',
              onSelected: () {
                appWindow.show();
              },
            ),
          ],
        ),
        PlatformMenu(
          label: context.l10n.help,
          menus: [
            PlatformMenuItem(
              label: context.l10n.helpCenter,
              onSelected: () {
                openUri(context, 'https://mixinmessenger.zendesk.com');
              },
            ),
            PlatformMenuItem(
              label: context.l10n.termsService,
              onSelected: () {
                openUri(context, 'https://mixin.one/pages/terms');
              },
            ),
            PlatformMenuItem(
              label: context.l10n.privacyPolicy,
              onSelected: () {
                openUri(context, 'https://mixin.one/pages/privacy');
              },
            ),
          ],
        ),
      ],
    );
  }
}
