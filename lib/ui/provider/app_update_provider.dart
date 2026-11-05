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

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  AppUpdateNotifier(this._ref) : _testDio = null, super(AppUpdateState.none) {
    unawaited(_start());
  }

  /// A Linux updater of [package] that does not check by itself and gets the
  /// network through [dio].
  @visibleForTesting
  AppUpdateNotifier.test(
    this._ref, {
    required String package,
    required List<int> publicKey,
    required Dio Function() dio,
  }) : _package = package,
       _publicKey = publicKey,
       _testDio = dio,
       super(AppUpdateState.none);

  final Ref _ref;
  final Dio Function()? _testDio;
  Timer? _timer;
  late String _package;
  late List<int> _publicKey;
  AppUpdateItem? _item;
  MacUpdateChannel? _mac;

  Future<void> _start() async {
    if (Platform.isMacOS) return _startMac();
    // shortcut: Linux and macOS only; Windows comes in a later change.
    if (!Platform.isLinux) return;
    final environment = Platform.environment;
    final executable = Platform.resolvedExecutable;
    final package = linuxUpdatePackage(
      environment: environment,
      executable: executable,
      abi: Abi.current(),
    );
    if (package == null) return;

    final key = (await rootBundle.loadString(
      'assets/update_ed25519.pub',
    )).trim();
    // The release key is not set up yet, so there is nothing to trust.
    if (key.isEmpty) return;
    if (!await canInstallLinuxUpdate(package, environment, executable)) {
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

  ProxyConfig? get _proxy =>
      _ref.read(databaseProvider).valueOrNull?.settingProperties.activatedProxy;

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

  Future<void> _check() async {
    if (state.status == AppUpdateStatus.downloading) return;
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
      if (!mounted || !available) return;
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

  Future<void> update() async {
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
    if (item == null || state.status == AppUpdateStatus.downloading) return;
    state = const AppUpdateState(AppUpdateStatus.downloading);
    final environment = Platform.environment;
    File? file;
    try {
      file = await createLinuxUpdateFile(item.package, environment);
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
      await startLinuxUpdateInstall(
        package: item.package,
        file: file,
        executable: Platform.resolvedExecutable,
        environment: environment,
      );
      exit(0);
    } catch (error, stack) {
      e('app update: install ${item.fileName} failed: $error $stack');
      if (file != null) await file.parent.delete(recursive: true);
      if (mounted) state = const AppUpdateState(AppUpdateStatus.failed);
    }
  }

  Future<void> _installSparkle() async {
    if (state.status == AppUpdateStatus.downloading) return;
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
