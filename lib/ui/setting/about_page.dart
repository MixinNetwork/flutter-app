import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:moor_db_viewer/moor_db_viewer.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';

import '../../account/account_server.dart';
import '../../constants/resources.dart';
import '../../crypto/signal/signal_database.dart';
import '../../generated/l10n.dart';
import '../../utils/hook.dart';
import '../../utils/uri_utils.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/brightness_observer.dart';
import '../../widgets/cell.dart';
import '../../widgets/interacter_decorated_box.dart';

class AboutPage extends HookWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final info = useMemoizedFuture(PackageInfo.fromPlatform, null);
    final version = info == null ? '' : '${info.version}(${info.buildNumber})';
    return Scaffold(
      backgroundColor: BrightnessData.themeOf(context).background,
      appBar: MixinAppBar(
        title: Text(Localization.of(context).about),
        actions: const [],
      ),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Image.asset(
                Resources.assetsImagesAboutLogoPng,
                width: 60,
                height: 60,
              ),
              const SizedBox(height: 24),
              InteractableDecoratedBox(
                onTap: () {
                  if (kReleaseMode) return;

                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (context) => MoorDbViewer(SignalDatabase.get),
                    ),
                  );
                },
                child: Text(
                  Localization.of(context).mixinMessenger,
                  style: TextStyle(
                    color: BrightnessData.themeOf(context).text,
                    fontSize: 18,
                  ),
                ),
              ),
              // SignalDatabase.get
              const SizedBox(height: 8),
              InteractableDecoratedBox(
                onTap: () {
                  if (kReleaseMode) return;

                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (context) => MoorDbViewer(
                          context.read<AccountServer>().database.mixinDatabase),
                    ),
                  );
                },
                child: Text(
                  version,
                  style: TextStyle(
                    color: BrightnessData.themeOf(context).secondaryText,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              CellGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CellItem(
                      title: Text(Localization.of(context).followTwitter),
                      onTap: () => openUri(
                          context, 'https://twitter.com/MixinMessenger'),
                    ),
                    CellItem(
                      title: Text(Localization.of(context).followFacebook),
                      onTap: () =>
                          openUri(context, 'https://fb.com/MixinMessenger'),
                    ),
                    CellItem(
                      title: Text(Localization.of(context).helpCenter),
                      onTap: () => openUri(
                          context, 'https://mixinmessenger.zendesk.com'),
                    ),
                    CellItem(
                      title: Text(Localization.of(context).termsService),
                      onTap: () =>
                          openUri(context, 'https://mixin.one/pages/terms'),
                    ),
                    CellItem(
                      title: Text(Localization.of(context).privacyPolicy),
                      onTap: () =>
                          openUri(context, 'https://mixin.one/pages/privacy'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
