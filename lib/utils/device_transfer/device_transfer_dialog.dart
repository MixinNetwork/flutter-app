import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

import '../../constants/resources.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cell.dart';
import '../../widgets/dialog.dart';
import '../event_bus.dart';
import '../extension/extension.dart';
import '../hook.dart';
import 'device_transfer_widget.dart';

Future<void> showDeviceTransferDialog(
  BuildContext context, {
  bool showRestore = true,
}) async =>
    showMixinDialog(
      context: context,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: const Material(
          color: Colors.transparent,
          child: _Navigator(),
        ),
      ),
    );

enum _DeviceTransferPageType {
  deviceTransfer,
  restore,
  backup,
  restoreWaitingConnect;

  Widget build(BuildContext context) {
    switch (this) {
      case _DeviceTransferPageType.deviceTransfer:
        return const _DeviceTransferPage();
      case _DeviceTransferPageType.restore:
        return const _RestorePage();
      case _DeviceTransferPageType.backup:
        return const _BackupPage();
      case _DeviceTransferPageType.restoreWaitingConnect:
        return const _RestoreWaitingConnectPage();
    }
  }
}

class _NavigatorState with EquatableMixin {
  _NavigatorState(this.pages);

  final List<_DeviceTransferPageType> pages;

  @override
  List<Object?> get props => [pages];
}

class _NavigatorCubit extends Cubit<_NavigatorState> {
  _NavigatorCubit()
      : super(_NavigatorState([_DeviceTransferPageType.deviceTransfer]));

  void push(_DeviceTransferPageType page) {
    emit(_NavigatorState([...state.pages, page]));
  }

  void pop() {
    emit(_NavigatorState([...state.pages]..removeLast()));
  }
}

class _Navigator extends HookWidget {
  const _Navigator();

  @override
  Widget build(BuildContext context) {
    final cubit = useBloc(_NavigatorCubit.new);
    final pages = useBlocState<_NavigatorCubit, _NavigatorState>(bloc: cubit);
    return BlocProvider.value(
      value: cubit,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.topCenter,
        child:
            pages.pages.lastOrNull?.build(context) ?? const SizedBox.shrink(),
      ),
    );
  }
}

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
          const SizedBox(height: 20),
          CellGroup(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CellItem(
              title: Text(context.l10n.restoreFromOtherDevice),
              onTap: () {
                context
                    .read<_NavigatorCubit>()
                    .push(_DeviceTransferPageType.restore);
              },
            ),
          ),
          const SizedBox(height: 16),
          CellGroup(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CellItem(
              title: Text(context.l10n.backupToOtherDevice),
              onTap: () {
                context
                    .read<_NavigatorCubit>()
                    .push(_DeviceTransferPageType.backup);
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      );
}

class _DialogBackButton extends HookWidget {
  const _DialogBackButton({this.onTapped});

  final VoidCallback? onTapped;

  @override
  Widget build(BuildContext context) {
    final canPopup =
        useBlocStateConverter<_NavigatorCubit, _NavigatorState, bool>(
            converter: (state) => state.pages.length > 1);
    return !canPopup
        ? const SizedBox.shrink()
        : Center(
            child: MixinBackButton(
              onTap: () {
                onTapped?.call();
                context.read<_NavigatorCubit>().pop();
              },
            ),
          );
  }
}

class _RestorePage extends StatelessWidget {
  const _RestorePage();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MixinAppBar(
            backgroundColor: Colors.transparent,
            title: Text(context.l10n.restoreFromOtherDevice),
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
                context
                    .read<_NavigatorCubit>()
                    .push(_DeviceTransferPageType.restoreWaitingConnect);
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      );
}

class _RestoreWaitingConnectPage extends StatelessWidget {
  const _RestoreWaitingConnectPage();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MixinAppBar(
            backgroundColor: Colors.transparent,
            title: Text(context.l10n.restoreFromOtherDevice),
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
          SvgPicture.asset(Resources.assetsImagesClockSvg),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              context.l10n.restoreWaitingOtherDeviceTips,
              style: TextStyle(
                color: context.theme.secondaryText,
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
            child: Text(context.l10n.cancel),
          ),
          const SizedBox(height: 40),
        ],
      );
}

class _BackupPage extends StatelessWidget {
  const _BackupPage();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MixinAppBar(
            backgroundColor: Colors.transparent,
            title: Text(context.l10n.backupToOtherDevice),
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
              context.theme.secondaryText,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 20),
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
          ),
          const SizedBox(height: 40),
        ],
      );
}
