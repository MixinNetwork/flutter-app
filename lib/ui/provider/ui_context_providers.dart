import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/brightness_theme_data.dart';
import '../../generated/l10n.dart';
import '../../widgets/brightness_observer.dart';
import 'setting_provider.dart';

class _UiContextSnapshot {
  const _UiContextSnapshot({
    required this.context,
    required this.locale,
    required this.localization,
    required this.materialLocalizations,
    required this.mediaQueryData,
    required this.materialTheme,
    required this.brightnessValue,
  });

  final BuildContext context;
  final Locale locale;
  final Localization localization;
  final MaterialLocalizations materialLocalizations;
  final MediaQueryData mediaQueryData;
  final ThemeData materialTheme;
  final double brightnessValue;
}

class _UiContextRevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

_UiContextSnapshot? _uiContextSnapshot;

final _uiContextRevisionProvider =
    NotifierProvider<_UiContextRevisionNotifier, int>(
      _UiContextRevisionNotifier.new,
    );

_UiContextSnapshot _requireUiContextSnapshot(Ref ref) {
  ref.watch(_uiContextRevisionProvider);
  final snapshot = _uiContextSnapshot;
  if (snapshot == null) {
    throw StateError('UiContextScope is not ready');
  }
  return snapshot;
}

final buildContextProvider = Provider<BuildContext>(
  (ref) => _requireUiContextSnapshot(ref).context,
  dependencies: [_uiContextRevisionProvider],
);

final localeProvider = Provider<Locale>(
  (ref) => _requireUiContextSnapshot(ref).locale,
  dependencies: [_uiContextRevisionProvider],
);

final localizationProvider = Provider<Localization>(
  (ref) => _requireUiContextSnapshot(ref).localization,
  dependencies: [_uiContextRevisionProvider],
);

final materialLocalizationsProvider = Provider<MaterialLocalizations>(
  (ref) => _requireUiContextSnapshot(ref).materialLocalizations,
  dependencies: [_uiContextRevisionProvider],
);

final mediaQueryDataProvider = Provider<MediaQueryData>(
  (ref) => _requireUiContextSnapshot(ref).mediaQueryData,
  dependencies: [_uiContextRevisionProvider],
);

final materialThemeProvider = Provider<ThemeData>(
  (ref) => _requireUiContextSnapshot(ref).materialTheme,
  dependencies: [_uiContextRevisionProvider],
);

final brightnessValueProvider = Provider<double>(
  (ref) => _requireUiContextSnapshot(ref).brightnessValue,
  dependencies: [_uiContextRevisionProvider],
);

final brightnessThemeDataProvider = Provider<BrightnessThemeData>(
  (ref) => BrightnessThemeData.lerp(
    lightBrightnessThemeData,
    darkBrightnessThemeData,
    ref.watch(brightnessValueProvider),
  ),
  dependencies: [brightnessValueProvider],
);

final platformBrightnessProvider = Provider<Brightness>(
  (ref) => ref.watch(materialThemeProvider.select((value) => value.brightness)),
  dependencies: [materialThemeProvider],
);

final effectiveBrightnessProvider = Provider<Brightness>(
  (ref) {
    final forcedBrightness = ref.watch(
      settingProvider.select((value) => value.brightness),
    );
    return forcedBrightness ?? ref.watch(platformBrightnessProvider);
  },
  dependencies: [platformBrightnessProvider],
);

typedef DynamicColorArgs = ({Color color, Color? darkColor});

final dynamicColorProvider = Provider.family<Color, DynamicColorArgs>(
  (ref, args) {
    if (args.darkColor == null) return args.color;
    return Color.lerp(
      args.color,
      args.darkColor,
      ref.watch(brightnessValueProvider),
    )!;
  },
  dependencies: [brightnessValueProvider],
);

class UiContextScope extends HookConsumerWidget {
  const UiContextScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    final localization = Localization.of(context);
    final materialLocalizations = MaterialLocalizations.of(context);
    final mediaQueryData = MediaQuery.of(context);
    final materialTheme = Theme.of(context);
    final brightnessValue = BrightnessData.of(context);

    _uiContextSnapshot = _UiContextSnapshot(
      context: context,
      locale: locale,
      localization: localization,
      materialLocalizations: materialLocalizations,
      mediaQueryData: mediaQueryData,
      materialTheme: materialTheme,
      brightnessValue: brightnessValue,
    );

    useEffect(
      () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ref.read(_uiContextRevisionProvider.notifier).bump();
        });
        return null;
      },
      [
        locale,
        mediaQueryData.size,
        mediaQueryData.devicePixelRatio,
        mediaQueryData.textScaler,
        materialTheme.brightness,
        brightnessValue,
      ],
    );

    return child;
  }
}
