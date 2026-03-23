import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../../blaze/blaze.dart';
import '../../../constants/resources.dart';
import '../../../ui/provider/account_server_provider.dart';
import '../../../ui/provider/ui_context_providers.dart';
import '../../../utils/file.dart';
import '../../../utils/uri_utils.dart';
import '../../../widgets/menu.dart';

class NetworkStatus extends HookConsumerWidget {
  const NetworkStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final connectedState = ref.watch(
      appRuntimeHubProvider.select(
        (value) => value.connectedState ?? ConnectedState.connecting,
      ),
    );

    final hasDisconnectedBefore = useRef(false);

    useEffect(() {
      if (connectedState == ConnectedState.disconnected) {
        hasDisconnectedBefore.value = true;
      }
    }, [connectedState]);

    return Column(
      children: [
        CustomContextMenuWidget(
          desktopMenuWidgetBuilder: CustomDesktopMenuWidgetBuilder(),
          menuProvider: (request) => Menu(
            children: [
              MenuAction(
                title: l10n.openLogDirectory,
                callback: () => openUri(
                  context,
                  mixinLogDirectory.uri.toString(),
                  container: ref.container,
                ),
              ),
            ],
          ),
          child: _NetworkNotConnect(
            visible:
                connectedState != ConnectedState.connected &&
                hasDisconnectedBefore.value,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          child:
              connectedState == ConnectedState.connecting ||
                  connectedState == ConnectedState.reconnecting
              ? LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: theme.accent,
                  minHeight: 2,
                )
              : const SizedBox(),
        ),
      ],
    );
  }
}

class _NetworkNotConnect extends ConsumerWidget {
  const _NetworkNotConnect({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    Widget child;
    child = visible
        ? Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
            color: theme.warning.withValues(alpha: 0.2),
            child: Row(
              children: [
                ClipOval(
                  child: Container(
                    color: theme.warning,
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 2,
                      height: 10,
                      child: SvgPicture.asset(
                        Resources.assetsImagesExclamationMarkSvg,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                        width: 2,
                        height: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 14,
                    ),
                    child: Row(
                      children: [
                        Text(l10n.networkConnectionFailed),
                        const Spacer(),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              i('ui: click reconnect');
                              ref
                                  .read(accountServerProvider)
                                  .requireValue
                                  .reconnectBlaze();
                            },
                            child: Text(
                              l10n.retry,
                              style: TextStyle(
                                color: theme.accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox();

    return AnimatedSize(
      alignment: Alignment.topCenter,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 200),
      child: child,
    );
  }
}
