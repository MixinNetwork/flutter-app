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
import '../../widgets/buttons.dart';
import '../../widgets/cell.dart';
import '../../widgets/high_light_text.dart';
import '../provider/ui_context_providers.dart';
import 'log_page.dart';

class AboutPage extends HookConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tapRef = useRef<(DateTime, int)?>(null);
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);

    final debugMode = useState(false);

    final info = useMemoizedFuture(getPackageInfo, null).data;

    void onTap() {
      if (debugMode.value) return;

      final value = tapRef.value;
      if (value == null) {
        tapRef.value = (DateTime.now(), 1);
      } else {
        final now = DateTime.now();
        final (last, count) = value;
        if (now.difference(last) < 1.seconds) {
          tapRef.value = (now, count + 1);
        } else {
          tapRef.value = (now, 1);
        }
      }

      if ((tapRef.value?.$2 ?? 0) > 6) {
        debugMode.value = true;
      }
    }

    return Scaffold(
      backgroundColor: theme.background,
      appBar: MixinAppBar(title: Text(l10n.about)),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              NTapGestureDetector(
                n: 5,
                child: Image.asset(
                  Resources.assetsImagesAboutLogoPng,
                  width: 60,
                  height: 60,
                ),
                onTap: () => showLogPage(context),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onTap,
                child: Animate(
                  effects: [
                    FadeEffect(duration: 1000.ms),
                    ScaleEffect(duration: 1000.ms),
                  ],
                  child: Text(
                    l10n.mixinMessengerDesktop,
                    style: TextStyle(color: theme.text, fontSize: 18),
                  ),
                ),
              ),

              // SignalDatabase.get
              const SizedBox(height: 8),
              CustomSelectableText(
                info?.versionAndBuildNumber ?? '',
                style: TextStyle(
                  color: theme.secondaryText,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 50),
              CellGroup(
                cellBackgroundColor: theme.settingCellBackgroundColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CellItem(
                      title: Text(l10n.followUsOnX),
                      onTap: () => openUri(
                        context,
                        'https://x.com/MixinMessenger',
                        container: ref.container,
                      ),
                    ),
                    CellItem(
                      title: Text(l10n.followUsOnFacebook),
                      onTap: () => openUri(
                        context,
                        'https://fb.com/MixinMessenger',
                        container: ref.container,
                      ),
                    ),
                    CellItem(
                      title: Text(l10n.helpCenter),
                      onTap: () => openUri(
                        context,
                        'https://support.mixin.one',
                        container: ref.container,
                      ),
                    ),
                    CellItem(
                      title: Text(l10n.termsOfService),
                      onTap: () => openUri(
                        context,
                        'https://mixin.one/pages/terms',
                        container: ref.container,
                      ),
                    ),
                    CellItem(
                      title: Text(l10n.privacyPolicy),
                      onTap: () => openUri(
                        context,
                        'https://mixin.one/pages/privacy',
                        container: ref.container,
                      ),
                    ),
                    if (!Platform.isMacOS)
                      CellItem(
                        title: Text(l10n.checkNewVersion),
                        onTap: () => openCheckUpdate(context, ref),
                      ),
                  ],
                ),
              ),
              if (debugMode.value)
                CellGroup(
                  child: CellItem(
                    title: Text(l10n.openLogDirectory),
                    onTap: () => openUri(
                      context,
                      mixinLogDirectory.uri.toString(),
                      container: ref.container,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void openCheckUpdate(BuildContext context, WidgetRef ref) {
    if (defaultTargetPlatform == TargetPlatform.linux) {
      openUri(context, 'https://mixin.one/messenger', container: ref.container);
    } else if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      openUri(
        context,
        'https://apps.apple.com/app/mixin-messenger/id1571128582',
        container: ref.container,
      );
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      openUri(
        context,
        'https://apps.microsoft.com/store/detail/mixin-desktop/9NQ6HF99B8NJ',
        container: ref.container,
      );
    }
  }
}
