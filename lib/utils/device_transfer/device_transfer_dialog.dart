import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' hide Provider;

import '../../constants/resources.dart';
import '../../ui/provider/ui_context_providers.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cell.dart';
import '../../widgets/dialog.dart';
import '../event_bus.dart';
import '../extension/extension.dart';
import '../logger.dart';
import 'device_transfer_widget.dart';

Future<void> showDeviceTransferDialog(BuildContext context) async =>
    showMixinDialog(
      context: context,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: const Material(color: Colors.transparent, child: _Navigator()),
      ),
    );

enum _DeviceTransferPageType {
  deviceTransfer,
  restore,
  backup,
  restoreWaitingConnect,
  backupWaitingConnect
  ;

  Widget build() {
    switch (this) {
      case _DeviceTransferPageType.deviceTransfer:
        return const _DeviceTransferPage();
      case _DeviceTransferPageType.restore:
        return const _RestorePage();
      case _DeviceTransferPageType.backup:
        return const _BackupPage();
      case _DeviceTransferPageType.restoreWaitingConnect:
        return const _RestoreWaitingConnectPage();
      case _DeviceTransferPageType.backupWaitingConnect:
        return const _BackupWaitingConnectPage();
    }
  }
}

class _NavigatorState with EquatableMixin {
  _NavigatorState(this.pages);

  final List<_DeviceTransferPageType> pages;

  @override
  List<Object?> get props => [pages];
}

class _NavigatorNotifier extends Notifier<_NavigatorState> {
  @override
  _NavigatorState build() =>
      _NavigatorState([_DeviceTransferPageType.deviceTransfer]);

  void push(_DeviceTransferPageType page) {
    state = _NavigatorState([...state.pages, page]);
  }

  void pop() {
    state = _NavigatorState([...state.pages]..removeLast());
  }
}

final _navigatorProvider =
    NotifierProvider.autoDispose<_NavigatorNotifier, _NavigatorState>(
      _NavigatorNotifier.new,
    );

class _Navigator extends HookConsumerWidget {
  const _Navigator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = ref.watch(_navigatorProvider);
    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      alignment: Alignment.topCenter,
      child: pages.pages.lastOrNull?.build() ?? const SizedBox.shrink(),
    );
  }
}

