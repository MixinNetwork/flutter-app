part of '../extension.dart';

extension ProviderExtension on BuildContext {
  MultiAuthCubit get multiAuthCubit => read<MultiAuthCubit>();

  MultiAuthState get multiAuthState => multiAuthCubit.state;

  SettingCubit get settingCubit => read<SettingCubit>();

  AccountServer get accountServer => read<AccountServer>();

  AudioMessagePlayService get audioMessageService =>
      read<AudioMessagePlayService>();

  Database get database => accountServer.database;

  Localization get l10n => Localization.of(this);

  BrightnessThemeData get theme => BrightnessData.themeOf(this);

  double get brightnessValue => BrightnessData.of(this);

  Color dynamicColor(
    Color color, {
    Color? darkColor,
  }) =>
      BrightnessData.dynamicColor(this, color, darkColor: darkColor);
}
