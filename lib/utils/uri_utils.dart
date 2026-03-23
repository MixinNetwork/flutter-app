import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:url_launcher/url_launcher.dart';

import '../account/account_server.dart';
import '../constants/constants.dart';
import '../crypto/uuid/uuid.dart';
import '../db/database.dart';
import '../db/mixin_database.dart' hide User;
import '../enum/encrypt_category.dart';
import '../ui/provider/account_server_provider.dart';
import '../ui/provider/conversation_provider.dart';
import '../ui/provider/database_provider.dart';
import '../ui/provider/multi_auth_provider.dart';
import '../ui/provider/ui_context_providers.dart';
import '../widgets/conversation/conversation_dialog.dart';
import '../widgets/message/item/action_card/action_card_data.dart';
import '../widgets/message/item/transfer/transfer_page.dart';
import '../widgets/message/send_message_dialog/send_message_dialog.dart';
import '../widgets/payment/multisigs_payment_dialog.dart';
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
  ProviderContainer? container,
  String? title,
  String? conversationId,
  AppCardData? appCardData,
}) async => openUri(
  context,
  text,
  container: container,
  fallbackHandler: (uri) async {
    if (container != null &&
        await MixinWebView.instance.isWebViewRuntimeAvailable()) {
      await MixinWebView.instance.openWebViewWindowWithUrl(
        context,
        uri.toString(),
        container: container,
        conversationId: conversationId,
        title: title,
        appCardData: appCardData,
      );
      return true;
    }
    return launchUrl(uri);
  },
);

Future<bool> openUri(
  BuildContext context,
  String text, {
  ProviderContainer? container,
  Future<bool> Function(Uri uri) fallbackHandler = launchUrl,
  App? app,
}) async {
  final accountServer = container?.read(accountServerProvider).value;
  final database = container?.read(databaseProvider).value;
  final l10n = container?.read(localizationProvider) ?? Localization.current;
  final account = container?.read(authAccountProvider);
  final uri = Uri.parse(text);
  if (uri.scheme.isEmpty) return Future.value(false);

  if (uri.isMixin) {
    if (container == null) {
      return fallbackHandler(uri);
    }
    final userId = uri.userId;
    if (userId != null && userId.trim().isNotEmpty) {
      await showUserDialog(context, container, userId);
      return true;
    }

    final code = uri.code;
    if (code != null && code.trim().isNotEmpty) {
      return _showCodeDialog(
        context,
        code,
        uri,
        container: container,
        accountServer: accountServer,
        database: database,
        account: account,
        l10n: l10n,
      );
    }

    final snapshotTraceId = uri.snapshotTraceId;
    if (snapshotTraceId != null && snapshotTraceId.trim().isNotEmpty) {
      return _showTransferDialog(
        context,
        snapshotTraceId,
        accountServer: accountServer,
        database: database,
      );
    }

    final conversationId = uri.conversationId;
    final startText = uri.startTextOfConversation;
    if (conversationId != null && conversationId.trim().isNotEmpty) {
      if (startText?.trim().isNotEmpty == true) {
        try {
          if (database == null || accountServer == null) {
            showToastFailed(null);
            return false;
          }
          final conversation = await database.conversationDao
              .conversationItem(conversationId)
              .getSingleOrNull();

          if (conversation == null) {
            showToastFailed(null);
            return false;
          }

          await ConversationStateNotifier.selectConversation(
            container,
            context,
            conversation.conversationId,
            conversation: conversation,
          );

          await accountServer.sendTextMessage(
            startText ?? '',
            EncryptCategory.plain,
            conversationId: conversationId,
          );

          return true;
        } catch (error) {
          showToastFailed(error);
          return false;
        }
      }

      return _selectConversation(
        uri,
        context,
        conversationId,
        container: container,
        accountServer: accountServer,
      );
    }

    if (uri.isSend) {
      return showSendDialog(
        context,
        uri.categoryOfSend,
        uri.conversationIdOfSend,
        uri.dataOfSend,
        app,
        uri.userOfSend,
        container,
      );
    }

    if (uri.isPay ||
        uri.isMultisigs ||
        uri.isSwap ||
        uri.isMarkets ||
        uri.isMembership) {
      await showUnknownMixinUrlDialog(context, uri);
      return false;
    }

    if (uri.appId != null) {
      if (uri.actionIsOpen) {
        App? app;

        try {
          showToastLoading();

          if (database == null || accountServer == null) {
            showToastFailed(null);
            return false;
          }
          await accountServer.refreshUsers([uri.appId!]);
          app = await database.appDao.findAppById(uri.appId!);
        } finally {
          Toast.dismiss();
        }

        var homeUri = Uri.tryParse(app?.homeUri ?? '');

        if (app == null || homeUri == null) {
          showToastFailed(ToastError(l10n.botNotFound));
          return true;
        }

        final queryParameters = ({...homeUri.queryParameters})
          ..addAll(({...uri.queryParameters})..remove('action'));

        homeUri = homeUri.replace(queryParameters: queryParameters);
        if (await MixinWebView.instance.isWebViewRuntimeAvailable()) {
          await MixinWebView.instance.openWebViewWindowWithUrl(
            context,
            homeUri.toString(),
            container: container,
            conversationId: conversationId,
          );
          return true;
        }
        return fallbackHandler(homeUri);
      } else {
        await showUserDialog(context, container, uri.appId);
        return true;
      }
    }

    if (uri.isMixinScheme) {
      Toast.dismiss();
      await showUnknownMixinUrlDialog(context, uri);
      return false;
    }
  }

  return fallbackHandler(uri);
}

