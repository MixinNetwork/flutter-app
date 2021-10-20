import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:webview_window/webview_window.dart';

import '../bloc/setting_cubit.dart';
import '../db/mixin_database.dart';
import '../ui/home/bloc/multi_auth_cubit.dart';

void initWebview() {
  WebviewWindow.init();
}

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
}) async {
  final webview = await WebviewWindow.create(
    configuration: CreateConfiguration(title: app.name),
  );
  final mixinContext = jsonEncode(await _mixinContext(context, conversationId));
  webview
    ..setPromptHandler((prompt, defaultText) {
      if (prompt == 'MixinContext.getContext()') {
        return mixinContext;
      }
      return '';
    })
    ..registerJavaScriptMessageHandler('MixinContext', (name, body) {
      // Webkit need a 'MixinContext' slot to check
      // if we can prompt MixinContent.getContext().
      // https://developers.mixin.one/docs/js-bridge#getcontext
    })
    ..setBrightness(context.read<SettingCubit>().brightness)
    ..addScriptToExecuteOnDocumentCreated(
        _mixinContextProviderJavaScript(mixinContext))
    ..launch(app.homeUri);
}
