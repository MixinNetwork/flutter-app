import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../constants/resources.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cell.dart';
import '../../widgets/dialog.dart';
import '../event_bus.dart';
import '../extension/extension.dart';
import 'device_transfer_widget.dart';

Future<void> showDeviceTransferDialog(
  BuildContext context, {
  bool showRestore = true,
}) async =>
    showMixinDialog(
      context: context,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Material(
          color: Colors.transparent,
          child: Navigator(
            pages: const [
              MaterialPage<void>(
                child: _DeviceTransferPage(),
              ),
            ],
            onPopPage: (route, result) => true,
          ),
        ),
      ),
    );

class _DeviceTransferPage extends StatelessWidget {
  const _DeviceTransferPage();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MixinAppBar(
            backgroundColor: Colors.transparent,
            title: Text(context.l10n.chatBackupAndRestore),
            leading: const SizedBox.shrink(),
            actions: [
              MixinCloseButton(
                onTap: () =>
                    Navigator.maybeOf(context, rootNavigator: true)?.pop(),
              ),
            ],
          ),
          CellGroup(
            child: CellItem(
              title: Text(context.l10n.restoreFromOtherDevice),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const _RestorePage()));
              },
            ),
          ),
          CellGroup(
            child: CellItem(
              title: Text(context.l10n.backupToOtherDevice),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const _BackupPage()));
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      );
}

class _RestorePage extends StatelessWidget {
  const _RestorePage();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          MixinAppBar(
            backgroundColor: Colors.transparent,
            title: Text(context.l10n.restoreFromOtherDevice),
            actions: [
              MixinCloseButton(
                onTap: () =>
                    Navigator.maybeOf(context, rootNavigator: true)?.pop(),
              ),
            ],
          ),
          const SizedBox(height: 60),
          SvgPicture.asset(Resources.assetsImagesDeviceTransferSvg),
          const SizedBox(height: 36),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              context.l10n.restoreChatTips,
              style: TextStyle(
                color: context.theme.secondaryText,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          CellGroup(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CellItem(
              title: Text(context.l10n.restoreChat),
              color: context.theme.accent,
              trailing: null,
              onTap: () {
                EventBus.instance.fire(DeviceTransferCommand.pullToRemote);
              },
            ),
          )
        ],
      );
}

class _BackupPage extends StatelessWidget {
  const _BackupPage();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          MixinAppBar(
            backgroundColor: Colors.transparent,
            title: Text(context.l10n.backupToOtherDevice),
            actions: [
              MixinCloseButton(
                onTap: () =>
                    Navigator.maybeOf(context, rootNavigator: true)?.pop(),
              ),
            ],
          ),
          const SizedBox(height: 60),
          SvgPicture.asset(Resources.assetsImagesDeviceTransferSvg),
          const SizedBox(height: 36),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              context.l10n.backupToOtherDeviceTips,
              style: TextStyle(
                color: context.theme.secondaryText,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          CellGroup(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CellItem(
              title: Text(context.l10n.backupChat),
              color: context.theme.accent,
              trailing: null,
              onTap: () {
                EventBus.instance.fire(DeviceTransferCommand.pushToRemote);
              },
            ),
          )
        ],
      );
}
