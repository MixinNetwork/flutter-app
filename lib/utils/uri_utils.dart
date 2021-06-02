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
      return runFutureWithToast(context, () async {
        if (uri.pathSegments.isEmpty) throw ArgumentError();
        final userId = uri.pathSegments[0];

        final accountServer = context.read<AccountServer>();

        var user = await accountServer.database.userDao
            .userById(userId)
            .getSingleOrNull();

        if (user == null) {
          final list = await accountServer.refreshUsers([userId]);
          if (list?.isEmpty ?? true) {
            throw ToastError(Localization.of(context).userNotFound);
          }
          user = list![0];
        }

        await ConversationCubit.selectUser(context, userId);
      }());
    }
  }

  return launch(text);
}
