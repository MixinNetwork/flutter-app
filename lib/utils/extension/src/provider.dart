part of '../extension.dart';

extension ProviderExtension on BuildContext {
  MultiAuthCubit get multiAuthCubit => read<MultiAuthCubit>();

  MultiAuthState get multiAuthState => multiAuthCubit.state;

  AccountServer get accountServer => read<AccountServer>();

  Database get database => accountServer.database;

  Localization get l10n => Localization.of(this);

  BrightnessThemeData get theme => BrightnessData.themeOf(this);

  double get brightnessValue => BrightnessData.of(this);
}
