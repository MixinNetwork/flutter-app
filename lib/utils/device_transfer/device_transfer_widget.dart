import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rxdart/rxdart.dart';

import '../../constants/resources.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cell.dart';
import '../../widgets/dialog.dart';
import '../event_bus.dart';
import '../extension/extension.dart';
import '../logger.dart';

enum DeviceTransferEventAction {
  pullToRemote,
  pushToRemote,
  onRestoreStart,
  cancelRestore,
  onRestoreSucceed,
  onRestoreFailed,
  onBackupStart,
  cancelBackup,
  onBackupSucceed,
  onBackupFailed,
  onRestoreProgress,
  onBackupProgress,
}

class DeviceTransferEvent {
  DeviceTransferEvent(this.action, [this.payload]);

  final DeviceTransferEventAction action;
  final dynamic payload;
}

class DeviceTransferEventBus {
  DeviceTransferEventBus._();

  static final DeviceTransferEventBus instance = DeviceTransferEventBus._();

  final _eventBus = EventBus.instance;

  Stream<DeviceTransferEvent> on(DeviceTransferEventAction action) =>
      _eventBus.on
          .whereType<DeviceTransferEvent>()
          .where((event) => event.action == action);

  Stream<DeviceTransferEvent> events() => _eventBus.on.whereType();

  void fire(DeviceTransferEventAction action, [dynamic payload]) {
    _eventBus.fire(DeviceTransferEvent(action, payload));
  }
}

enum _Status {
  start,
  succeed,
  failed,
}

final _backupBehavior = () {
  final subject = BehaviorSubject<_Status>();
  DeviceTransferEventBus.instance.events().listen((event) {
    if (event.action == DeviceTransferEventAction.onBackupStart) {
      subject.add(_Status.start);
    } else if (event.action == DeviceTransferEventAction.onBackupSucceed) {
      subject.add(_Status.succeed);
    } else if (event.action == DeviceTransferEventAction.onBackupFailed) {
      subject.add(_Status.failed);
    }
  });
  return subject;
}();

final _restoreBehavior = () {
  final subject = BehaviorSubject<_Status>();
  DeviceTransferEventBus.instance.events().listen((event) {
    if (event.action == DeviceTransferEventAction.onRestoreStart) {
      subject.add(_Status.start);
    } else if (event.action == DeviceTransferEventAction.onRestoreSucceed) {
      subject.add(_Status.succeed);
    } else if (event.action == DeviceTransferEventAction.onRestoreFailed) {
      subject.add(_Status.failed);
    }
  });
  return subject;
}();

final _backupProgressBehavior = () {
  final subject = PublishSubject<double>();
  DeviceTransferEventBus.instance.events().listen((event) {
    if (event.action == DeviceTransferEventAction.onBackupProgress) {
      subject.add(event.payload as double);
    }
  });
  return subject;
}();

final _restoreProgressBehavior = () {
  final subject = PublishSubject<double>();
  DeviceTransferEventBus.instance.events().listen((event) {
    if (event.action == DeviceTransferEventAction.onRestoreProgress) {
      subject.add(event.payload as double);
    }
  });
  return subject;
}();

void _useTransferStatus(
  Stream<_Status> stream, {
  required WidgetBuilder progressBuilder,
  required WidgetBuilder succeedBuilder,
  required WidgetBuilder failedBuilder,
}) {
  final context = useContext();
  useEffect(() {
    var isProgressShowing = false;
    final subscription = stream.listen((status) async {
      if (status == _Status.start) {
        isProgressShowing = true;
        await showMixinDialog(
          context: context,
          child: progressBuilder(context),
        );
        isProgressShowing = false;
      } else {
        if (isProgressShowing) {
          Navigator.of(context).pop();
          isProgressShowing = false;
        }
        if (status == _Status.succeed) {
          d('restore succeed');
          await showMixinDialog(
            context: context,
            child: succeedBuilder(context),
          );
        } else if (status == _Status.failed) {
          await showMixinDialog(
            context: context,
            child: failedBuilder(context),
          );
        }
      }
    });
    return subscription.cancel;
  }, [stream]);
}

