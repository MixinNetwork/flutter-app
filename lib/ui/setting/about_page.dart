import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/uri_utils.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';

class AboutPage extends HookWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final info = useMemoizedFuture(PackageInfo.fromPlatform, null).data;
    final version = info == null ? '' : '${info.version}(${info.buildNumber})';
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
                context.l10n.mixinMessenger,
                style: TextStyle(
                  color: context.theme.text,
                  fontSize: 18,
                ),
              ),
              // SignalDatabase.get
              const SizedBox(height: 8),
              Text(
                version,
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
                      title: Text(context.l10n.followTwitter),
                      onTap: () => openUri(
                          context, 'https://twitter.com/MixinMessenger'),
                    ),
                    CellItem(
                      title: Text(context.l10n.followFacebook),
                      onTap: () =>
                          openUri(context, 'https://fb.com/MixinMessenger'),
                    ),
                    CellItem(
                      title: Text(context.l10n.helpCenter),
                      onTap: () => openUri(
                          context, 'https://mixinmessenger.zendesk.com'),
                    ),
                    CellItem(
                      title: Text(context.l10n.termsService),
                      onTap: () =>
                          openUri(context, 'https://mixin.one/pages/terms'),
                    ),
                    CellItem(
                      title: Text(context.l10n.privacyPolicy),
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
