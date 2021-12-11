import 'dart:convert';
import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

import '../bloc/setting_cubit.dart';
import '../constants/brightness_theme_data.dart';
import '../db/mixin_database.dart';
import '../ui/home/bloc/multi_auth_cubit.dart';
import '../widgets/brightness_observer.dart';
import '../widgets/dialog.dart';
import '../widgets/web_view_navigation_bar.dart';
import 'extension/extension.dart';
import 'file.dart';
import 'uri_utils.dart';

final kIsSupportWebView =
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;

// https://docs.microsoft.com/en-us/microsoft-edge/webview2/concepts/distribution
// We need check WebView Runtime is available on Windows.
Future<bool> isWebViewRuntimeAvailable() async =>
    !Platform.isWindows || await WebviewWindow.isWebviewAvailable();

Future<void> showBotWebViewUnavailableDialog({
  required BuildContext context,
}) async {
  await showMixinDialog(
    context: context,
    child: const _BotWebViewRuntimeInstallDialog(),
  );
}

bool runWebViewNavigationBar(List<String> args) => runWebViewTitleBarWidget(
      args,
      builder: (context) => const BrightnessData(
        brightnessThemeData: lightBrightnessThemeData,
        value: 1,
        child: WebViewNavigationBar(),
      ),
      backgroundColor: const Color(0xFFF0E7EA),
    );

class _BotWebViewRuntimeInstallDialog extends StatelessWidget {
  const _BotWebViewRuntimeInstallDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const runtimeDownloadLink =
        'https://go.microsoft.com/fwlink/p/?LinkId=2124703';
    return SizedBox(
      width: 400,
      child: AlertDialogLayout(
        title: Text(context.l10n.webViewRuntimeNotAvailable),
        content: DefaultTextStyle(
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: context.theme.text,
          ),
          child: Column(
            children: [
              Text(context.l10n.webView2RuntimeInstallDescription),
              const SizedBox(height: 10),
              SelectableText.rich(TextSpan(children: [
                TextSpan(text: context.l10n.downloadLink),
                TextSpan(
                  text: runtimeDownloadLink.overflow,
                  style: TextStyle(color: context.theme.accent),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => openUri(context, runtimeDownloadLink),
                ),
              ])),
              const SizedBox(height: 10),
            ],
          ),
        ),
        actions: <Widget>[
          MixinButton(
            onTap: () => Navigator.pop(context, true),
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );
  }
}

// The folder to store WebView user data.
// Only works on Windows, to avoid we do not have write permission to the folder
// of executable file.
String get _webViewUserDataFolder =>
    p.join(mixinDocumentsDirectory.path, 'web_view_user_data');

void clearWebViewCacheAndCookies() {
  WebviewWindow.clearAll(userDataFolderWindows: _webViewUserDataFolder);
}

Future<Map<String, dynamic>> _mixinContext(
  BuildContext context,
  String? conversationId,
) async {
  assert(MultiAuthCubit.currentAccount != null);

  final mode = context.read<SettingCubit>().brightness ??
      MediaQuery.platformBrightnessOf(context);
  final info = await PackageInfo.fromPlatform();
  return {
    'app_version': info.version,
    'immersive': false,
    'appearance': mode == Brightness.light ? 'light' : 'dark',
    'platform': 'Desktop',
    'locale': Localizations.localeOf(context).toLanguageTag(),
    'conversation_id': conversationId ?? '',
    'currency': MultiAuthCubit.currentAccount?.fiatCurrency
  };
}

String _mixinContextProviderJavaScript(String contextJson) => '''
  window.MixinContext = {
    getContext: function() {
      return '$contextJson'
    }
  }
  ''';

Future<void> openBotWebViewWindow(
  BuildContext context,
  App app, {
  String? conversationId,
}) async {
  if (!await isWebViewRuntimeAvailable()) {
    await showBotWebViewUnavailableDialog(context: context);
    return;
  }
  return openWebViewWindowWithUrl(
    context,
    app.homeUri,
    conversationId: conversationId,
    title: app.name,
  );
}

Future<void> openWebViewWindowWithUrl(
  BuildContext context,
  String url, {
  String? conversationId,
  String? title,
}) async {
  final brightness = context.read<SettingCubit>().brightness;
  final packageInfo = await PackageInfo.fromPlatform();
  final webView = await WebviewWindow.create(
    configuration: CreateConfiguration(
      windowWidth: 380,
      windowHeight: 750,
      title: title ?? '',
      titleBarTopPadding: 22,
      userDataFolderWindows: _webViewUserDataFolder,
    ),
  );
  final mixinContext = jsonEncode(await _mixinContext(context, conversationId));
  webView
    ..setBrightness(brightness)
    ..addScriptToExecuteOnDocumentCreated(
      _mixinContextProviderJavaScript(mixinContext),
    );
  await webView.setApplicationNameForUserAgent(' Mixin/${packageInfo.version}');
  webView.launch(url);
}
