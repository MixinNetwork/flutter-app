import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/constants.dart';
import '../widgets/conversation/conversation_dialog.dart';
import '../widgets/toast.dart';
import '../widgets/user/user_dialog.dart';
import 'extension/extension.dart';
import 'logger.dart';
import 'webview.dart';

// Try open url in app webview.
// fallback to launch system browser if WebView is not available.
Future<bool> openUriWithWebView(
  BuildContext context,
  String text, {
  String? title,
  String? conversationId,
}) async {
  if (kIsSupportWebView) {
    return openUri(context, text, fallbackHandler: (url) async {
      if (await isWebViewRuntimeAvailable()) {
        await openWebViewWindowWithUrl(
          context,
          url,
          conversationId: conversationId,
          title: title,
        );
        return true;
      }
      return launch(url);
    });
  } else {
    return openUri(context, text);
  }
}

Future<bool> openUri(
  BuildContext context,
  String text, {
  Future<bool> Function(String url) fallbackHandler = launch,
}) async {
  final uri = Uri.parse(text);
  if (uri.scheme.isEmpty) return Future.value(false);

  if (uri.isMixin) {
    final userId = uri.userId;
    if (userId != null) {
      await showUserDialog(context, userId);
      return true;
    }

    final code = uri.code;
    if (code != null) {
      showToastLoading(context);
      try {
        final mixinResponse =
            await context.accountServer.client.accountApi.code(code);
        final data = mixinResponse.data;
        if (data is User) {
          await showUserDialog(context, data.userId);
          return true;
        } else if (data is ConversationResponse) {
          await showConversationDialog(context, data, code);
          return true;
        }

        await showToastFailed(
            context, ToastError(context.l10n.uriCheckOnPhone));
        return false;
      } catch (error) {
        e('open code: $error');
        await showToastFailed(context, error);
        return false;
      }
    }

    await showToastFailed(context, ToastError(context.l10n.uriCheckOnPhone));
    return false;
  }

  return fallbackHandler(uri.toString());
}

extension _MixinUriExtension on Uri {
  bool get _isMixinScheme => isScheme(mixinScheme);

  bool get _isMixinHost => host == mixinHost || host == 'www.$mixinHost';

  bool get isMixin => _isMixinScheme || _isMixinHost;

  bool _isTypeScheme(MixinSchemeHost type) =>
      _isMixinScheme &&
      host == enumConvertToString(type) &&
      pathSegments.length == 1 &&
      pathSegments.single.isNotEmpty;

  bool _isTypeHost(MixinSchemeHost type) =>
      _isMixinHost &&
      pathSegments.length == 2 &&
      pathSegments[0] == enumConvertToString(type) &&
      pathSegments[1].isNotEmpty;

  String? _getValue(MixinSchemeHost type) {
    if (_isTypeScheme(type)) return pathSegments.single;
    if (_isTypeHost(type)) return pathSegments[1];
    return null;
  }

  String? get userId => _getValue(MixinSchemeHost.users);

  String? get code => _getValue(MixinSchemeHost.codes);
}
