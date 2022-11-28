import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:window_manager/window_manager.dart';

import '../utils/extension/extension.dart';
import '../utils/hook.dart';
import '../utils/logger.dart';
import '../utils/uri_utils.dart';

class AppProtocolHandler extends StatelessWidget {
  const AppProtocolHandler({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Platform.isLinux) {
      return _LinuxAppProtocolHandler(child: child);
    } else {
      return _ProtocolHandler(child: child);
    }
  }
}

class _LinuxAppProtocolHandler extends StatefulWidget {
  const _LinuxAppProtocolHandler({required this.child});

  final Widget child;

  @override
  State<_LinuxAppProtocolHandler> createState() =>
      _LinuxAppProtocolHandlerState();
}

class _LinuxAppProtocolHandlerState extends State<_LinuxAppProtocolHandler> {
  final client = DBusClient.session();
  late _MixinDbusObject object;

  @override
  void initState() {
    super.initState();
    object = _MixinDbusObject(
      open: (url) {
        windowManager
          ..show()
          ..focus();
        if (url != null) {
          openUri(context, url);
        }
      },
    );
    _initialize();
  }

  Future<void> _initialize() async {
    final replay = await client.requestName(
      'one.mixin.messenger',
      flags: {DBusRequestNameFlag.replaceExisting},
    );
    if (replay != DBusRequestNameReply.primaryOwner) {
      e('Failed to request name: $replay');
      return;
    }
    await client.registerObject(object);
  }

  @override
  void dispose() {
    super.dispose();
    client.unregisterObject(object);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _MixinDbusObject extends DBusObject {
  _MixinDbusObject({this.open}) : super(DBusObjectPath('/one/mixin/messenger'));

  final ValueChanged<String?>? open;

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    i('handleMethodCall: ${methodCall.interface} ${methodCall.name}');
    if (methodCall.interface != 'one.mixin.messenger') {
      return DBusMethodErrorResponse.unknownInterface();
    }
    if (methodCall.name == 'Open') {
      i('Open: ${methodCall.values}');
      final url = methodCall.values.firstOrNull as DBusString?;
      open?.call(url?.value);
      return DBusMethodSuccessResponse();
    }
    return DBusMethodSuccessResponse();
  }
}

class _ProtocolHandler extends HookWidget {
  const _ProtocolHandler({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    useProtocol((String url) {
      windowManager.show();
      openUri(context, url);
    });
    return child;
  }
}
