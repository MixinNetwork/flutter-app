import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../constants/resources.dart';
import '../../db/extension/app.dart';
import '../../db/mixin_database.dart';
import '../../widgets/action_button.dart';
import '../../widgets/cell.dart';
import '../../widgets/dialog.dart';
import '../../widgets/message/item/action_card/action_card_data.dart';
import '../../widgets/toast.dart';
import '../../widgets/user_selector/conversation_selector.dart';
import '../extension/extension.dart';
import '../logger.dart';
import 'web_view_interface.dart';

class MobileMixinWebView extends MixinWebView {
  final _cookieManager = WebViewCookieManager();

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
    AppCardData? appCardData,
  }) async {
    await showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) =>
          _FullWindowInAppWebViewPage(
        initialUrl: url,
        app: app,
        appCardData: appCardData,
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

class _FullWindowInAppWebViewPage extends HookConsumerWidget {
  const _FullWindowInAppWebViewPage({
    required this.initialUrl,
    required this.app,
    required this.appCardData,
  });

  final String initialUrl;
  final App? app;
  final AppCardData? appCardData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final webViewController = useMemoized(() => WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(initialUrl)));
    return Material(
      color: context.theme.background,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: WebViewWidget(controller: webViewController),
            ),
            Positioned(
              top: 8,
              right: 10,
              width: 88,
              height: 32,
              child: _WebControl(
                webViewController: webViewController,
                app: app,
                appCardData: appCardData,
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
    required this.webViewController,
    required this.app,
    required this.appCardData,
  });

  final WebViewController? webViewController;
  final App? app;
  final AppCardData? appCardData;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: context.theme.background,
          border: Border.all(color: context.theme.sidebarSelected),
          borderRadius: const BorderRadius.all(Radius.circular(32)),
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
                      appCardData: appCardData,
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
    required this.webViewController,
    required this.app,
    required this.appCardData,
  });

  final WebViewController webViewController;

  final App? app;

  final AppCardData? appCardData;

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
                  _ShareMenuItem(
                    appCardData: appCardData,
                    app: app,
                    webViewController: webViewController,
                  ),
                  CellItem(
                    title: Text(context.l10n.refresh),
                    leading: SvgPicture.asset(
                      Resources.assetsImagesInviteRefreshSvg,
                      width: 24,
                      height: 24,
                      colorFilter:
                          ColorFilter.mode(context.theme.text, BlendMode.srcIn),
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

class _ShareMenuItem extends StatelessWidget {
  const _ShareMenuItem({
    required this.appCardData,
    required this.app,
    required this.webViewController,
  });

  final AppCardData? appCardData;
  final App? app;
  final WebViewController webViewController;

  @override
  Widget build(BuildContext context) => CellItem(
        title: Text(context.l10n.share),
        leading: SvgPicture.asset(
          Resources.assetsImagesShareSvg,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(context.theme.text, BlendMode.srcIn),
        ),
        trailing: null,
        onTap: () async {
          // can not share app
          if (appCardData?.shareable == false) {
            showToastFailed(
              ToastError(context.l10n.appCardShareDisallow),
            );
          } else {
            var title = await webViewController.getTitle();
            final url = await webViewController.currentUrl();

            final selectedConversation = await showConversationSelector(
              context: context,
              singleSelect: true,
              title: context.l10n.forward,
              onlyContact: false,
            );
            if (selectedConversation == null || selectedConversation.isEmpty) {
              return;
            }

            var app = this.app;
            if (appCardData?.appId != null) {
              app = await context.accountServer.getAppAndCheckUser(
                appCardData!.appId!,
                DateTime.tryParse(appCardData!.updatedAt ?? ''),
              );
            }

            if (app != null && url != null && _matchResourcePattern(url, app)) {
              if (title?.trim().isNotEmpty != true) {
                title = app.name;
              }
              final appCardData = AppCardData(
                app.appId,
                app.iconUrl,
                app.name,
                title ?? app.name,
                url,
                app.updatedAt?.toIso8601String() ?? '',
                true,
              );

              await context.accountServer.sendAppCardMessage(
                conversationId: selectedConversation.first.conversationId,
                recipientId: selectedConversation.first.userId,
                data: appCardData,
              );
            } else {
              final category = selectedConversation.first.encryptCategory;
              assert(category != null, 'category must not be null');
              if (category == null) {
                e('selected conversation encrypt category is null');
                return;
              }
              await context.accountServer.sendTextMessage(
                url ?? '',
                category,
                conversationId: selectedConversation.first.conversationId,
                recipientId: selectedConversation.first.userId,
              );
            }
            Navigator.pop(context);
          }
        },
      );
}

bool _matchResourcePattern(String url, App app) {
  String? toSchemeHostOrNull(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    return '${uri.scheme.toLowerCase()}://${uri.host.toLowerCase()}';
  }

  final uri = toSchemeHostOrNull(url);

  final patterns = app.resourcePatternsList;
  if (patterns == null) return false;
  try {
    return patterns.any((element) => toSchemeHostOrNull(element.trim()) == uri);
  } catch (error, stacktrace) {
    e('decode resource patterns error: $error, $stacktrace');
    return false;
  }
}
