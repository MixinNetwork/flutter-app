import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../db/mixin_database.dart';
import '../../widgets/message/item/action_card/action_card_data.dart';
import '../platform.dart';
import 'web_view_desktop.dart';
import 'web_view_mobile.dart';

abstract class MixinWebView {
  MixinWebView();

  factory MixinWebView._platform() =>
      kPlatformIsDesktop ? DesktopMixinWebView() : MobileMixinWebView();

  static MixinWebView? _instance;

  static MixinWebView get instance => _instance ??= MixinWebView._platform();

  Future<bool> isWebViewRuntimeAvailable();

  Future<void> showWebViewUnavailableDialog({required BuildContext context});

  void clearWebViewCacheAndCookies();

  Future<void> openWebViewWindowWithUrl(
    BuildContext context,
    String url, {
    required ProviderContainer container,
    String? conversationId,
    String? title,
    App? app,
    AppCardData? appCardData,
  });

  Future<void> openBotWebViewWindow(
    BuildContext context,
    ProviderContainer container,
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
      container: container,
      conversationId: conversationId,
      title: app.name,
      app: app,
    );
  }
}
