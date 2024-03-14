part of '../extension.dart';

extension ProviderExtension on BuildContext {
  MultiAuthStateNotifier get multiAuthChangeNotifier =>
      providerContainer.read(multiAuthStateNotifierProvider.notifier);

  AuthState? get auth => providerContainer.read(authProvider);

  Account? get account => providerContainer.read(authAccountProvider);

  SettingChangeNotifier get settingChangeNotifier =>
      providerContainer.read(settingProvider);

  AccountServer get accountServer =>
      providerContainer.read(accountServerProvider.select((value) {
        if (!value.hasValue) throw Exception('AccountServerProvider not ready');
        return value.requireValue;
      }));

  AudioMessagePlayService get audioMessageService =>
      read<AudioMessagePlayService>();

  Database get database =>
      providerContainer.read(databaseProvider.select((value) {
        if (!value.hasValue) throw Exception('DatabaseProvider not ready');
        return value.requireValue;
      }));

  Localization get l10n => Localization.maybeOf(this) ?? Localization.current;

  BrightnessThemeData get theme => BrightnessData.themeOf(this);

  double get brightnessValue => BrightnessData.of(this);

  Brightness get brightness =>
      settingChangeNotifier.brightness ?? MediaQuery.platformBrightnessOf(this);

  Color dynamicColor(
    Color color, {
    Color? darkColor,
  }) =>
      BrightnessData.dynamicColor(this, color, darkColor: darkColor);

  ProviderContainer get providerContainer =>
      ProviderScope.containerOf(this, listen: false);
}
