# Mixin Messenger Flutter version

[![Dart CI](https://github.com/MixinNetwork/flutter-app/workflows/Dart%20CI/badge.svg)](https://github.com/MixinNetwork/flutter-app/actions)

Mixin Messenger for macOS, Windows and Linux, powered by [Flutter](https://flutter.dev/), the Signal Protocol is implemented with our [libsignal_protocol_dart](https://github.com/MixinNetwork/libsignal_protocol_dart).

Download release version from https://mixin.one/mm

## Quick start

Because some of the underlying implementations in the libraries are written in Rust, you will need to install Rust:
For macOS or Linux, execute the following command in Terminal.

```shell
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

For Windows, you can use the [Rust Installer](https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe).
In case you have Rust already installed, make sure to update it to latest version:

```shell
rustup update
```

Then you can run the app with:

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
sudo apt-get install webkit2gtk-4.1
sudo apt-get install libsdl2-dev
sudo apt-get install libopus-dev libogg-dev
```


# License

Released under the [GPLv3](https://github.com/MixinNetwork/flutter-app/blob/master/LICENSE) license.

