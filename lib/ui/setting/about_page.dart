import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/utils/hook.dart';
import 'package:flutter_app/utils/uri_utils.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/widgets/cell.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:package_info/package_info.dart';

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
        actions: [],
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
                Localization.of(context).mixinMessenger,
                style: TextStyle(
                  color: BrightnessData.themeOf(context).text,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                version,
                style: TextStyle(
                  color: BrightnessData.themeOf(context).secondaryText,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 50),
              CellGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CellItem(
                      title: Text(Localization.of(context).followTwitter),
                      onTap: () =>
                          openUri('https://twitter.com/MixinMessenger'),
                    ),
                    CellItem(
                      title: Text(Localization.of(context).followFacebook),
                      onTap: () => openUri('https://fb.com/MixinMessenger'),
                    ),
                    CellItem(
                      title: Text(Localization.of(context).helpCenter),
                      onTap: () =>
                          openUri('https://mixinmessenger.zendesk.com'),
                    ),
                    CellItem(
                      title: Text(Localization.of(context).termsService),
                      onTap: () => openUri('https://mixin.one/pages/terms'),
                    ),
                    CellItem(
                      title: Text(Localization.of(context).privacyPolicy),
                      onTap: () => openUri('https://mixin.one/pages/privacy'),
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
