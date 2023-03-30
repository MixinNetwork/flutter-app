import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rxdart/rxdart.dart';

import '../../widgets/buttons.dart';
import '../../widgets/cell.dart';
import '../event_bus.dart';
import '../extension/extension.dart';
import '../logger.dart';
import 'device_transfer_link_info.dart';

abstract class DeviceTransferEvent {}

/// The request which send to remote
class DeviceTransferRequestEvent extends DeviceTransferEvent {
  DeviceTransferRequestEvent({
    this.linkInfo,
  });

  final DeviceTransferLinkInfo? linkInfo;
}

/// The request which from remote
class DeviceTransferRemoteRequestEvent extends DeviceTransferEvent {
  DeviceTransferRemoteRequestEvent({
    required this.linkInfo,
  });

  final DeviceTransferLinkInfo? linkInfo;
}

class DeviceTransferEventBus {
  DeviceTransferEventBus._();

  static final DeviceTransferEventBus instance = DeviceTransferEventBus._();

  final _eventBus = EventBus.instance;

  Stream<T> on<T extends DeviceTransferEvent>() => _eventBus.on.whereType<T>();

  void fire<T extends DeviceTransferEvent>(T event) {
    _eventBus.fire(event);
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
            .on<DeviceTransferRemoteRequestEvent>()
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
                      title:
                          const Text('Restore chat history from other device'),
                      trailing: null,
                      onTap: () {
                        DeviceTransferEventBus.instance.fire(
                          DeviceTransferRequestEvent(),
                        );
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
