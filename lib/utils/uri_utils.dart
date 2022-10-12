import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/constants.dart';
import '../crypto/uuid/uuid.dart';
import '../db/mixin_database.dart' hide User;
import '../ui/home/bloc/conversation_cubit.dart';
import '../widgets/conversation/conversation_dialog.dart';
import '../widgets/message/item/action_card/action_card_data.dart';
import '../widgets/message/item/transfer/transfer_page.dart';
import '../widgets/message/send_message_dialog/send_message_dialog.dart';
import '../widgets/toast.dart';
import '../widgets/unknown_mixin_url_dialog.dart';
import '../widgets/user/user_dialog.dart';
import 'extension/extension.dart';
import 'logger.dart';
import 'web_view/web_view_interface.dart';

// Try open url in app webview.
// fallback to launch system browser if WebView is not available.
Future<bool> openUriWithWebView(
  BuildContext context,
  String text, {
  String? title,
  String? conversationId,
  AppCardData? appCardData,
}) async =>
    openUri(context, text, fallbackHandler: (uri) async {
      if (await MixinWebView.instance.isWebViewRuntimeAvailable()) {
        await MixinWebView.instance.openWebViewWindowWithUrl(
          context,
          uri.toString(),
          conversationId: conversationId,
          title: title,
          appCardData: appCardData,
        );
        return true;
      }
      return launchUrl(uri);
    });

Future<bool> openUri(
  BuildContext context,
  String text, {
  Future<bool> Function(Uri uri) fallbackHandler = launchUrl,
  App? app,
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
      return _showCodeDialog(context, code, uri);
    }

    final snapshotTraceId = uri.snapshotTraceId;
    if (snapshotTraceId != null && snapshotTraceId.trim().isNotEmpty) {
      return _showTransferDialog(context, snapshotTraceId);
    }

    final conversationId = uri.conversationId;
    if (conversationId != null && conversationId.trim().isNotEmpty) {
      return _selectConversation(uri, context, conversationId);
    }

    if (uri.isSend) {
      return showSendDialog(context, uri.categoryOfSend,
          uri.conversationIdOfSend, uri.dataOfSend, app);
    }

    if (uri.appId != null && uri.actionIsOpen) {
      await context.accountServer.refreshUsers([uri.appId!]);
      final app = await context.database.appDao.findAppById(uri.appId!);
      var homeUri = Uri.tryParse(app?.homeUri ?? '');

      if (app == null || homeUri == null) {
        await showToastFailed(
          context,
          ToastError(
            context.l10n.botNotFound,
          ),
        );
        return true;
      }

      final queryParameters = ({...homeUri.queryParameters})
        ..addAll(({...uri.queryParameters})..remove('action'));

      homeUri = homeUri.replace(queryParameters: queryParameters);
      if (await MixinWebView.instance.isWebViewRuntimeAvailable()) {
        await MixinWebView.instance.openWebViewWindowWithUrl(
          context,
          homeUri.toString(),
          conversationId: conversationId,
        );
        return true;
      }
      return fallbackHandler(homeUri);
    }

    if (uri.isMixinScheme) {
      Toast.dismiss();
      await showUnknownMixinUrlDialog(context, uri);
      return false;
    }
  }

  return fallbackHandler(uri);
}

Future<bool> _showCodeDialog(BuildContext context, String code, Uri uri) async {
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

Future<bool> _showTransferDialog(
    BuildContext context, String snapshotTraceId) async {
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

Future<bool> _selectConversation(
    Uri uri, BuildContext context, String conversationId) async {
  final userId = uri.queryParameters['user'];
  if (userId != null && userId.trim().isNotEmpty) {
    showToastLoading(context);
    await context.accountServer.refreshUsers([userId]);
    Toast.dismiss();

    if (conversationId !=
        generateConversationId(context.accountServer.userId, userId)) {
      await showToastFailed(context, null);
      return false;
    } else {
      await ConversationCubit.selectUser(context, userId);
      return true;
    }
  }

  await ConversationCubit.selectConversation(context, conversationId,
      sync: true);
  return true;
}

extension _MixinUriExtension on Uri {
  bool get isMixinScheme => isScheme(mixinScheme);

  bool get _isMixinHost => host == mixinHost || host == 'www.$mixinHost';

  bool get isMixin => isMixinScheme || _isMixinHost;

  bool _isTypeScheme(MixinSchemeHost type) =>
      isMixinScheme && host == type.name;

  bool _isTypeHost(MixinSchemeHost type) =>
      _isMixinHost &&
      pathSegments.isNotEmpty &&
      pathSegments.first == type.name;

  String? _getValue(MixinSchemeHost type) {
    if (_isTypeScheme(type)) {
      return pathSegments.isNotEmpty ? pathSegments.single : null;
    }
    if (_isTypeHost(type)) {
      return pathSegments.isNotEmpty ? pathSegments[1] : null;
    }
    return null;
  }

  String? get appId => _getValue(MixinSchemeHost.apps);

  bool get actionIsOpen => queryParameters['action'] == 'open';

  String? get userId => _getValue(MixinSchemeHost.users);

  String? get code => _getValue(MixinSchemeHost.codes);

  String? get conversationId => _getValue(MixinSchemeHost.conversations);

  String? get snapshotTraceId {
    if (_isTypeScheme(MixinSchemeHost.snapshots)) {
      return queryParameters['trace'];
    }
  }

  bool get isSend => _isTypeScheme(MixinSchemeHost.send);

  String? get categoryOfSend {
    if (!isSend) return null;
    return queryParameters['category'];
  }

  String? get conversationIdOfSend {
    if (!isSend) return null;
    return queryParameters['conversation'];
  }

  String? get dataOfSend {
    if (!isSend) return null;
    return queryParameters['data'];
  }
}