Future<bool> _showCodeDialog(
  BuildContext context,
  String code,
  Uri uri, {
  required ProviderContainer container,
  required AccountServer? accountServer,
  required Database? database,
  required Account? account,
  required Localization l10n,
}) async {
  if (accountServer == null) {
    showToastFailed(null);
    return false;
  }
  showToastLoading();
  try {
    final mixinResponse = await accountServer.client.accountApi.code(code);
    final data = mixinResponse.data;
    Toast.dismiss();
    if (data is User) {
      await showUserDialog(context, container, data.userId);
      return true;
    } else if (data is ConversationResponse) {
      if (database == null) {
        showToastFailed(ToastError(l10n.groupAlreadyIn));
        return false;
      }
      await showConversationDialog(
        context,
        container,
        data,
        code,
        database: database,
        accountServer: accountServer,
        account: account,
        l10n: l10n,
      );
      return true;
    } else if (data is PaymentCodeResponse) {
      final asset = await accountServer.checkAsset(assetId: data.assetId);
      if (asset == null) {
        await showUnknownMixinUrlDialog(context, uri);
        return false;
      }
      await showMultisigsPaymentDialog(
        context,
        item: MultisigsPaymentItem(
          senders: [accountServer.userId],
          receivers: data.receivers,
          threshold: data.threshold,
          asset: asset,
          amount: data.amount,
          state: data.status,
          uri: uri,
        ),
      );
      return true;
    } else if (data is MultisigsResponse) {
      debugPrint('PaymentCodeResponse: ${data.toJson()}');
      final asset = await accountServer.checkAsset(assetId: data.assetId);
      if (asset == null) {
        await showUnknownMixinUrlDialog(context, uri);
        return false;
      }
      await showMultisigsPaymentDialog(
        context,
        item: Multi2MultiItem(
          senders: data.senders,
          receivers: data.receivers,
          threshold: data.threshold,
          asset: asset,
          amount: data.amount,
          state: data.state,
          action: data.action,
          uri: uri,
        ),
      );
      return true;
    }
    await showUnknownMixinUrlDialog(context, uri);
    return false;
  } catch (error) {
    e('open code: $error');
    showToastFailed(error);
    return false;
  }
}

Future<bool> _showTransferDialog(
  BuildContext context,
  String snapshotTraceId, {
  required AccountServer? accountServer,
  required Database? database,
}) async {
  try {
    showToastLoading();

    if (database == null || accountServer == null) {
      showToastFailed(null);
      return false;
    }

    final snapshotId = await database.snapshotDao
        .snapshotIdByTraceId(snapshotTraceId)
        .getSingleOrNull();

    if (snapshotId != null && snapshotId.trim().isNotEmpty) {
      Toast.dismiss();
      await showTransferDialog(context, snapshotId);
      return true;
    }

    final snapshot = await accountServer.updateSnapshotByTraceId(
      traceId: snapshotTraceId,
    );

    Toast.dismiss();
    await showTransferDialog(context, snapshot.snapshotId);
    return true;
  } catch (error) {
    e('get snapshot by traceId: $error');
    showToastFailed(error);
    return false;
  }
}

Future<bool> _selectConversation(
  Uri uri,
  BuildContext context,
  String conversationId, {
  required ProviderContainer container,
  required AccountServer? accountServer,
}) async {
  final userId = uri.queryParameters['user'];
  if (userId != null && userId.trim().isNotEmpty) {
    if (accountServer == null) {
      showToastFailed(null);
      return false;
    }
    showToastLoading();
    await accountServer.refreshUsers([userId]);
    Toast.dismiss();

    if (conversationId !=
        generateConversationId(accountServer.userId, userId)) {
      showToastFailed(null);
      return false;
    } else {
      await ConversationStateNotifier.selectUser(container, context, userId);
      return true;
    }
  }

  await ConversationStateNotifier.selectConversation(
    container,
    context,
    conversationId,
    sync: true,
    checkCurrentUserExist: true,
  );
  return true;
}

extension MixinUriExt on Uri {
  bool get isSendToUser => !userOfSend.isNullOrBlank();

  bool get isHttpsSendUrl => _isTypeHost(MixinSchemeHost.send);

  bool get isMixinActionUrl =>
      isMixin &&
      pathSegments.isNotEmpty &&
      MixinSchemeHost.values.any((e) => e.name == pathSegments.first);
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

  bool get isSend =>
      _isTypeScheme(MixinSchemeHost.send) || _isTypeHost(MixinSchemeHost.send);

  bool get isPay => _isTypeHost(MixinSchemeHost.pay);

  bool get isMultisigs => _isTypeHost(MixinSchemeHost.multisigs);

  bool get isSwap =>
      _isTypeHost(MixinSchemeHost.swap) || _isTypeScheme(MixinSchemeHost.swap);

  bool get isMarkets =>
      _isTypeHost(MixinSchemeHost.markets) ||
      _isTypeScheme(MixinSchemeHost.markets);

  bool get isMembership => _isTypeHost(MixinSchemeHost.membership);

  String? get startTextOfConversation {
    if (!isMixin) return null;
    return queryParameters['start'];
  }

  String? get userOfSend {
    if (!isSend) {
      return null;
    }
    return queryParameters['user'];
  }

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
