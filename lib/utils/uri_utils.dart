import 'package:flutter/widgets.dart';
import 'package:flutter_app/widgets/user/user_dialog.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/constants.dart';

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
      await showUserDialog(context, userId);
      return true;
    }
  }

  return launch(uri.toString());
}
