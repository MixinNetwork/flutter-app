import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';

import '../constants/resources.dart';
import '../utils/extension/extension.dart';
import 'action_button.dart';

class WebViewNavigationBar extends StatelessWidget {
  const WebViewNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = TitleBarWebViewState.of(context);
    final controller = TitleBarWebViewController.of(context);
    return Row(
      children: [
        const SizedBox(width: 10),
        ActionButton(
          name: Resources.assetsImagesIcBackSvg,
          color: state.canGoBack
              ? context.theme.icon
              : context.theme.icon.withValues(alpha: 0.5),
          onTap: controller.back,
          size: 16,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: 16),
        ActionButton(
          name: Resources.assetsImagesIcForwardSvg,
          color: state.canGoForward
              ? context.theme.icon
              : context.theme.icon.withValues(alpha: 0.5),
          onTap: controller.forward,
          size: 16,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: 16),
        ActionButton(
          name: Resources.assetsImagesWebViewRefreshSvg,
          color: context.theme.icon,
          onTap: controller.reload,
          size: 16,
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
