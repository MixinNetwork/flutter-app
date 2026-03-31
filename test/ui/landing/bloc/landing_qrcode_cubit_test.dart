import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_app/ui/landing/bloc/landing_cubit.dart';
import 'package:flutter_app/ui/landing/bloc/landing_state.dart';
import 'package:flutter_app/ui/provider/multi_auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

void main() {
  group('LandingQrCodeCubit', () {
    test('older auth url request must not override newer qr code', () async {
      final notifier = MultiAuthStateNotifier(const MultiAuthState());
      final first = Completer<MixinResponse<ProvisioningId>>();
      final second = Completer<MixinResponse<ProvisioningId>>();
      var requestCount = 0;

      final cubit = LandingQrCodeCubit(
        notifier,
        const Locale('en'),
        autoStart: false,
        provisioningIdLoader: () {
          requestCount += 1;
          return requestCount == 1 ? first.future : second.future;
        },
        pollingStreamFactory: () => const Stream<int>.empty(),
      );

      unawaited(cubit.requestAuthUrl());
      unawaited(cubit.requestAuthUrl());

      second.complete(
        MixinResponse(ProvisioningId(deviceId: 'new', expiredAt: null)),
      );
      await pumpEventQueue();

      first.complete(
        MixinResponse(ProvisioningId(deviceId: 'old', expiredAt: null)),
      );
      await pumpEventQueue();

      expect(cubit.state.status, LandingStatus.ready);
      expect(cubit.state.authUrl, contains('id=new'));
      expect(cubit.state.authUrl, isNot(contains('id=old')));

      await cubit.close();
    });

    test('expiration automatically refreshes qr code once', () async {
      final notifier = MultiAuthStateNotifier(const MultiAuthState());
      final pollingStreams = [
        StreamController<int>(),
        StreamController<int>(),
      ];
      var pollingIndex = 0;
      var requestCount = 0;

      final cubit = LandingQrCodeCubit(
        notifier,
        const Locale('en'),
        autoStart: false,
        expirationTickLimit: 0,
        provisioningIdLoader: () async {
          requestCount += 1;
          return MixinResponse(
            ProvisioningId(
              deviceId: requestCount == 1 ? 'first' : 'second',
              expiredAt: null,
            ),
          );
        },
        provisioningLoader: (_) async => MixinResponse(
          Provisioning(
            deviceId: 'device',
            expiredAt: null,
            secret: '',
            platform: null,
            provisioningCode: null,
            sessionId: null,
            userId: null,
          ),
        ),
        pollingStreamFactory: () => pollingStreams[pollingIndex++].stream,
      );

      await cubit.requestAuthUrl();
      pollingStreams[0].add(0);
      await pumpEventQueue();
      pollingStreams[0].add(1);
      await pumpEventQueue();

      expect(requestCount, 2);
      expect(cubit.state.status, LandingStatus.ready);
      expect(cubit.state.authUrl, contains('id=second'));

      await cubit.close();
      for (final controller in pollingStreams) {
        await controller.close();
      }
    });

    test('failed auto refresh moves qr code to retry state', () async {
      final notifier = MultiAuthStateNotifier(const MultiAuthState());
      final pollingController = StreamController<int>();
      var requestCount = 0;

      final cubit = LandingQrCodeCubit(
        notifier,
        const Locale('en'),
        autoStart: false,
        expirationTickLimit: 0,
        provisioningIdLoader: () async {
          requestCount += 1;
          if (requestCount == 1) {
            return MixinResponse(
              ProvisioningId(deviceId: 'first', expiredAt: null),
            );
          }
          throw Exception('refresh failed');
        },
        provisioningLoader: (_) async => MixinResponse(
          Provisioning(
            deviceId: 'device',
            expiredAt: null,
            secret: '',
            platform: null,
            provisioningCode: null,
            sessionId: null,
            userId: null,
          ),
        ),
        pollingStreamFactory: () => pollingController.stream,
      );

      await cubit.requestAuthUrl();
      pollingController.add(1);
      await pumpEventQueue();

      expect(cubit.state.status, LandingStatus.needReload);
      expect(cubit.state.authUrl, contains('id=first'));

      await cubit.close();
      await pollingController.close();
    });

    test('polling failure threshold surfaces retry state', () async {
      final notifier = MultiAuthStateNotifier(const MultiAuthState());
      final pollingController = StreamController<int>();

      final cubit = LandingQrCodeCubit(
        notifier,
        const Locale('en'),
        autoStart: false,
        pollingFailureLimit: 1,
        provisioningIdLoader: () async =>
            MixinResponse(ProvisioningId(deviceId: 'first', expiredAt: null)),
        provisioningLoader: (_) async => throw Exception('network'),
        pollingStreamFactory: () => pollingController.stream,
        expiredMessageBuilder: () => 'expired',
      );

      await cubit.requestAuthUrl();
      pollingController.add(0);
      await pumpEventQueue();

      expect(cubit.state.status, LandingStatus.needReload);

      await cubit.close();
      await pollingController.close();
    });
  });
}
