import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';
import '../../utils/file.dart';
import '../../utils/hook.dart';
import '../../utils/system/package_info.dart';
import '../../utils/uri_utils.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../../widgets/high_light_text.dart';

class AboutPage extends HookConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ref = useRef<(DateTime, int)?>(null);

    final debugMode = useState(false);

    final info = useMemoizedFuture(getPackageInfo, null).data;

    void onTap() {
      if (debugMode.value) return;

      final value = ref.value;
      if (value == null) {
        ref.value = (DateTime.now(), 1);
      } else {
        final now = DateTime.now();
        final (last, count) = value;
        if (now.difference(last) < 1.seconds) {
          ref.value = (now, count + 1);
        } else {
          ref.value = (now, 1);
        }
      }

      if ((ref.value?.$2 ?? 0) > 6) {
        debugMode.value = true;
      }
    }

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
              GestureDetector(
                onTap: onTap,
                child: Animate(
                  effects: [
                    FadeEffect(duration: 1000.ms),
                    ScaleEffect(duration: 1000.ms)
                  ],
                  child: Text(
                    context.l10n.mixinMessengerDesktop,
                    style: TextStyle(
                      color: context.theme.text,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),

              // SignalDatabase.get
              const SizedBox(height: 8),
              CustomSelectableText(
                info?.versionAndBuildNumber ?? '',
                style: TextStyle(
                  color: context.theme.secondaryText,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 50),
              CellGroup(
                cellBackgroundColor: context.theme.settingCellBackgroundColor,
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
              if (debugMode.value)
                CellGroup(
                  child: CellItem(
                    title: Text(context.l10n.openLogDirectory),
                    onTap: () => openUri(
                      context,
                      mixinLogDirectory.uri.toString(),
                    ),
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
