import 'dart:async';
import 'dart:io';

import 'package:bring_window_to_front/bring_window_to_front.dart';
import 'package:dbus/dbus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:window_manager/window_manager.dart';

import '../utils/extension/extension.dart';
import '../utils/hook.dart';
import '../utils/logger.dart';
import '../utils/uri_utils.dart';

String? _initialUrl;

Future<void> parseAppInitialArguments(List<String> args) async {
  try {
    if (Platform.isLinux) {
      _initialUrl = args.firstOrNull;
    } else if (Platform.isWindows || Platform.isMacOS) {
      _initialUrl = await protocolHandler.getInitialUrl();
    }
  } catch (error, stacktrace) {
    e('parseAppInitialArguments error $error $stacktrace');
  }
}

class AppProtocolHandler extends HookConsumerWidget {
  const AppProtocolHandler({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      if (_initialUrl != null) {
        openUri(context, _initialUrl!);
      }
    }, [_initialUrl]);
    if (Platform.isLinux) {
      return _LinuxAppProtocolHandler(child: child);
    } else {
      return _ProtocolHandler(child: child);
    }
  }
}

class _LinuxAppProtocolHandler extends HookConsumerWidget {
  const _LinuxAppProtocolHandler({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = useMemoized(DBusClient.session);
    useEffect(() {
      final object = _MixinDbusObject(
        open: (url) {
          windowManager.show();
          bringWindowToFront();
          if (url != null) {
            openUri(context, url);
          }
        },
      );
      scheduleMicrotask(() async {
        final replay = await client.requestName(
          'one.mixin.messenger',
          flags: {DBusRequestNameFlag.replaceExisting},
        );
        if (replay != DBusRequestNameReply.primaryOwner) {
          e('Failed to request name: $replay');
          return;
        }
        await client.registerObject(object);
      });
      return () {
        client
          ..unregisterObject(object)
          ..releaseName('one.mixin.messenger')
          ..close();
      };
    }, [client]);
    return child;
  }
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

class _ProtocolHandler extends HookConsumerWidget {
  const _ProtocolHandler({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useProtocol((url) {
      windowManager.show();
      openUri(context, url);
    });
    return child;
  }
}
