import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rxdart/rxdart.dart';

import '../../widgets/buttons.dart';
import '../../widgets/cell.dart';
import '../event_bus.dart';
import '../extension/extension.dart';
import '../logger.dart';

enum DeviceTransferEventAction {
  pullToRemote,
  pushToRemote,
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
            .on(DeviceTransferEventAction.pullToRemote)
            .listen((event) {
          d('DeviceTransferRemoteRequestEvent: $event');
        });
        return subscription.cancel;
      },
    );
    return child;
  }
}

class DeviceTransferDialog extends StatelessWidget {
  const DeviceTransferDialog({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 400,
        height: 210,
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
