import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter/gestures.dart';
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/ui/home/app_update_item.dart';
import 'package:flutter_app/ui/provider/app_update_provider.dart';
import 'package:flutter_app/ui/provider/database_provider.dart';
import 'package:flutter_app/utils/system/main_window.dart';
import 'package:flutter_app/utils/system/package_info.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_portal/flutter_portal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rhttp/rhttp.dart';
import 'package:window_manager/window_manager.dart';

// The app of the end-to-end update tests (dist/test_update_macos.sh,
// .github/workflows/update-test.yml): it shows its version and the
// sidebar update item, without an account. With MIXIN_UPDATE_E2E_TAP=1 it
// taps the item when it shows, else a person clicks it. Not shipped.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The update client gets the network through rhttp, as in lib/main.dart.
  await Rhttp.init();
  final info = await getPackageInfo();
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWith((ref) => DatabaseOpener())],
      child: BrightnessData(
        value: 0,
        brightnessThemeData: lightBrightnessThemeData,
        // SelectItem shows its tooltip in a Portal, as in lib/app.dart.
        child: Portal(
          child: MaterialApp(
            localizationsDelegates: const [
              Localization.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: Localization.delegate.supportedLocales,
            home: _UpdatePage(version: '${info.version} (${info.buildNumber})'),
          ),
        ),
      ),
    ),
  );
  final window = await ensureMainWindow();
  if (window == null) return;
  restoreWindowForStartup(window);
  window
    ..setSize(const Size(480, 320).toNative(), false)
    ..show()
    ..focus();
}

class _UpdatePage extends ConsumerStatefulWidget {
  const _UpdatePage({required this.version});

  final String version;

  @override
  ConsumerState<_UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends ConsumerState<_UpdatePage> {
  final _item = GlobalKey();
  final _tap = Platform.environment['MIXIN_UPDATE_E2E_TAP'] == '1';

  // A tap through the gesture system, so the item's own onTap runs.
  void _tapItem() => WidgetsBinding.instance.addPostFrameCallback((_) {
    final box = _item.currentContext!.findRenderObject()! as RenderBox;
    final center = box.localToGlobal(box.size.center(Offset.zero));
    GestureBinding.instance
      ..handlePointerEvent(PointerDownEvent(position: center))
      ..handlePointerEvent(PointerUpEvent(position: center));
  });

  @override
  Widget build(BuildContext context) {
    if (_tap) {
      ref.listen(appUpdateProvider, (_, state) {
        switch (state.status) {
          case AppUpdateStatus.available:
            _tapItem();
          case AppUpdateStatus.failed:
            exit(1);
          case AppUpdateStatus.none || AppUpdateStatus.downloading:
        }
      });
    }
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mixin ${widget.version}',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 16),
            SizedBox(width: 200, child: AppUpdateItem(key: _item)),
          ],
        ),
      ),
    );
  }
}
