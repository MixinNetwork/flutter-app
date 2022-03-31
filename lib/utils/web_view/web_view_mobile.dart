import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../extension/extension.dart';
import 'web_view_interface.dart';

class MobileMixinWebView extends MixinWebView {
  final _cookieManager = CookieManager();

  @override
  void clearWebViewCacheAndCookies() {
    _cookieManager.clearCookies();
    // TODO clear cache.
  }

  @override
  Future<bool> isWebViewRuntimeAvailable() async => true;

  @override
  Future<void> openWebViewWindowWithUrl(
    BuildContext context,
    String url, {
    String? conversationId,
    String? title,
  }) async {
    await showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) =>
          _FullWindowInAppWebViewPage(initialUrl: url),
    );
  }

  @override
  Future<void> showWebViewUnavailableDialog({
    required BuildContext context,
  }) async {
    // do nothing.
  }
}

class _FullWindowInAppWebViewPage extends HookWidget {
  const _FullWindowInAppWebViewPage({
    Key? key,
    required this.initialUrl,
  }) : super(key: key);

  final String initialUrl;

  @override
  Widget build(BuildContext context) {
    final webViewController = useState<WebViewController?>(null);
    return Material(
      color: context.theme.background,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: WebView(
                initialUrl: initialUrl,
                javascriptMode: JavascriptMode.unrestricted,
                onWebViewCreated: (WebViewController controller) {
                  webViewController.value = controller;
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 10,
              width: 88,
              height: 32,
              child: _WebControl(
                webViewController: webViewController.value,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebControl extends StatelessWidget {
  const _WebControl({
    Key? key,
    required this.webViewController,
  }) : super(key: key);

  final WebViewController? webViewController;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: context.theme.background,
          border: Border.all(color: context.theme.sidebarSelected),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                child: Icon(
                  Icons.more_horiz,
                  size: 24,
                  color: context.theme.icon,
                ),
                onTap: () {},
              ),
            ),
            Container(
              width: 1,
              height: 20,
              color: context.theme.sidebarSelected,
            ),
            Expanded(
              child: InkWell(
                child: Icon(
                  Icons.close,
                  size: 24,
                  color: context.theme.icon,
                ),
                onTap: () {
                  Navigator.maybePop(context);
                },
              ),
            ),
          ],
        ),
      );
}
