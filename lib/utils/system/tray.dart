import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart' hide MenuItem;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:path/path.dart' as p;
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

import '../../constants/resources.dart';
import '../extension/extension.dart';
import '../logger.dart';

final SystemTray _systemTray = SystemTray();

final _enableTray = Platform.isWindows;

class SystemTrayWidget extends HookWidget {
  const SystemTrayWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final show = context.l10n.show;
    final exitStr = context.l10n.exit;

    useMemoized(() {
      if (!_enableTray) {
        return;
      }
      _initSystemTray();
    });

    useEffect(() {
      if (!_enableTray) {
        return;
      }
      _systemTray.setContextMenu(
        [
          MenuItem(
            label: show,
            onClicked: windowManager.show,
          ),
          MenuSeparator(),
          MenuItem(
            label: exitStr,
            onClicked: () {
              exit(0);
            },
          ),
        ],
      );
    }, [show, exitStr]);

    return child;
  }
}

Future<void> _initSystemTray() async {
  String path;
  if (Platform.isWindows) {
    path = p.joinAll([
      p.dirname(Platform.resolvedExecutable),
      'data/flutter_assets',
      Resources.assetsImagesNotifyIconIco,
    ]);
  } else if (Platform.isMacOS) {
    path = p.joinAll(['AppIcon']);
  } else if (Platform.isLinux) {
    path = p.joinAll([
      p.dirname(Platform.resolvedExecutable),
      'data/flutter_assets',
      Resources.assetsIconsWindowsAppIconPng,
    ]);
  } else {
    assert(false, 'can not init tray icon path.');
    return;
  }

  // We first init the systray menu and then add the menu entries
  unawaited(_systemTray.initSystemTray(
    title: 'Mixin',
    iconPath: path,
    toolTip: 'Mixin',
  ));

  // handle system tray event
  _systemTray.registerSystemTrayEventHandler((eventName) {
    d('eventName: $eventName');
    switch (eventName) {
      case 'leftMouseUp':
        windowManager.show();
        break;
      case 'rightMouseUp':
        _systemTray.popUpContextMenu();
        break;
      default:
        break;
    }
  });
}
