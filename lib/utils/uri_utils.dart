import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/constants.dart';
import '../widgets/conversation/conversation_dialog.dart';
import '../widgets/message/item/transfer/transfer_page.dart';
import '../widgets/toast.dart';
import '../widgets/unknown_mixin_url_dialog.dart';
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
    if (userId != null && userId.trim().isNotEmpty) {
      await showUserDialog(context, userId);
      return true;
    }

    final code = uri.code;
    if (code != null && code.trim().isNotEmpty) {
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

        Toast.dismiss();
        await showUnknownMixinUrlDialog(context, uri);
        return false;
      } catch (error) {
        e('open code: $error');
        await showToastFailed(context, error);
        return false;
      }
    }

    final snapshotTraceId = uri.snapshotTraceId;
    if (snapshotTraceId != null && snapshotTraceId.trim().isNotEmpty) {
      try {
        showToastLoading(context);

        final snapshotId = await context.database.snapshotDao
            .snapshotIdByTraceId(snapshotTraceId)
            .getSingleOrNull();

        if (snapshotId != null && snapshotId.trim().isNotEmpty) {
          Toast.dismiss();
          await showTransferDialog(context, snapshotId);
          return true;
        }

        final snapshot = await context.accountServer
            .updateSnapshotByTraceId(traceId: snapshotTraceId);

        Toast.dismiss();
        await showTransferDialog(context, snapshot.snapshotId);
        return true;
      } catch (error) {
        e('get snapshot by traceId: $error');
        await showToastFailed(context, error);
        return false;
      }
    }

    if (uri.isMixinScheme) {
      Toast.dismiss();
      await showUnknownMixinUrlDialog(context, uri);
      return false;
    }
  }

  return fallbackHandler(uri.toString());
}

extension _MixinUriExtension on Uri {
  bool get isMixinScheme => isScheme(mixinScheme);

  bool get _isMixinHost => host == mixinHost || host == 'www.$mixinHost';

  bool get isMixin => isMixinScheme || _isMixinHost;

  bool _isTypeScheme(MixinSchemeHost type) =>
      isMixinScheme && host == enumConvertToString(type);

  bool _isTypeHost(MixinSchemeHost type) =>
      _isMixinHost &&
      pathSegments.isNotEmpty &&
      pathSegments[0] == enumConvertToString(type);

  String? _getValue(MixinSchemeHost type) {
    if (_isTypeScheme(type)) {
      return pathSegments.isNotEmpty ? pathSegments.single : null;
    }
    if (_isTypeHost(type)) {
      return pathSegments.isNotEmpty ? pathSegments[1] : null;
    }
    return null;
  }

  String? get userId => _getValue(MixinSchemeHost.users);

  String? get code => _getValue(MixinSchemeHost.codes);

  String? get snapshotTraceId {
    if (_isTypeScheme(MixinSchemeHost.snapshots)) {
      return queryParameters['trace'];
    }
  }
}
