import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/system/package_info.dart';
import '../../utils/uri_utils.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';

class AboutPage extends HookWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final info = useMemoizedFuture(getPackageInfo, null).data;
    return Scaffold(
      backgroundColor: context.theme.background,
      appBar: MixinAppBar(
        title: Text(context.l10n.about),
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
              Text(
                context.l10n.mixinMessengerDesktop,
                style: TextStyle(
                  color: context.theme.text,
                  fontSize: 18,
                ),
              ),
              // SignalDatabase.get
              const SizedBox(height: 8),
              SelectableText(
                info?.versionAndBuildNumber ?? '',
                style: TextStyle(
                  color: context.theme.secondaryText,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 50),
              CellGroup(
                cellBackgroundColor: context.dynamicColor(
                  Colors.white,
                  darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CellItem(
                      title: Text(context.l10n.followUsOnTwitter),
                      onTap: () => openUri(
                          context, 'https://twitter.com/MixinMessenger'),
                    ),
                    CellItem(
                      title: Text(context.l10n.followUsOnFacebook),
                      onTap: () =>
                          openUri(context, 'https://fb.com/MixinMessenger'),
                    ),
                    CellItem(
                      title: Text(context.l10n.helpCenter),
                      onTap: () => openUri(
                          context, 'https://mixinmessenger.zendesk.com'),
                    ),
                    CellItem(
                      title: Text(context.l10n.termsOfService),
                      onTap: () =>
                          openUri(context, 'https://mixin.one/pages/terms'),
                    ),
                    CellItem(
                      title: Text(context.l10n.privacyPolicy),
                      onTap: () =>
                          openUri(context, 'https://mixin.one/pages/privacy'),
                    ),
                    if (!Platform.isMacOS)
                      CellItem(
                        title: Text(context.l10n.checkNewVersion),
                        onTap: () => openCheckUpdate(context),
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

  void openCheckUpdate(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.linux) {
      openUri(context, 'https://mixin.one/messenger');
    } else if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      openUri(
          context, 'https://apps.apple.com/app/mixin-messenger/id1571128582');
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      openUri(context,
          'https://apps.microsoft.com/store/detail/mixin-desktop/9NQ6HF99B8NJ');
    }
  }
}
