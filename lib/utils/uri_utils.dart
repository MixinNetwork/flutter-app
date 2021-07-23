import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../account/account_server.dart';
import '../constants/constants.dart';
import '../generated/l10n.dart';
import '../widgets/toast.dart';
import '../widgets/user/user_dialog.dart';

Future<bool> openUri(BuildContext context, String text) async {
  final uri = Uri.parse(text);
  if (uri.scheme.isEmpty) return Future.value(false);

  if (uri.isScheme(mixinScheme)) {
    final host = EnumToString.fromString(MixinSchemeHost.values, uri.host);

    final protocolUrl = mixinProtocolUrls[host];
    if (protocolUrl != null) {
      return launch('$protocolUrl${uri.path}');
    } else if (MixinSchemeHost.users == host) {
      if (uri.pathSegments.isEmpty) return false;
      final userId = uri.pathSegments[0];

      showToastLoading(context);
      final result = await context.read<AccountServer>().refreshUsers([userId]);
      if (result?.isEmpty ?? true) {
        await showToastFailed(
            context, ToastError(Localization.of(context).userNotFound));
      } else {
        Toast.dismiss();
        await showUserDialog(context, userId);
      }

      return true;
    }
  }

  return launch(uri.toString());
}
