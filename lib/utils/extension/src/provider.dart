part of '../extension.dart';

extension ProviderExtension on BuildContext {
  MultiAuthChangeNotifier get multiAuthChangeNotifier =>
      providerContainer.read(multiAuthNotifierProvider);
  AuthState? get auth => providerContainer.read(authProvider);
  Account? get account => providerContainer.read(authAccountProvider);

  SettingCubit get settingCubit => read<SettingCubit>();

  AccountServer get accountServer => read<AccountServer>();

  AudioMessagePlayService get audioMessageService =>
      read<AudioMessagePlayService>();

  Database get database => accountServer.database;

  Localization get l10n => Localization.of(this);

  BrightnessThemeData get theme => BrightnessData.themeOf(this);

  double get brightnessValue => BrightnessData.of(this);

  Brightness get brightness =>
      watch<SettingCubit>().brightness ?? MediaQuery.platformBrightnessOf(this);

  Color dynamicColor(
    Color color, {
    Color? darkColor,
  }) =>
      BrightnessData.dynamicColor(this, color, darkColor: darkColor);

  ProviderContainer get providerContainer => ProviderScope.containerOf(this);
}
