import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../db/mixin_database.dart';
import '../../widgets/dialog.dart';
import '../../widgets/high_light_text.dart';
import '../../widgets/message/item/action_card/action_card_data.dart';
import '../extension/extension.dart';
import '../file.dart';
import '../system/package_info.dart';
import '../uri_utils.dart';

import 'desktop/bot_window.dart';
import 'web_view_interface.dart';

class DesktopMixinWebView extends MixinWebView {
  /// Keys of the windows being created.
  final _opening = <String>{};

  // The folder to store WebView user data.
  // Only works on Windows, to avoid we do not have write permission to the folder
  // of executable file.
  WindowsWebviewOptions get _windowsOptions => WindowsWebviewOptions(
    userDataFolder: p.join(mixinDocumentsDirectory.path, 'web_view_user_data'),
  );

  @override
  void clearWebViewCacheAndCookies() {
    BotWindow.closeAll();
    WebviewWindow.clearAll(windows: _windowsOptions);
  }

  @override
  Future<bool> isWebViewRuntimeAvailable() async =>
      !Platform.isWindows || await WebviewWindow.isWebviewAvailable();

  @override
  Future<void> openWebViewWindowWithUrl(
    BuildContext context,
    String url, {
    String? conversationId,
    String? title,
    App? app,
    AppCardData? appCardData,
  }) async {
    // The page reads the conversation from MixinContext, so another
    // conversation gets its own window.
    final key = '${app?.appId ?? appCardData?.appId}|$conversationId|$url';
    final existing = BotWindow.find(key);
    if (existing != null && await existing.focus()) return;
    // A second click while the window is still being created.
    if (!_opening.add(key)) return;
    try {
      final appId = appCardData?.appId;
      app ??= appId == null
          ? null
          : await context.database.appDao.findAppById(appId);
      if (!context.mounted) return;
      final packageInfo = await getPackageInfo();
      if (!context.mounted) return;
      await BotWindow.open(
        context,
        key: key,
        url: url,
        title: app?.name ?? title ?? '',
        app: app,
        appCardData: appCardData,
        conversationId: conversationId,
        version: packageInfo.version,
        windows: _windowsOptions,
      );
    } finally {
      _opening.remove(key);
    }
  }

  @override
  Future<void> showWebViewUnavailableDialog({required BuildContext context}) =>
      showMixinDialog(
        context: context,
        child: const _BotWebViewRuntimeInstallDialog(),
      );
}

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
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => openUri(context, runtimeDownloadLink),
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
