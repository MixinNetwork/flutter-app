import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../constants/resources.dart';
import '../../db/mixin_database.dart';
import '../../widgets/action_button.dart';
import '../../widgets/cell.dart';
import '../../widgets/dialog.dart';
import '../../widgets/message/item/action_card/action_card_data.dart';
import '../../widgets/user_selector/conversation_selector.dart';
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
    App? app,
  }) async {
    await showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) =>
          _FullWindowInAppWebViewPage(
        initialUrl: url,
        app: app,
      ),
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
    required this.app,
  }) : super(key: key);

  final String initialUrl;
  final App? app;

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
                app: app,
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
    required this.app,
  }) : super(key: key);

  final WebViewController? webViewController;
  final App? app;

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
                onTap: () {
                  final controller = webViewController;
                  if (controller == null) {
                    return;
                  }
                  showMixinDialog(
                    context: context,
                    child: _WebViewActionDialog(
                      webViewController: controller,
                      app: app,
                    ),
                  );
                },
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

class _WebViewActionDialog extends StatelessWidget {
  const _WebViewActionDialog({
    Key? key,
    required this.webViewController,
    required this.app,
  }) : super(key: key);

  final WebViewController webViewController;

  final App? app;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 16),
                const Spacer(),
                ActionButton(
                  name: Resources.assetsImagesIcCloseSvg,
                  color: context.theme.icon,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 16),
              ],
            ),
            const SizedBox(height: 16),
            CellGroup(
              child: Column(
                children: [
                  if (app != null)
                    CellItem(
                      title: Text(context.l10n.share),
                      leading: SvgPicture.asset(
                        Resources.assetsImagesShareSvg,
                        width: 24,
                        height: 24,
                        color: context.theme.text,
                      ),
                      trailing: null,
                      onTap: () async {
                        Navigator.pop(context);
                        final title = await webViewController.getTitle();
                        final url = await webViewController.currentUrl();
                        final accountServer = context.accountServer;
                        final result = await showConversationSelector(
                          context: context,
                          singleSelect: true,
                          title: context.l10n.forward,
                          onlyContact: false,
                        );
                        if (result == null || result.isEmpty) return;

                        final app = this.app!;

                        await accountServer.sendAppCardMessage(
                          conversationId: result.first.conversationId,
                          recipientId: result.first.userId,
                          data: AppCardData(
                            app.appId,
                            app.iconUrl,
                            app.name,
                            title ?? app.name,
                            url ?? app.homeUri,
                            app.updatedAt?.toIso8601String() ?? '',
                            true,
                          ),
                        );
                      },
                    ),
                  CellItem(
                    title: Text(context.l10n.refresh),
                    leading: SvgPicture.asset(
                      Resources.assetsImagesInviteRefreshSvg,
                      width: 24,
                      height: 24,
                      color: context.theme.text,
                    ),
                    trailing: null,
                    onTap: () {
                      webViewController.reload();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
}
