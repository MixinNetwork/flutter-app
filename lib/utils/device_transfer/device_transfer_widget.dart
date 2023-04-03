import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rxdart/rxdart.dart';

import '../../constants/resources.dart';
import '../../widgets/dialog.dart';
import '../event_bus.dart';
import '../extension/extension.dart';
import '../logger.dart';

enum DeviceTransferCommand {
  pullToRemote,
  pushToRemote,
  cancelRestore,
  cancelBackup,
  confirmRestore,
  confirmBackup,
}

enum DeviceTransferCallbackType {
  onRestoreStart,
  onRestoreSucceed,
  onRestoreFailed,
  onBackupStart,
  onBackupSucceed,
  onBackupFailed,
  onRestoreProgress,
  onBackupProgress,

  /// a push event from other device.
  onRestoreReceived,

  /// a pull event from other device.
  onBackupReceived,
}

class DeviceTransferCallbackEvent {
  DeviceTransferCallbackEvent(this.action, [this.payload]);

  final DeviceTransferCallbackType action;
  final dynamic payload;
}

class DeviceTransferEventBus {
  DeviceTransferEventBus._();

  static final DeviceTransferEventBus instance = DeviceTransferEventBus._();

  final _eventBus = EventBus.instance;

  Stream<DeviceTransferCallbackEvent> on(DeviceTransferCallbackType action) =>
      _eventBus.on
          .whereType<DeviceTransferCallbackEvent>()
          .where((event) => event.action == action);

  Stream<DeviceTransferCallbackEvent> events() => _eventBus.on.whereType();

  void fire(DeviceTransferCallbackType action, [dynamic payload]) {
    _eventBus.fire(DeviceTransferCallbackEvent(action, payload));
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
    if (event.action == DeviceTransferCallbackType.onBackupStart) {
      subject.add(_Status.start);
    } else if (event.action == DeviceTransferCallbackType.onBackupSucceed) {
      subject.add(_Status.succeed);
    } else if (event.action == DeviceTransferCallbackType.onBackupFailed) {
      subject.add(_Status.failed);
    }
  });
  return subject;
}();

final _restoreBehavior = () {
  final subject = BehaviorSubject<_Status>();
  DeviceTransferEventBus.instance.events().listen((event) {
    if (event.action == DeviceTransferCallbackType.onRestoreStart) {
      subject.add(_Status.start);
    } else if (event.action == DeviceTransferCallbackType.onRestoreSucceed) {
      subject.add(_Status.succeed);
    } else if (event.action == DeviceTransferCallbackType.onRestoreFailed) {
      subject.add(_Status.failed);
    }
  });
  return subject;
}();

final _backupProgressBehavior = () {
  final subject = PublishSubject<double>();
  DeviceTransferEventBus.instance.events().listen((event) {
    if (event.action == DeviceTransferCallbackType.onBackupProgress) {
      subject.add(event.payload as double);
    }
  });
  return subject;
}();

final _restoreProgressBehavior = () {
  final subject = PublishSubject<double>();
  DeviceTransferEventBus.instance.events().listen((event) {
    if (event.action == DeviceTransferCallbackType.onRestoreProgress) {
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

void useOnTransferEventType(
  DeviceTransferCallbackType type,
  VoidCallback callback,
) {
  useEffect(() {
    final subscription =
        DeviceTransferEventBus.instance.on(type).listen((event) => callback());
    return subscription.cancel;
  }, [type]);
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
    useOnTransferEventType(
      DeviceTransferCallbackType.onRestoreReceived,
      () => showMixinDialog(
        context: context,
        child: _ConfirmDialog(
          message: 'restore from remote',
          onConfirmed: () {
            EventBus.instance.fire(DeviceTransferCommand.confirmRestore);
          },
        ),
      ),
    );
    useOnTransferEventType(
      DeviceTransferCallbackType.onBackupReceived,
      () => showMixinDialog(
        context: context,
        child: _ConfirmDialog(
          message: 'backup from remote',
          onConfirmed: () {
            EventBus.instance.fire(DeviceTransferCommand.confirmBackup);
          },
        ),
      ),
    );
    return child;
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.message,
    this.onConfirmed,
  });

  final String message;

  final VoidCallback? onConfirmed;

  @override
  Widget build(BuildContext context) => AlertDialogLayout(
        content: Text(message),
        title: Text(context.l10n.confirm),
        actions: [
          TextButton(
            onPressed: () {
              onConfirmed?.call();
              Navigator.of(context).pop(false);
            },
            child: Text(context.l10n.confirm),
          ),
        ],
      );
}

class _RestoreProcessingDialog extends StatelessWidget {
  const _RestoreProcessingDialog();

  @override
  Widget build(BuildContext context) => _TransferProcessDialog(
        title: const Text('Transferring...'),
        onCancelTapped: () {
          EventBus.instance.fire(DeviceTransferCommand.cancelRestore);
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
          EventBus.instance.fire(DeviceTransferCommand.cancelBackup);
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
