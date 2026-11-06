import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../utils/app_update.dart';
import '../../utils/logger.dart';
import '../../utils/proxy.dart';
import '../../utils/system/package_info.dart';
import 'database_provider.dart';

enum AppUpdateStatus { none, available, downloading, failed }

class AppUpdateState {
  const AppUpdateState(this.status, {this.progress = 0});

  static const none = AppUpdateState(AppUpdateStatus.none);

  final AppUpdateStatus status;

  /// Download progress from 0 to 1, used only while [status] is downloading.
  final double progress;
}

const _macChannel = MethodChannel('mixin_desktop/app_update');
@visibleForTesting
const storeUpdateChannel = MethodChannel('mixin_desktop/store_update');

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  AppUpdateNotifier(this._ref, {@visibleForTesting bool? windows})
    : _windows = windows ?? Platform.isWindows,
      _testDio = null,
      _testProxy = null,
      super(AppUpdateState.none) {
    unawaited(_windows ? _startStore() : _start());
  }

  /// An updater of [package] (or of the macOS [mac] channel) that does not
  /// check by itself and gets the network through [dio] and the in-app proxy
  /// from [proxy].
  @visibleForTesting
  AppUpdateNotifier.test(
    this._ref, {
    required String package,
    required List<int> publicKey,
    required Dio Function() dio,
    MacUpdateChannel? mac,
    ProxyConfig? Function()? proxy,
  }) : _package = package,
       _publicKey = publicKey,
       _testDio = dio,
       _mac = mac,
       _testProxy = proxy,
       _windows = false,
       super(AppUpdateState.none);

  final Ref _ref;
  final Dio Function()? _testDio;
  final ProxyConfig? Function()? _testProxy;
  final bool _windows;
  var _store = false;
  Timer? _timer;
  late String _package;
  late List<int> _publicKey;
  AppUpdateItem? _item;
  MacUpdateChannel? _mac;

  Future<void> _start() async {
    // The Store build was checked first; this is the Inno install or
    // a copy that does not update itself.
    if (!_windows && Platform.isMacOS) return _startMac();
    final environment = Platform.environment;
    final executable = Platform.resolvedExecutable;
    final package = Platform.isLinux
        ? linuxUpdatePackage(
            environment: environment,
            executable: executable,
            abi: Abi.current(),
          )
        : _windows
        ? windowsUpdatePackage(
            executable: executable,
            abi: Abi.current(),
            fileExists: (path) => File(path).existsSync(),
          )
        : null;
    if (package == null) return;

    final key = (await rootBundle.loadString(
      'assets/update_ed25519.pub',
    )).trim();
    // The release key is not set up yet, so there is nothing to trust.
    if (key.isEmpty) return;
    if (Platform.isLinux &&
        !await canInstallLinuxUpdate(package, environment, executable)) {
      i('app update: $package cannot install by itself');
      return;
    }
    _package = package;
    _publicKey = base64Decode(key);
    await _schedule();
  }

  Future<void> _startMac() async {
    final info = (await _macChannel.invokeMapMethod<String, dynamic>(
      'channel',
    ))!;
    _mac = macUpdateChannel(
      environment: info['environment'] as String?,
      sparkle: info['sparkle'] as bool,
    );
    if (_mac == null) return;
    _macChannel.setMethodCallHandler((call) async {
      if (call.method == 'progress' && mounted) {
        state = AppUpdateState(
          AppUpdateStatus.downloading,
          progress: call.arguments as double,
        );
      }
    });
    await _schedule();
  }

  Future<void> _schedule() async {
    await _check();
    _timer = Timer.periodic(const Duration(hours: 6), (_) => _check());
  }

  String get _appcastUrl =>
      // A test appcast; its packages still need the release key.
      Platform.environment['MIXIN_UPDATE_APPCAST_URL'] ?? appcastUrl;

  ProxyConfig? get _proxy => _testProxy != null
      ? _testProxy()
      : _ref
            .read(databaseProvider)
            .valueOrNull
            ?.settingProperties
            .activatedProxy;

  Dio _dio() =>
      _testDio?.call() ??
      (Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
      )..applyProxy(_proxy));

  @visibleForTesting
  Future<void> check() => _check();

  // Checked again before each use, because the proxy can change at any time.
  bool _sparkleNeedsProxy() {
    if (_mac != MacUpdateChannel.dmg || _proxy == null) return false;
    // Sparkle downloads with NSURLSession, which ignores the in-app proxy,
    // so the install would fail. Sparkle refuses a file:// feed, so the app
    // cannot download the DMG for it.
    i('app update: no DMG update, Sparkle cannot use the in-app proxy');
    if (mounted) state = AppUpdateState.none;
    return true;
  }

  Future<void> _check() async {
    if (state.status == AppUpdateStatus.downloading) return;
    if (_sparkleNeedsProxy()) return;
    try {
      final info = await getPackageInfo();
      final build = int.parse(info.buildNumber);
      final item = _mac == null
          ? findAppUpdate(await _get(_appcastUrl), _package, build)
          : null;
      final available = switch (_mac) {
        MacUpdateChannel.appStore => isNewerVersion(
          appStoreVersion(await _get(macAppStoreLookupUrl)) ?? '',
          info.version,
        ),
        // TestFlight gets the same builds as the DMG.
        MacUpdateChannel.testFlight || MacUpdateChannel.dmg =>
          (latestAppcastBuild(await _get(_appcastUrl), 'dmg') ?? 0) > build,
        null => item != null,
      };
      if (!mounted || !available || _sparkleNeedsProxy()) return;
      // The state stays available, so a later appcast without this package
      // must not empty the item.
      _item = item ?? _item;
      if (state.status == AppUpdateStatus.none) {
        state = const AppUpdateState(AppUpdateStatus.available);
      }
    } catch (error) {
      // No network or no appcast yet: check again later.
      i('app update: check failed: $error');
    }
  }

  Future<String> _get(String url) async => (await _dio().get<String>(
    url,
    options: Options(responseType: ResponseType.plain),
  )).data!;

  Future<void> _startStore() async {
    storeUpdateChannel.setMethodCallHandler((call) async {
      if (call.method == 'progress' &&
          mounted &&
          state.status == AppUpdateStatus.downloading) {
        state = AppUpdateState(
          AppUpdateStatus.downloading,
          progress: call.arguments as double,
        );
      }
    });
    // Not packaged: not the Store build.
    if (!await _checkStore()) return _start();
    _store = true;
    _timer = Timer.periodic(const Duration(hours: 6), (_) => _checkStore());
  }

  /// False when the app is not packaged, so it is not the Store build.
  Future<bool> _checkStore() async {
    if (state.status == AppUpdateStatus.downloading) return true;
    try {
      final count = await storeUpdateChannel.invokeMethod<int>(
        'storeUpdateCount',
      );
      if (count == null) return false;
      if (mounted && count > 0 && state.status == AppUpdateStatus.none) {
        state = const AppUpdateState(AppUpdateStatus.available);
      }
    } on PlatformException catch (error) {
      i('app update: store check failed: $error');
    }
    return true;
  }

  Future<void> _installStore() async {
    state = const AppUpdateState(AppUpdateStatus.downloading);
    try {
      await storeUpdateChannel.invokeMethod<void>('installStoreUpdates');
      // The Store restarts the app after the install.
      if (mounted) state = AppUpdateState.none;
    } on PlatformException catch (error) {
      e('app update: store install failed: $error');
      if (mounted) state = const AppUpdateState(AppUpdateStatus.failed);
    }
  }

  Future<void> update() async {
    if (state.status case AppUpdateStatus.none || AppUpdateStatus.downloading) {
      return;
    }
    if (_store) return _installStore();
    switch (_mac) {
      case MacUpdateChannel.appStore:
        await launchUrlString(macAppStoreUrl);
        return;
      case MacUpdateChannel.testFlight:
        await launchUrlString(macTestFlightUrl);
        return;
      case MacUpdateChannel.dmg:
        return _installSparkle();
      case null:
    }
    final item = _item;
    if (item == null) return;
    state = const AppUpdateState(AppUpdateStatus.downloading);
    final environment = Platform.environment;
    File? file;
    try {
      file = await createUpdateFile(item.package, environment);
      await _dio().downloadUri(
        item.url,
        file.path,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            state = AppUpdateState(
              AppUpdateStatus.downloading,
              progress: received / total,
            );
          }
        },
      );
      if (!verifyAppUpdate(item, await sha256File(file), _publicKey)) {
        throw const FormatException('the package does not match its signature');
      }
      if (Platform.isWindows) {
        await startWindowsUpdateInstall(
          file: file,
          executable: Platform.resolvedExecutable,
        );
      } else {
        await startLinuxUpdateInstall(
          package: item.package,
          file: file,
          executable: Platform.resolvedExecutable,
          environment: environment,
        );
      }
      exit(0);
    } catch (error, stack) {
      e('app update: install ${item.fileName} failed: $error $stack');
      if (file != null) await file.parent.delete(recursive: true);
      if (mounted) state = const AppUpdateState(AppUpdateStatus.failed);
    }
  }

  Future<void> _installSparkle() async {
    if (state.status == AppUpdateStatus.downloading || _sparkleNeedsProxy()) {
      return;
    }
    state = const AppUpdateState(AppUpdateStatus.downloading);
    try {
      // Sparkle checks the EdDSA signature, then quits and relaunches the app.
      await _macChannel.invokeMethod('install', _appcastUrl);
    } catch (error) {
      e('app update: Sparkle install failed: $error');
      if (mounted) state = const AppUpdateState(AppUpdateStatus.failed);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final appUpdateProvider =
    StateNotifierProvider<AppUpdateNotifier, AppUpdateState>(
      AppUpdateNotifier.new,
    );