class DeviceTransferHandlerWidget extends HookWidget {
  const DeviceTransferHandlerWidget({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    _useTransferStatus(
      _restoreBehavior,
      progressBuilder: (context) => const _RestoreProcessingDialog(),
      succeedBuilder: (context) => const _ConfirmDialog(
        message: 'restore succeed',
      ),
      failedBuilder: (context) => const _ConfirmDialog(
        message: 'backup failed',
      ),
    );
    _useTransferStatus(
      _backupBehavior,
      progressBuilder: (context) => const _BackupProcessingDialog(),
      succeedBuilder: (context) => const _ConfirmDialog(
        message: 'backupSuccess',
      ),
      failedBuilder: (context) => const _ConfirmDialog(
        message: 'backup failed',
      ),
    );
    return child;
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => AlertDialogLayout(
        content: Text(message),
        title: Text(context.l10n.confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.confirm),
          ),
        ],
      );
}

class DeviceTransferDialog extends StatelessWidget {
  const DeviceTransferDialog({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 400,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Device Transfer',
                    style: TextStyle(
                      color: context.theme.text,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CellGroup(
                    child: CellItem(
                      title: const Text('Pull'),
                      trailing: null,
                      onTap: () {
                        DeviceTransferEventBus.instance
                            .fire(DeviceTransferEventAction.pullToRemote);
                      },
                    ),
                  ),
                  CellGroup(
                    child: CellItem(
                      title: const Text('Push'),
                      trailing: null,
                      onTap: () {
                        DeviceTransferEventBus.instance
                            .fire(DeviceTransferEventAction.pushToRemote);
                      },
                    ),
                  ),
                ],
              ),
              const Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(22),
                  child: MixinCloseButton(),
                ),
              ),
            ],
          ),
        ),
      );
}

class _RestoreProcessingDialog extends StatelessWidget {
  const _RestoreProcessingDialog();

  @override
  Widget build(BuildContext context) => _TransferProcessDialog(
        title: const Text('Transferring...'),
        onCancelTapped: () {
          DeviceTransferEventBus.instance
              .fire(DeviceTransferEventAction.cancelRestore);
          Navigator.pop(context);
        },
        tips: const Text(
          'Please do not turn off your phone or disconnect the USB cable during the transfer.',
        ),
        statusBehavior: _restoreBehavior,
        progressBehavior: _restoreProgressBehavior,
      );
}

class _BackupProcessingDialog extends StatelessWidget {
  const _BackupProcessingDialog();

  @override
  Widget build(BuildContext context) => _TransferProcessDialog(
        title: const Text('Transferring...'),
        onCancelTapped: () {
          DeviceTransferEventBus.instance
              .fire(DeviceTransferEventAction.cancelBackup);
          Navigator.pop(context);
        },
        tips: const Text(
          'Please do not turn off your phone or disconnect the USB cable during the transfer.',
        ),
        statusBehavior: _backupBehavior,
        progressBehavior: _backupProgressBehavior,
      );
}

class _TransferProcessDialog extends HookWidget {
  const _TransferProcessDialog({
    required this.title,
    required this.onCancelTapped,
    required this.tips,
    required this.statusBehavior,
    required this.progressBehavior,
  });

  final Widget title;
  final VoidCallback onCancelTapped;
  final Widget tips;

  final Stream<_Status> statusBehavior;
  final Stream<double> progressBehavior;

  @override
  Widget build(BuildContext context) {
    final progress = useStream<double>(progressBehavior, initialData: 0);
    return SizedBox(
      width: 420,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),
              SvgPicture.asset(
                Resources.assetsImagesClockSvg,
                width: 72,
                height: 72,
                colorFilter: ColorFilter.mode(
                  context.theme.secondaryText,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 38),
              DefaultTextStyle.merge(
                style: TextStyle(
                  color: context.theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    title,
                    const SizedBox(width: 2),
                    if (progress.data != null && progress.data! > 0)
                      Text('(${progress.data!.toStringAsFixed(0)}%)'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DefaultTextStyle.merge(
                style: TextStyle(
                  color: context.theme.secondaryText,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                child: tips,
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: onCancelTapped,
                child: Text(
                  context.l10n.cancel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: context.theme.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
