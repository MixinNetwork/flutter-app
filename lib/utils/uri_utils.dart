import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../generated/l10n.dart';
import '../account/account_server.dart';
import '../constants/constants.dart';
import '../ui/home/bloc/conversation_cubit.dart';
import '../widgets/toast.dart';

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

      final accountServer = context.read<AccountServer>();

      var user = await accountServer.database.userDao
          .userById(userId)
          .getSingleOrNull();

      if (user == null) {
        // Because request network need long time.
        showToastLoading(context);
        final list = await accountServer.refreshUsers([userId]);
        if (list?.isEmpty ?? true) {
          await showToastFailed(
              context, ToastError(Localization.of(context).userNotFound));
          return false;
        }
        user = list![0];
      }

      Toast.dismiss();

      await ConversationCubit.selectUser(context, userId, user: user);
      return true;
    }
  }

  return launch(text);
}
