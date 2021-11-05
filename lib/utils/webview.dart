import 'dart:convert';
import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../bloc/setting_cubit.dart';
import '../db/mixin_database.dart';
import '../ui/home/bloc/multi_auth_cubit.dart';

final kIsSupportWebview =
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;

void clearWebviewCacheAndCookies() {
  WebviewWindow.clearAll();
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

Future<void> openBotWebviewWindow(
  BuildContext context,
  App app, {
  String? conversationId,
}) =>
    openWebviewWindowWithUrl(
      context,
      app.homeUri,
      conversationId: conversationId,
      title: app.name,
    );

Future<void> openWebviewWindowWithUrl(
  BuildContext context,
  String url, {
  String? conversationId,
  String? title,
}) async {
  final brightness = context.read<SettingCubit>().brightness;
  final packageInfo = await PackageInfo.fromPlatform();
  final webview = await WebviewWindow.create(
    configuration: CreateConfiguration(
      windowWidth: 380,
      windowHeight: 750,
      title: title ?? '',
    ),
  );
  final mixinContext = jsonEncode(await _mixinContext(context, conversationId));
  webview
    ..setBrightness(brightness)
    ..addScriptToExecuteOnDocumentCreated(
      _mixinContextProviderJavaScript(mixinContext),
    );
  await webview.setApplicationNameForUserAgent(' Mixin/${packageInfo.version}');
  webview.launch(url);
}
