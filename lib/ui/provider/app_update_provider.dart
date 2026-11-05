import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  AppUpdateNotifier(this._ref) : super(AppUpdateState.none) {
    unawaited(_start());
  }

  final Ref _ref;
  Timer? _timer;
  late String _package;
  late List<int> _publicKey;
  AppUpdateItem? _item;

  Future<void> _start() async {
    // shortcut: Linux only; macOS and Windows come in later changes.
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
    await _check();
    _timer = Timer.periodic(const Duration(hours: 6), (_) => _check());
  }

  Dio _dio() =>
      Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
      )..applyProxy(
        _ref
            .read(databaseProvider)
            .valueOrNull
            ?.settingProperties
            .activatedProxy,
      );

  Future<void> _check() async {
    if (state.status == AppUpdateStatus.downloading) return;
    try {
      final build = int.parse((await getPackageInfo()).buildNumber);
      final response = await _dio().get<String>(
        // A test appcast; its packages still need the release key.
        Platform.environment['MIXIN_UPDATE_APPCAST_URL'] ?? appcastUrl,
        options: Options(responseType: ResponseType.plain),
      );
      final item = findAppUpdate(response.data!, _package, build);
      if (!mounted || item == null) return;
      _item = item;
      if (state.status == AppUpdateStatus.none) {
        state = const AppUpdateState(AppUpdateStatus.available);
      }
    } catch (error) {
      // No network or no appcast yet: check again later.
      i('app update: check failed: $error');
    }
  }

  Future<void> update() async {
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
