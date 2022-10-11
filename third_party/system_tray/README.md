# system_tray

[![Pub](https://img.shields.io/pub/v/system_tray.svg)](https://pub.dartlang.org/packages/system_tray)

A [Flutter package](https://github.com/antler119/system_tray.git) that enables support for system tray menu for desktop flutter apps. **on Windows, macOS, and Linux**.

## Install

In the pubspec.yaml of your flutter project, add the following dependency:

```yaml
dependencies:
  ...
  system_tray: ^0.1.0
```

In your library add the following import:

```dart
import 'package:system_tray/system_tray.dart';
```

## Prerequisite

### Linux

```bash
sudo apt-get install appindicator3-0.1 libappindicator3-dev
```

## Example App

### Windows

<img src="https://raw.githubusercontent.com/antler119/system_tray/master/resources/screenshot_windows.png">

### macOS

<img src="https://raw.githubusercontent.com/antler119/system_tray/master/resources/screenshot_macos.png">

### Linux

<img src="https://raw.githubusercontent.com/antler119/system_tray/master/resources/screenshot_ubuntu.png">

## API

<table>
    <tr>
        <th>Method</th>
        <th>Description</th>
        <th>Windows</th>
        <th>macOS</th>
        <th>Linux</th>
    </tr>
    <tr>
        <td>initSystemTray</td>
        <td>Initialize system tray</td>
        <td>✔️</td>
        <td>✔️</td>
        <td>✔️</td>
    </tr>
    <tr>
        <td>setSystemTrayInfo</td>
        <td>Modify the tray info</td>
        <td>
          <ul>
            <li>icon</li>
            <li>toolTip</li>
          </ul>
        </td>
        <td>
          <ul>
            <li>title</li>
            <li>icon</li>
            <li>toolTip</li>
          </ul>
        </td>
       <td>
          <ul>
            <li>icon</li>
          </ul>
        </td>
    </tr>
    <tr>
        <td>setImage</td>
        <td>Modify the tray image</td>
        <td>✔️</td>
        <td>✔️</td>
        <td>✔️</td>
    </tr>
    <tr>
        <td>setTooltip</td>
        <td>Modify the tray tooltip</td>
        <td>✔️</td>
        <td>✔️</td>
        <td>➖</td>
    </tr>
    <tr>
        <td>setTitle / getTitle</td>
        <td>Set / Get the tray title</td>
        <td>➖</td>
        <td>✔️</td>
        <td>➖</td>
    </tr>
    <tr>
        <td>setContextMenu</td>
        <td>Set the tray context menu</td>
        <td>✔️</td>
        <td>✔️</td>
        <td>✔️</td>
    </tr>
       <tr>
        <td>popUpContextMenu</td>
        <td>Popup the tray context menu</td>
        <td>✔️</td>
        <td>✔️</td>
        <td>➖</td>
    </tr>
    <tr>
        <td>registerSystemTrayEventHandler</td>
        <td>Register system tray event</td>
        <td>
          <ul>
            <li>leftMouseUp</li>
            <li>leftMouseDown</li>
            <li>leftMouseDblClk</li>
            <li>rightMouseUp</li>
            <li>rightMouseDown</li>
          </ul>
        </td>
        <td>         
          <ul>
            <li>leftMouseUp</li>
            <li>leftMouseDown</li>
            <li>rightMouseUp</li>
            <li>rightMouseDown</li>
          </ul>
        </td>
        <td>➖</td>
    </tr>
</table>

## Usage

```dart
Future<void> initSystemTray() async {
  String path =
      Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png';

  final menu = [
    MenuItem(label: 'Show', onClicked: _appWindow.show),
    MenuItem(label: 'Hide', onClicked: _appWindow.hide),
    MenuItem(label: 'Exit', onClicked: _appWindow.close),
  ];

  // We first init the systray menu and then add the menu entries
  await _systemTray.initSystemTray(
    title: "system tray",
    iconPath: path,
  );

  await _systemTray.setContextMenu(menu);

  // handle system tray event
  _systemTray.registerSystemTrayEventHandler((eventName) {
    debugPrint("eventName: $eventName");
    if (eventName == "leftMouseDown") {
    } else if (eventName == "leftMouseUp") {
      _systemTray.popUpContextMenu();
    } else if (eventName == "rightMouseDown") {
    } else if (eventName == "rightMouseUp") {
      _appWindow.show();
    }
  });
}
```

## Additional Resources

Recommended library that supports window control:

- [bitsdojo_window](https://pub.dev/packages/bitsdojo_window)
- [window_size (Google)](https://github.com/google/flutter-desktop-embedding/tree/master/plugins/window_size)

## Q&A

1. Q: If you encounter the following compilation error

   ```C++
   Undefined symbols for architecture x86_64:
     "___gxx_personality_v0", referenced from:
         ...
   ```

   A: add **libc++.tbd**

   ```bash
   1. open example/macos/Runner.xcodeproj
   2. add 'libc++.tbd' to TARGET runner 'Link Binary With Libraries'
   ```
