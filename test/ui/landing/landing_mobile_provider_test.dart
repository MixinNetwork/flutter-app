import 'package:flutter/widgets.dart';
import 'package:flutter_app/ui/landing/landing.dart';
import 'package:flutter_app/ui/provider/ui_context_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test(
    'landingMobileClientProvider derives headers from platform info',
    () async {
      final container = ProviderContainer(
        overrides: [
          localeProvider.overrideWith((ref) => const Locale('en')),
          landingMobilePlatformInfoProvider.overrideWith(
            (ref) async =>
                (userAgent: 'test-user-agent', deviceId: 'device-123'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final client = await container.read(landingMobileClientProvider.future);

      expect(client.dio.options.headers['Accept-Language'], 'en');
      expect(client.dio.options.headers['User-Agent'], 'test-user-agent');
      expect(client.dio.options.headers['Mixin-Device-Id'], 'device-123');
    },
  );
}
