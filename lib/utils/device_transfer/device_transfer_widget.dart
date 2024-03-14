import 'dart:async';

import 'package:desktop_keep_screen_on/desktop_keep_screen_on.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
  cancelBackupRequest,
  cancelRestoreRequest,
  confirmRestore,
  confirmBackup,
}

enum DeviceTransferCallbackType {
  onRestoreConnected,
  onRestoreStart,
  onRestoreSucceed,
  onRestoreFailed,
  onBackupServerCreated,
  onBackupStart,
  onBackupSucceed,
  onBackupFailed,
  onRestoreProgress,
  onBackupProgress,
  onRestoreNetworkSpeed,
  onBackupNetworkSpeed,

  /// a push event from other device.
  onBackupRequestReceived,

  /// a pull event from other device.
  onRestoreRequestReceived,
  onConnectionFailed,
}

enum ConnectionFailedReason {
  versionNotMatched,
  unknown,
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
  final subject = StreamController<_Status>.broadcast();
  DeviceTransferEventBus.instance.events().listen((event) {
    if (event.action == DeviceTransferCallbackType.onBackupServerCreated) {
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
  final subject = StreamController<_Status>.broadcast();
  DeviceTransferEventBus.instance.events().listen((event) {
    if (event.action == DeviceTransferCallbackType.onRestoreConnected) {
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

final _backupNetworkSpeedBehavior = () {
  final subject = PublishSubject<double>();
  DeviceTransferEventBus.instance.events().listen((event) {
    if (event.action == DeviceTransferCallbackType.onBackupNetworkSpeed) {
      subject.add(event.payload as double);
    }
  });
  return subject;
}();

final _restoreNetworkSpeedBehavior = () {
  final subject = PublishSubject<double>();
  DeviceTransferEventBus.instance.events().listen((event) {
    if (event.action == DeviceTransferCallbackType.onRestoreNetworkSpeed) {
      subject.add(event.payload as double);
    }
  });
  return subject;
}();

void _useTransferStatus(
  Stream<_Status> Function() streamBuilder, {
  required WidgetBuilder progressBuilder,
  required WidgetBuilder succeedBuilder,
  required WidgetBuilder failedBuilder,
}) {
  final context = useContext();
  final stream = useMemoized(streamBuilder);
  useEffect(() {
    var isProgressShowing = false;
    final subscription = stream.listen((status) async {
      if (status == _Status.start) {
        if (isProgressShowing) {
          return;
        }
        isProgressShowing = true;
        await showMixinDialog(
          context: context,
          child: progressBuilder(context),
          barrierDismissible: false,
        );
        isProgressShowing = false;
      } else {
        if (!isProgressShowing) {
          return;
        }
        if (isProgressShowing) {
          Navigator.of(context).pop();
          isProgressShowing = false;
        }
        if (status == _Status.succeed) {
          d('restore succeed');
          await showMixinDialog(
            context: context,
            child: succeedBuilder(context),
            barrierDismissible: false,
          );
        } else if (status == _Status.failed) {
          await showMixinDialog(
            context: context,
            child: failedBuilder(context),
            barrierDismissible: false,
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

void useOnTransferEventTypePayload<T>(
  DeviceTransferCallbackType type,
  void Function(T) callback,
) {
  useEffect(() {
    final subscription = DeviceTransferEventBus.instance
        .on(type)
        .listen((event) => callback(event.payload as T));
    return subscription.cancel;
  }, [type]);
}

class DeviceTransferHandlerWidget extends HookConsumerWidget {
  const DeviceTransferHandlerWidget({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _useTransferStatus(
      () => _restoreBehavior.stream,
      progressBuilder: (context) => const _RestoreProcessingDialog(),
      succeedBuilder: (context) => _ConfirmDialog(
        message: context.l10n.transferCompleted,
      ),
      failedBuilder: (context) => _ConfirmDialog(
        message: context.l10n.deviceTransferFailed,
      ),
    );
    _useTransferStatus(
      () => _backupBehavior.stream,
      progressBuilder: (context) => const _BackupProcessingDialog(),
      succeedBuilder: (context) => _ConfirmDialog(
        message: context.l10n.transferCompleted,
      ),
      failedBuilder: (context) => _ConfirmDialog(
        message: context.l10n.deviceTransferFailed,
      ),
    );
    useOnTransferEventType(
      DeviceTransferCallbackType.onBackupRequestReceived,
      () async {
        final approved = await showMixinDialog<bool>(
          context: context,
          child: _ApproveDialog(
            message: context.l10n.confirmSyncChatsFromPhone,
          ),
        );
        if (approved == true) {
          EventBus.instance.fire(DeviceTransferCommand.confirmRestore);
        } else {
          EventBus.instance.fire(DeviceTransferCommand.cancelRestoreRequest);
        }
      },
    );
    useOnTransferEventType(
      DeviceTransferCallbackType.onRestoreRequestReceived,
      () async {
        final approved = await showMixinDialog<bool>(
          context: context,
          child: _ApproveDialog(
            message: context.l10n.confirmSyncChatsToPhone,
          ),
        );
        if (approved == true) {
          EventBus.instance.fire(DeviceTransferCommand.confirmBackup);
        } else {
          EventBus.instance.fire(DeviceTransferCommand.cancelBackupRequest);
        }
      },
    );

    useOnTransferEventTypePayload<ConnectionFailedReason>(
      DeviceTransferCallbackType.onConnectionFailed,
      (reason) {
        final String message;
        switch (reason) {
          case ConnectionFailedReason.versionNotMatched:
            message = context.l10n.transferProtocolVersionNotMatched;
          case ConnectionFailedReason.unknown:
            message = context.l10n.deviceTransferFailed;
        }
        showMixinDialog(
          context: context,
          child: _ConfirmDialog(message: message),
        );
      },
    );

    return child;
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) => AlertDialogLayout(
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text(context.l10n.confirm),
          ),
        ],
      );
}

class _ApproveDialog extends StatelessWidget {
  const _ApproveDialog({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => AlertDialogLayout(
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text(
              context.l10n.cancel,
              style: TextStyle(
                color: context.theme.secondaryText,
              ),
            ),
          ),
          MixinButton(
            onTap: () {
              Navigator.of(context).pop(true);
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
        onCancelTapped: () {
          EventBus.instance.fire(DeviceTransferCommand.cancelRestore);
          Navigator.pop(context);
        },
        iconAssetName: Resources.assetsImagesTransferFromPhoneSvg,
        progressBehavior: _restoreProgressBehavior,
        networkSpeedBehavior: _restoreNetworkSpeedBehavior,
      );
}

class _BackupProcessingDialog extends StatelessWidget {
  const _BackupProcessingDialog();

  @override
  Widget build(BuildContext context) => _TransferProcessDialog(
        onCancelTapped: () {
          EventBus.instance.fire(DeviceTransferCommand.cancelBackup);
          Navigator.pop(context);
        },
        iconAssetName: Resources.assetsImagesTransferToPhoneSvg,
        progressBehavior: _backupProgressBehavior,
        networkSpeedBehavior: _backupNetworkSpeedBehavior,
      );
}

class _TransferProcessDialog extends HookConsumerWidget {
  const _TransferProcessDialog({
    required this.onCancelTapped,
    required this.progressBehavior,
    required this.iconAssetName,
    required this.networkSpeedBehavior,
  });

  final VoidCallback onCancelTapped;
  final Stream<double> progressBehavior;
  final Stream<double> networkSpeedBehavior;

  final String iconAssetName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = useStream<double>(progressBehavior, initialData: 0);
    useEffect(() {
      DesktopKeepScreenOn.setPreventSleep(true);
      return () => DesktopKeepScreenOn.setPreventSleep(false);
    }, []);
    final networkSpeed =
        useStream<double>(networkSpeedBehavior, initialData: 0);
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
                iconAssetName,
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
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.l10n.transferringChats),
                    const SizedBox(width: 2),
                    if (progress.data != null && progress.data! > 0)
                      Text('(${progress.data!.toStringAsFixed(2)}%)'),
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
                child: Text(context.l10n.transferringChatsTips),
              ),
              const SizedBox(height: 18),
              Text(
                _formatNetworkSpeed(networkSpeed.data ?? 0),
                style: TextStyle(
                  color: context.theme.secondaryText,
                  fontSize: 14,
                ),
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

String _formatNetworkSpeed(double speed) {
  final speedInKb = speed / 1024;
  if (speedInKb < 1024) {
    return '${speedInKb.toStringAsFixed(2)} KB/s';
  } else {
    return '${(speedInKb / 1024).toStringAsFixed(2)} MB/s';
  }
}
