import 'package:envied/envied.dart';
import 'package:flutter/foundation.dart';

part 'env.g.dart';

class Env {
  static const String sentryDsn = kReleaseMode
      ? ProductEnv._sentryDsn ?? ''
      : '';
}

@Envied(path: '.env', allowOptionalFields: true)
abstract class ProductEnv {
  @EnviedField(varName: 'SENTRY_DSN')
  static const String? _sentryDsn = _ProductEnv._sentryDsn;
}