class _DeviceTransferPage extends ConsumerWidget {
  const _DeviceTransferPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MixinAppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Chat Backup and Restore'),
          leading: const SizedBox.shrink(),
          actions: [
            MixinCloseButton(
              onTap: () =>
                  Navigator.maybeOf(context, rootNavigator: true)?.pop(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        CellGroup(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CellItem(
            title: const Text('sync from other device'),
            onTap: () {
              ref
                  .read(_navigatorProvider.notifier)
                  .push(
                    _DeviceTransferPageType.restore,
                  );
            },
          ),
        ),
        const SizedBox(height: 16),
        CellGroup(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CellItem(
            title: const Text('sync to other device'),
            onTap: () {
              ref
                  .read(_navigatorProvider.notifier)
                  .push(
                    _DeviceTransferPageType.backup,
                  );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _DialogBackButton extends HookConsumerWidget {
  const _DialogBackButton({this.onTapped});

  final VoidCallback? onTapped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPopup = ref.watch(
      _navigatorProvider.select((value) => value.pages.length > 1),
    );
    return !canPopup
        ? const SizedBox.shrink()
        : Center(
            child: MixinBackButton(
              onTap: () {
                onTapped?.call();
                ref.read(_navigatorProvider.notifier).pop();
              },
            ),
          );
  }
}

class _RestorePage extends ConsumerWidget {
  const _RestorePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MixinAppBar(
          backgroundColor: Colors.transparent,
          title: const Text('sync from other device'),
          leading: const _DialogBackButton(),
          actions: [
            MixinCloseButton(
              onTap: () =>
                  Navigator.maybeOf(context, rootNavigator: true)?.pop(),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SvgPicture.asset(Resources.assetsImagesDeviceTransferSvg),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Text(
            'restore chat tip',
            style: TextStyle(
              color: theme.secondaryText,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 40),
        CellGroup(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CellItem(
            title: const Text('restore chat'),
            color: theme.accent,
            trailing: null,
            onTap: () {
              EventBus.instance.fire(DeviceTransferCommand.pullToRemote);
              ref
                  .read(_navigatorProvider.notifier)
                  .push(
                    _DeviceTransferPageType.restoreWaitingConnect,
                  );
            },
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _RestoreWaitingConnectPage extends HookConsumerWidget {
  const _RestoreWaitingConnectPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final l10n = ref.watch(localizationProvider);
    useOnTransferEventType(DeviceTransferCallbackType.onRestoreStart, () {
      i('_RestoreWaitingConnectPage: onRestoreStart, closing dialog');
      Navigator.maybeOf(context, rootNavigator: true)?.pop();
    });
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MixinAppBar(
          backgroundColor: Colors.transparent,
          title: const Text('restore from other device'),
          leading: _DialogBackButton(
            onTapped: () {
              EventBus.instance.fire(DeviceTransferCommand.cancelRestore);
            },
          ),
          actions: [
            MixinCloseButton(
              onTap: () {
                Navigator.maybeOf(context, rootNavigator: true)?.pop();
                EventBus.instance.fire(DeviceTransferCommand.cancelRestore);
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        SvgPicture.asset(Resources.assetsImagesTransferFromPhoneSvg),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Text(
            'waiting other device connection',
            style: TextStyle(
              color: theme.secondaryText,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 40),
        TextButton(
          onPressed: () {
            Navigator.maybeOf(context, rootNavigator: true)?.pop();
            EventBus.instance.fire(DeviceTransferCommand.cancelRestore);
          },
          child: Text(l10n.cancel),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _BackupPage extends ConsumerWidget {
  const _BackupPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MixinAppBar(
          backgroundColor: Colors.transparent,
          title: const Text('backup to other device'),
          leading: const _DialogBackButton(),
          actions: [
            MixinCloseButton(
              onTap: () =>
                  Navigator.maybeOf(context, rootNavigator: true)?.pop(),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SvgPicture.asset(
          Resources.assetsImagesDeviceTransferSvg,
          colorFilter: ColorFilter.mode(
            theme.secondaryText,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Text(
            'tips for backup to other device',
            style: TextStyle(
              color: theme.secondaryText,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 40),
        CellGroup(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CellItem(
            title: const Text('backup chat'),
            color: theme.accent,
            trailing: null,
            onTap: () {
              EventBus.instance.fire(DeviceTransferCommand.pushToRemote);
              ref
                  .read(_navigatorProvider.notifier)
                  .push(
                    _DeviceTransferPageType.backupWaitingConnect,
                  );
            },
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _BackupWaitingConnectPage extends HookConsumerWidget {
  const _BackupWaitingConnectPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final l10n = ref.watch(localizationProvider);
    useOnTransferEventType(DeviceTransferCallbackType.onBackupStart, () {
      i('_BackupWaitingConnectPage: onBackupStart, closing dialog');
      Navigator.maybeOf(context, rootNavigator: true)?.pop();
    });
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MixinAppBar(
          backgroundColor: Colors.transparent,
          title: const Text('backup to other device'),
          leading: _DialogBackButton(
            onTapped: () {
              EventBus.instance.fire(DeviceTransferCommand.cancelBackup);
            },
          ),
          actions: [
            MixinCloseButton(
              onTap: () {
                Navigator.maybeOf(context, rootNavigator: true)?.pop();
                EventBus.instance.fire(DeviceTransferCommand.cancelBackup);
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        SvgPicture.asset(Resources.assetsImagesTransferToPhoneSvg),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Text(
            'restore waiting other device',
            style: TextStyle(
              color: theme.secondaryText,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 40),
        TextButton(
          onPressed: () {
            Navigator.maybeOf(context, rootNavigator: true)?.pop();
            EventBus.instance.fire(DeviceTransferCommand.cancelBackup);
          },
          child: Text(l10n.cancel),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
