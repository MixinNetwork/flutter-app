import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../constants/resources.dart';
import '../ui/provider/ui_context_providers.dart';
import 'action_button.dart';

class WebViewNavigationBar extends ConsumerWidget {
  const WebViewNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final state = TitleBarWebViewState.of(context);
    final controller = TitleBarWebViewController.of(context);
    return Row(
      children: [
        const SizedBox(width: 10),
        ActionButton(
          name: Resources.assetsImagesIcBackSvg,
          color: state.canGoBack
              ? theme.icon
              : theme.icon.withValues(alpha: 0.5),
          onTap: controller.back,
          size: 16,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: 16),
        ActionButton(
          name: Resources.assetsImagesIcForwardSvg,
          color: state.canGoForward
              ? theme.icon
              : theme.icon.withValues(alpha: 0.5),
          onTap: controller.forward,
          size: 16,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: 16),
        ActionButton(
          name: Resources.assetsImagesWebViewRefreshSvg,
          color: theme.icon,
          onTap: controller.reload,
          size: 16,
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
