import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../constants/constants.dart';
import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';
import '../../utils/logger.dart';
import '../dialog.dart';
import '../toast.dart';

enum CaptchaType { gCaptcha, hCaptcha }

/// return:
/// list[0] : CaptchaType
/// list[1] : String (captcha token)
Future<List<dynamic>?> showCaptchaWebViewDialog(BuildContext context) =>
    showMixinDialog<List<dynamic>>(
      context: context,
      child: const CaptchaWebViewDialog(),
    );

class CaptchaWebViewDialog extends HookConsumerWidget {
  const CaptchaWebViewDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = useRef<Timer?>(null);
    final captcha = useRef<CaptchaType>(CaptchaType.gCaptcha);

    useEffect(
      () => () {
        timer.value?.cancel();
      },
      [],
    );

    final controller = useMemoized(() {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted);

      void loadFallback() {
        if (captcha.value == CaptchaType.gCaptcha) {
          captcha.value = CaptchaType.hCaptcha;
          _loadCaptcha(controller, CaptchaType.hCaptcha);
        } else {
          controller.loadRequest(Uri.parse('about:blank'));
          showToastFailed(ToastError(context.l10n.recaptchaTimeout));
          Navigator.pop(context);
        }
      }

      controller
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              timer.value = Timer(const Duration(seconds: 15), loadFallback);
            },
            onPageFinished: (url) {
              timer.value?.cancel();
              timer.value = null;
            },
          ),
        )
        ..addJavaScriptChannel(
          'MixinContextTokenCallback',
          onMessageReceived: (message) {
            timer.value?.cancel();
            timer.value = null;
            final token = message.message;
            Navigator.pop(context, [captcha.value, token]);
          },
        )
        ..addJavaScriptChannel(
          'MixinContextErrorCallback',
          onMessageReceived: (message) {
            e('on captcha error: ${message.message}');
            timer.value?.cancel();
            timer.value = null;
            loadFallback();
          },
        );
      _loadCaptcha(controller, captcha.value);
      return controller;
    });

    return SizedBox(
      width: 400,
      height: 520,
      child: WebViewWidget(controller: controller),
    );
  }
}

Future<void> _loadCaptcha(
  WebViewController controller,
  CaptchaType type,
) async {
  i('load captcha: $type');
  final html = await rootBundle.loadString(Resources.assetsCaptchaHtml);
  final String apiKey;
  final String src;
  switch (type) {
    case CaptchaType.gCaptcha:
      apiKey = kRecaptchaKey;
      src =
          'https://www.recaptcha.net/recaptcha/api.js'
          '?onload=onGCaptchaLoad&render=explicit';
    case CaptchaType.hCaptcha:
      apiKey = hCaptchaKey;
      src =
          'https://hcaptcha.com/1/api.js'
          '?onload=onHCaptchaLoad&render=explicit';
  }
  final htmlWithCaptcha = html
      .replaceAll('#src', src)
      .replaceAll('#apiKey', apiKey);

  await controller.clearCache();
  await controller.loadHtmlString(
    htmlWithCaptcha,
    baseUrl: 'https://mixin.one',
  );
}
