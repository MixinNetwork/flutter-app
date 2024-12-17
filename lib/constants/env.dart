import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', allowOptionalFields: true)
abstract class Env {
  @EnviedField(varName: 'SENTRY_DSN')
  static const String? _sentryDsn = _Env._sentryDsn;

  static const String sentryDsn = _sentryDsn ?? '';
}
