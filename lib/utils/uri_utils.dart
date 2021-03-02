import 'package:flutter_app/constants/constants.dart';
import 'package:url_launcher/url_launcher.dart';

import 'enum_to_string.dart';

Future<bool> openUri(String text) {
  final uri = Uri.parse(text);
  if(uri.scheme.isEmpty) return Future.value(false);

  if (uri.isScheme(mixinScheme)) {
    final host = EnumToString.fromString(MixinSchemeHost.values, uri.host);

    final protocolUrl = mixinProtocolUrls[host];
    if (protocolUrl != null) {
      return launch('$protocolUrl${uri.path}');
    } else if (MixinSchemeHost.users == host) {
      // TODO user profile page
      return launch(text);
    }
  }

  return launch(text);
}
