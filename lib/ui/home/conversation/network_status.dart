import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

import '../../../blaze/blaze.dart';
import '../../../constants/resources.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/file.dart';
import '../../../utils/hook.dart';
import '../../../utils/uri_utils.dart';
import '../../../widgets/menu.dart';

class NetworkStatus extends HookWidget {
  const NetworkStatus({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final connectedState = useMemoizedStream(
            () => context.accountServer.connectedStateStream
                .map((event) => event == ConnectedState.connected)
                .distinct(),
            initialData: true)
        .requireData;
    return ContextMenuPortalEntry(
      buildMenus: () => [
        ContextMenu(
          title: context.l10n.openLogDirectory,
          onTap: () {
            openUri(context, mixinLogDirectory.uri.toString());
          },
        ),
      ],
      child: _NetworkNotConnect(visible: !connectedState),
    );
  }
}

class _NetworkNotConnect extends StatelessWidget {
  const _NetworkNotConnect({
    Key? key,
    required this.visible,
  }) : super(key: key);

  final bool visible;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (visible) {
      child = Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
        color: context.theme.warning.withOpacity(0.2),
        child: Row(
          children: [
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
                    color: Colors.white,
                    width: 2,
                    height: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              context.l10n.networkConnectionFailed,
              style: TextStyle(
                color: context.theme.text,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    } else {
      child = const SizedBox();
    }

    return AnimatedSize(
      alignment: Alignment.topCenter,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 200),
      child: child,
    );
  }
}
