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
  const AppUpdateState(
    this.status, {
    this.progress = 0,
    this.hasChannel = false,
  });

  static const none = AppUpdateState(AppUpdateStatus.none);

  final AppUpdateStatus status;

  /// Download progress from 0 to 1, used only while [status] is downloading.
  final double progress;

  /// Whether this copy has a known update channel (store or self-updater).
  final bool hasChannel;
}

const _macChannel = MethodChannel('mixin_desktop/app_update');
@visibleForTesting
const storeUpdateChannel = MethodChannel('mixin_desktop/store_update');

sealed class _UpdateChannel {
  const _UpdateChannel();
}

final class _StoreChannel extends _UpdateChannel {
  const _StoreChannel();
}

final class _MacChannel extends _UpdateChannel {
  const _MacChannel(this.channel);
  final MacUpdateChannel channel;
}

final class _SnapChannel extends _UpdateChannel {
  const _SnapChannel(this.arch);
  final String arch;
}

final class _PackageChannel extends _UpdateChannel {
  const _PackageChannel(this.package, this.publicKey);
  final String package;
  final List<int> publicKey;
}

_UpdateChannel? _testChannel({
  MacUpdateChannel? mac,
  String? snapArch,
  String? package,
  List<int> publicKey = const [],
}) {
  if (mac != null) return _MacChannel(mac);
  if (snapArch != null) return _SnapChannel(snapArch);
  if (package != null) return _PackageChannel(package, publicKey);
  return null;
}

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  AppUpdateNotifier(
    this._ref, {
    @visibleForTesting bool? windows,
    @visibleForTesting Future<bool> Function(String url)? launchUrl,
  }) : _windows = windows ?? Platform.isWindows,
       _testDio = null,
       _testProxy = null,
       _launchUrl = launchUrl ?? launchUrlString,
       super(AppUpdateState.none) {
    _channel = _discoverChannel();
    unawaited(_channel);
  }

  /// An updater of [package] (or of the macOS [mac] or Linux [snapArch]
  /// channel) that does not check by itself and gets the network through [dio]
  /// and the in-app proxy from [proxy].
  @visibleForTesting
  AppUpdateNotifier.test(
    this._ref, {
    required Dio Function() dio,
    String? package,
    List<int> publicKey = const [],
    MacUpdateChannel? mac,
    String? snapArch,
    ProxyConfig? Function()? proxy,
    Future<bool> Function(String url)? launchUrl,
  }) : _channel = Future.value(
         _testChannel(
           mac: mac,
           snapArch: snapArch,
           package: package,
           publicKey: publicKey,
         ),
       ),
       _testDio = dio,
       _testProxy = proxy,
       _launchUrl = launchUrl ?? launchUrlString,
       _windows = false,
       super(
         AppUpdateState(
           AppUpdateStatus.none,
           hasChannel: mac != null || snapArch != null || package != null,
         ),
       );

  final Ref _ref;
  final Dio Function()? _testDio;
  final ProxyConfig? Function()? _testProxy;
  final Future<bool> Function(String url) _launchUrl;
  final bool _windows;
  late final Future<_UpdateChannel?> _channel;
  Timer? _timer;
  Future<void>? _checkInFlight;
  Future<bool>? _updateInFlight;
  AppUpdateItem? _item;

  void _setState(
    AppUpdateStatus status, {
    double progress = 0,
    bool? hasChannel,
  }) {
    if (!mounted) return;
    state = AppUpdateState(
      status,
      progress: progress,
      hasChannel: hasChannel ?? state.hasChannel,
    );
  }

  Future<bool> _tryLaunch(String url) async {
    try {
      return await _launchUrl(url);
    } on PlatformException catch (error) {
      w('app update: cannot open $url: $error');
      return false;
    }
  }

  Future<bool> _launchWithFallback(String url, String fallback) async =>
      await _tryLaunch(url) || await _tryLaunch(fallback);

  Future<_UpdateChannel?> _discoverChannel() async {
    if (_windows) {
      storeUpdateChannel.setMethodCallHandler((call) async {
        if (call.method == 'progress' &&
            mounted &&
            state.status == AppUpdateStatus.downloading) {
          _setState(
            AppUpdateStatus.downloading,
            progress: call.arguments as double,
          );
        }
      });
      // Not packaged: not the Store build.
      if (await _queryStoreUpdates()) {
        if (!mounted) return const _StoreChannel();
        _setState(state.status, progress: state.progress, hasChannel: true);
        _timer = Timer.periodic(const Duration(hours: 6), (_) => _check());
        return const _StoreChannel();
      }
    }
    final channel = await _detectDesktopChannel();
    if (channel == null || !mounted) return channel;
    _setState(state.status, progress: state.progress, hasChannel: true);
    if (channel is _MacChannel) {
      _macChannel.setMethodCallHandler((call) async {
        if (call.method == 'progress' && mounted) {
          _setState(
            AppUpdateStatus.downloading,
            progress: call.arguments as double,
          );
        }
      });
    }
    unawaited(_schedule());
    return channel;
  }

  Future<_UpdateChannel?> _detectDesktopChannel() async {
    if (!_windows && Platform.isMacOS) {
      final info = (await _macChannel.invokeMapMethod<String, dynamic>(
        'channel',
      ))!;
      final mac = macUpdateChannel(
        environment: info['environment'] as String?,
        sparkle: info['sparkle'] as bool,
      );
      return mac == null ? null : _MacChannel(mac);
    }
    final environment = Platform.environment;
    final executable = Platform.resolvedExecutable;
    if (Platform.isLinux) {
      final snapArch = linuxSnapArch(
        environment: environment,
        executable: executable,
        abi: Abi.current(),
      );
      if (snapArch != null) return _SnapChannel(snapArch);
    }
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
    if (package == null) return null;

    final key = (await rootBundle.loadString(
      'assets/update_ed25519.pub',
    )).trim();
    // The release key is not set up yet, so there is nothing to trust.
    if (key.isEmpty) return null;
    if (!await canInstallUpdate(package, environment, executable)) {
      i('app update: $package cannot install by itself');
      return null;
    }
    return _PackageChannel(package, base64Decode(key));
  }

  Future<void> _schedule() async {
    await _check();
    if (!mounted) return;
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

  @visibleForTesting
  Future<void> checkStore() => _check();

  Future<void> checkForUpdate() async {
    await _channel;
    if (!mounted || state.status != AppUpdateStatus.none) return;
    await _check();
  }

  Future<void> _check() =>
      _checkInFlight ??= _runCheck().whenComplete(() => _checkInFlight = null);

  Future<void> _runCheck() async {
    final channel = await _channel;
    if (!mounted ||
        state.status == AppUpdateStatus.downloading ||
        channel == null) {
      return;
    }
    if (channel is _StoreChannel) {
      await _queryStoreUpdates();
      return;
    }
    try {
      final info = await getPackageInfo();
      final build = int.parse(info.buildNumber);
      // 0 is the fallback when the build is unknown; every item is newer.
      if (build <= 0) return;
      AppUpdateItem? item;
      final available = switch (channel) {
        _MacChannel(channel: MacUpdateChannel.appStore) => isNewerVersion(
          appStoreVersion(await _get(macAppStoreLookupUrl)) ?? '',
          info.version,
        ),
        // TestFlight gets the same builds as the DMG.
        _MacChannel(
          channel: MacUpdateChannel.testFlight || MacUpdateChannel.dmg,
        ) =>
          (latestAppcastBuild(await _get(_appcastUrl), 'dmg') ?? 0) > build,
        _SnapChannel(:final arch) => isNewerVersion(
          snapStoreVersion(
                await _get(
                  snapStoreInfoUrl,
                  headers: const {'Snap-Device-Series': '16'},
                ),
                arch,
              ) ??
              '',
          info.version,
        ),
        _PackageChannel(:final package) =>
          (item = findAppUpdate(await _get(_appcastUrl), package, build)) !=
              null,
        _StoreChannel() => false,
      };
      if (!mounted || !available) return;
      // The state stays available, so a later appcast without this package
      // must not empty the item.
      _item = item ?? _item;
      if (state.status == AppUpdateStatus.none) {
        _setState(AppUpdateStatus.available);
      }
    } catch (error) {
      // No network or no appcast yet: check again later.
      i('app update: check failed: $error');
    }
  }

  Future<String> _get(String url, {Map<String, Object?>? headers}) async =>
      (await _dio().get<String>(
        url,
        options: Options(responseType: ResponseType.plain, headers: headers),
      )).data!;

  /// False when the app is not packaged, so it is not the Store build.
  Future<bool> _queryStoreUpdates() async {
    if (state.status == AppUpdateStatus.downloading) return true;
    try {
      final count = await storeUpdateChannel.invokeMethod<int>(
        'storeUpdateCount',
      );
      if (count == null) return false;
      if (!mounted) return true;
      if (count > 0 && state.status == AppUpdateStatus.none) {
        _setState(AppUpdateStatus.available, hasChannel: true);
      } else if (count == 0 &&
          (state.status == AppUpdateStatus.available ||
              state.status == AppUpdateStatus.failed)) {
        // Installed elsewhere or withdrawn: a click would fail with no_updates.
        // Not while installing: this check may have started before the click.
        _setState(AppUpdateStatus.none, hasChannel: true);
      }
    } on PlatformException catch (error) {
      i('app update: store check failed: $error');
    }
    return true;
  }

  Future<void> _installStore() async {
    _setState(AppUpdateStatus.downloading);
    try {
      await storeUpdateChannel.invokeMethod<void>('installStoreUpdates');
      // The Store restarts the app after the install.
      _setState(AppUpdateStatus.none);
    } on PlatformException catch (error) {
      e('app update: store install failed: $error');
      _setState(AppUpdateStatus.failed);
    }
  }

  /// Starts an update via the active channel. When [forced] is true (the
  /// 10006 upgrade page), known channels still run their own update action
  /// even if `state.status` is [AppUpdateStatus.none]. Returns false when
  /// the caller should fall back to opening the website download page.
  Future<bool> update({bool forced = false}) {
    if (_updateInFlight != null ||
        state.status == AppUpdateStatus.downloading) {
      return Future.value(true);
    }
    return _updateInFlight = _runUpdate(
      forced: forced,
    ).whenComplete(() => _updateInFlight = null);
  }

  Future<bool> _runUpdate({required bool forced}) async {
    final channel = await _channel;
    if (!mounted || state.status == AppUpdateStatus.downloading) return true;
    if (!forced && state.status == AppUpdateStatus.none) return false;
    switch (channel) {
      case _StoreChannel():
        if (state.status == AppUpdateStatus.none) {
          return _launchWithFallback(microsoftStoreUrl, microsoftStoreWebUrl);
        }
        await _installStore();
        return true;
      case _MacChannel(channel: MacUpdateChannel.appStore):
        return _tryLaunch(macAppStoreUrl);
      case _MacChannel(channel: MacUpdateChannel.testFlight):
        return _tryLaunch(macTestFlightUrl);
      case _MacChannel(channel: MacUpdateChannel.dmg):
        await _installSparkle();
        return true;
      case _SnapChannel():
        return _launchWithFallback(snapStoreUrl, snapStoreWebUrl);
      case _PackageChannel(:final publicKey):
        if (_item == null && forced) {
          await _check();
          if (!mounted || state.status == AppUpdateStatus.downloading) {
            return true;
          }
        }
        final item = _item;
        if (item == null) return false;
        await _downloadAndInstall(item, publicKey);
        return true;
      case null:
        return false;
    }
  }

  Future<void> _downloadAndInstall(
    AppUpdateItem item,
    List<int> publicKey,
  ) async {
    _setState(AppUpdateStatus.downloading);
    final environment = Platform.environment;
    File? file;
    try {
      file = await createUpdateFile(item.package, environment);
      await _dio().downloadUri(
        item.url,
        file.path,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            _setState(AppUpdateStatus.downloading, progress: received / total);
          }
        },
      );
      if (!verifyAppUpdate(item, await sha256File(file), publicKey)) {
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
          sha256: item.sha256,
        );
      }
      exit(0);
    } catch (error, stack) {
      e('app update: install ${item.fileName} failed: $error $stack');
      _setState(AppUpdateStatus.failed);
      try {
        await file?.parent.delete(recursive: true);
      } on FileSystemException catch (error) {
        w('app update: cannot delete the download: $error');
      }
    }
  }

  Future<void> _installSparkle() async {
    if (state.status == AppUpdateStatus.downloading) {
      return;
    }
    _setState(AppUpdateStatus.downloading);
    try {
      // Sparkle checks the EdDSA signature, then quits and relaunches the app.
      await _macChannel.invokeMethod('install', _appcastUrl);
    } catch (error) {
      e('app update: Sparkle install failed: $error');
      _setState(AppUpdateStatus.failed);
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
