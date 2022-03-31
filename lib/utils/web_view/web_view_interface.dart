import 'package:flutter/widgets.dart';

import '../../db/mixin_database.dart';
import '../platform.dart';
import 'web_view_desktop.dart';
import 'web_view_mobile.dart';

abstract class MixinWebView {
  MixinWebView();

  factory MixinWebView._platform() {
    if (kPlatformIsDesktop) {
      return DesktopMixinWebView();
    } else {
      return MobileMixinWebView();
    }
  }

  static MixinWebView? _instance;

  static MixinWebView get instance => _instance ??= MixinWebView._platform();

  Future<bool> isWebViewRuntimeAvailable();

  Future<void> showWebViewUnavailableDialog({
    required BuildContext context,
  });

  void clearWebViewCacheAndCookies();

  Future<void> openWebViewWindowWithUrl(
    BuildContext context,
    String url, {
    String? conversationId,
    String? title,
    App? app,
  });

  Future<void> openBotWebViewWindow(
    BuildContext context,
    App app, {
    String? conversationId,
  }) async {
    if (!await isWebViewRuntimeAvailable()) {
      await showWebViewUnavailableDialog(context: context);
      return;
    }
    return openWebViewWindowWithUrl(
      context,
      app.homeUri,
      conversationId: conversationId,
      title: app.name,
      app: app,
    );
  }
}
