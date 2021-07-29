part of '../extension.dart';

extension ProviderExtension on BuildContext {
  AccountServer get accountServer => read<AccountServer>();

  AccountServer get watchAccountServer => watch<AccountServer>();

  Database get database => accountServer.database;

  Localization get l10n => Localization.of(this);

  BrightnessThemeData get theme => BrightnessData.themeOf(this);

  double get brightnessValue => BrightnessData.of(this);
}
