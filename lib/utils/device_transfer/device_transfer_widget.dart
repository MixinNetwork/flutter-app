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

class DeviceTransferHandlerWidget extends HookWidget {
  const DeviceTransferHandlerWidget({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    useEffect(
      () {
        final subscription = DeviceTransferEventBus.instance
            .on(DeviceTransferEventAction.onRestoreStart)
            .listen((event) {
          d('onRestoreStart: $event');
          showMixinDialog(
            context: context,
            child: const TransferProcessDialog(),
            barrierDismissible: false,
          );
        });
        return subscription.cancel;
      },
      [],
    );
    return child;
  }
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

class TransferProcessDialog extends StatelessWidget {
  const TransferProcessDialog({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 320,
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
              ),
              const SizedBox(height: 38),
              // TODO: i18n
              Text(
                'Transferring...',
                style: TextStyle(
                  color: context.theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  DeviceTransferEventBus.instance
                      .fire(DeviceTransferEventAction.cancelRestore);
                },
                child: Text(
                  context.l10n.cancel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: context.theme.accent,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
}
