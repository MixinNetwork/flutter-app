import 'dart:convert';
import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../constants/brightness_theme_data.dart';
import '../../db/mixin_database.dart';
import '../../widgets/brightness_observer.dart';
import '../../widgets/dialog.dart';
import '../../widgets/high_light_text.dart';
import '../../widgets/message/item/action_card/action_card_data.dart';
import '../../widgets/web_view_navigation_bar.dart';
import '../extension/extension.dart';
import '../file.dart';
import '../system/package_info.dart';
import '../uri_utils.dart';

import 'web_view_interface.dart';

class DesktopMixinWebView extends MixinWebView {
  // The folder to store WebView user data.
  // Only works on Windows, to avoid we do not have write permission to the folder
  // of executable file.
  String get _webViewUserDataFolder =>
      p.join(mixinDocumentsDirectory.path, 'web_view_user_data');

  @override
  void clearWebViewCacheAndCookies() {
    WebviewWindow.clearAll(userDataFolderWindows: _webViewUserDataFolder);
  }

  @override
  Future<bool> isWebViewRuntimeAvailable() async =>
      !Platform.isWindows || await WebviewWindow.isWebviewAvailable();

  Future<Map<String, dynamic>> _mixinContext(
    BuildContext context,
    String? conversationId,
  ) async {
    assert(context.auth != null);

    final mode =
        context.settingChangeNotifier.brightness ??
        MediaQuery.platformBrightnessOf(context);
    final info = await getPackageInfo();
    debugPrint(
      'info: appName: ${info.appName} packageName: ${info.packageName} version: ${info.version} buildNumber: ${info.buildNumber} buildSignature: ${info.buildSignature} ',
    );
    return {
      'app_version': info.version,
      'immersive': false,
      'appearance': mode == Brightness.light ? 'light' : 'dark',
      'platform': 'Desktop',
      'locale': Localizations.localeOf(context).toLanguageTag(),
      'conversation_id': conversationId ?? '',
      'currency': context.account?.fiatCurrency,
    };
  }

  String _mixinContextProviderJavaScript(String contextJson) => '''
  window.MixinContext = {
    getContext: function() {
      return '$contextJson'
    }
  }
  ''';

  @override
  Future<void> openWebViewWindowWithUrl(
    BuildContext context,
    String url, {
    String? conversationId,
    String? title,
    App? app,
    AppCardData? appCardData,
  }) async {
    final brightness = context.settingChangeNotifier.brightness;
    final packageInfo = await getPackageInfo();
    final webView = await WebviewWindow.create(
      configuration: CreateConfiguration(
        windowWidth: 380,
        windowHeight: 750,
        title: title ?? '',
        titleBarTopPadding: 22,
        userDataFolderWindows: _webViewUserDataFolder,
      ),
    );
    final mixinContext = jsonEncode(
      await _mixinContext(context, conversationId),
    );
    webView
      ..setBrightness(brightness)
      ..addScriptToExecuteOnDocumentCreated(
        _mixinContextProviderJavaScript(mixinContext),
      );
    await webView.setApplicationNameForUserAgent(
      ' Mixin/${packageInfo.version}',
    );
    webView.launch(url);
  }

  @override
  Future<void> showWebViewUnavailableDialog({required BuildContext context}) =>
      showMixinDialog(
        context: context,
        child: const _BotWebViewRuntimeInstallDialog(),
      );
}

bool runWebViewNavigationBar(List<String> args) => runWebViewTitleBarWidget(
  args,
  builder:
      (context) => const BrightnessData(
        brightnessThemeData: lightBrightnessThemeData,
        value: 1,
        child: WebViewNavigationBar(),
      ),
  backgroundColor: const Color(0xFFF0E7EA),
);

class _BotWebViewRuntimeInstallDialog extends StatelessWidget {
  const _BotWebViewRuntimeInstallDialog();

  @override
  Widget build(BuildContext context) {
    const runtimeDownloadLink =
        'https://go.microsoft.com/fwlink/p/?LinkId=2124703';
    return SizedBox(
      width: 400,
      child: AlertDialogLayout(
        title: Text(context.l10n.webviewRuntimeUnavailable),
        content: DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: context.theme.text,
          ),
          child: Column(
            children: [
              Text(context.l10n.webview2RuntimeInstallDescription),
              const SizedBox(height: 10),
              CustomSelectableText.rich(
                TextSpan(
                  children: [
                    TextSpan(text: context.l10n.downloadLink),
                    TextSpan(
                      text: runtimeDownloadLink.overflow,
                      style: TextStyle(color: context.theme.accent),
                      recognizer:
                          TapGestureRecognizer()
                            ..onTap =
                                () => openUri(context, runtimeDownloadLink),
                    ),
                  ],
                ),
              ),
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
