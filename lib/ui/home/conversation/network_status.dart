import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../../blaze/blaze.dart';
import '../../../constants/resources.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/file.dart';
import '../../../utils/hook.dart';
import '../../../utils/uri_utils.dart';

class NetworkStatus extends HookConsumerWidget {
  const NetworkStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectedState = useMemoizedStream(
            () => context.accountServer.connectedStateStream.distinct(),
            initialData: ConnectedState.connecting)
        .requireData;

    final hasDisconnectedBefore = useRef(false);

    useEffect(() {
      if (connectedState == ConnectedState.disconnected) {
        hasDisconnectedBefore.value = true;
      }
    }, [connectedState]);

    return Column(
      children: [
        ContextMenuWidget(
          menuProvider: (request) => Menu(children: [
            MenuAction(
              title: context.l10n.openLogDirectory,
              callback: () =>
                  openUri(context, mixinLogDirectory.uri.toString()),
            ),
          ]),
          child: _NetworkNotConnect(
            visible: connectedState != ConnectedState.connected &&
                hasDisconnectedBefore.value,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          child: connectedState == ConnectedState.connecting ||
                  connectedState == ConnectedState.reconnecting
              ? LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: context.theme.accent,
                  minHeight: 2,
                )
              : const SizedBox(),
        ),
      ],
    );
  }
}

class _NetworkNotConnect extends StatelessWidget {
  const _NetworkNotConnect({
    required this.visible,
  });

  final bool visible;

  @override
  Widget build(BuildContext context) {
    Widget child;
    child = visible
        ? Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
            color: context.theme.warning.withOpacity(0.2),
            child: Row(children: [
              ClipOval(
                child: Container(
                  color: context.theme.warning,
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
                    color: context.theme.text,
                    fontSize: 14,
                  ),
                  child: Row(
                    children: [
                      Text(context.l10n.networkConnectionFailed),
                      const Spacer(),
                      MouseRegion(
                        cursor: MaterialStateMouseCursor.clickable,
                        child: GestureDetector(
                          onTap: () {
                            i('ui: click reconnect');
                            context.accountServer.reconnectBlaze();
                          },
                          child: Text(
                            context.l10n.retry,
                            style: TextStyle(color: context.theme.accent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ]))
        : const SizedBox();

    return AnimatedSize(
      alignment: Alignment.topCenter,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 200),
      child: child,
    );
  }
}
