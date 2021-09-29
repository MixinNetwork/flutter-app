import 'dart:async';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:path/path.dart' as p;
import 'package:system_tray/system_tray.dart';

final SystemTray _systemTray = SystemTray();

Future<void> initSystemTray() async {
  String path;
  if (Platform.isWindows) {
    path = p.joinAll([
      p.dirname(Platform.resolvedExecutable),
      'data/flutter_assets/assets',
      'windows_app_icon.png'
    ]);
  } else if (Platform.isMacOS) {
    path = p.joinAll(['AppIcon']);
  } else {
    path = p.joinAll([
      p.dirname(Platform.resolvedExecutable),
      'data/flutter_assets/assets',
      'macos_app_icon.png'
    ]);
  }

  // We first init the systray menu and then add the menu entries
  await _systemTray.initSystemTray("system tray",
      iconPath: path, toolTip: "How to use system tray with Flutter");

  await _systemTray.setContextMenu(
    [
      MenuItem(
        label: 'Show',
        onClicked: () {
          appWindow.show();
        },
      ),
      MenuSeparator(),
      SubMenu(
        label: "SubMenu",
        children: [
          MenuItem(
            label: 'SubItem1',
            enabled: false,
            onClicked: () {
              print("click SubItem1");
            },
          ),
          MenuItem(label: 'SubItem2'),
          MenuItem(label: 'SubItem3'),
        ],
      ),
      MenuSeparator(),
      MenuItem(
        label: 'Exit',
        onClicked: () {
          appWindow.close();
        },
      ),
    ],
  );

  await _systemTray.setSystemTrayInfo(
    iconPath: path,
  );

  // handle system tray event
  _systemTray.registerSystemTrayEventHandler((eventName) {
    print("eventName: $eventName");
  });
}
