# Mixin Messenger Flutter version

[![Dart CI](https://github.com/MixinNetwork/flutter-app/workflows/Dart%20CI/badge.svg)](https://github.com/MixinNetwork/flutter-app/actions)

Mixin Messenger for macOS, Windows and Linux, powered by [Flutter](https://flutter.dev/), the Signal Protocol is implemented with our [libsignal_protocol_dart](https://github.com/MixinNetwork/libsignal_protocol_dart).

## Quick start

```
flutter run -d macOS
flutter run -d linux
flutter run -d windows
```

## Release

```
flutter build macos --release
flutter build linux --release
flutter build windows --release
```

## Linux build Requirement

there are some addition library needed.

### debian

```shell
sudo apt-get install libsqlite3-dev
sudo apt-get install webkit2gtk-4.0
sudo apt-get install libsdl2-dev
```


# License

Released under the [GPLv3](https://github.com/MixinNetwork/flutter-app/blob/master/LICENSE) license.

