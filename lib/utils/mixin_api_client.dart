import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../constants/constants.dart';
import 'logger.dart';
import 'platform.dart';
import 'property/setting_property.dart';
import 'proxy.dart';
import 'system/package_info.dart';

const tenSecond = Duration(seconds: 10);

const kRequestTimeStampKey = 'requestTimeStamp';

Future<String?> _userAgent = generateUserAgent();
Future<String?> _deviceId = getDeviceId();

class ApiUpgradeRequiredException implements Exception {
  const ApiUpgradeRequiredException();

  @override
  String toString() => 'API upgrade required';
}

class ApiUpgradeGate {
  bool _required = false;

  bool get isRequired => _required;

  bool require() {
    if (_required) return false;
    _required = true;
    return true;
  }

  DioException error(RequestOptions options) => DioException(
    requestOptions: options,
    type: DioExceptionType.cancel,
    error: const ApiUpgradeRequiredException(),
  );
}

Client createClient({
  required String userId,
  required String sessionId,
  required String privateKey,
  // Hive didn't support multi isolate.
  required bool loginByPhoneNumber,
  List<Interceptor> interceptors = const [],
  ApiUpgradeGate? upgradeGate,
  void Function()? onUpgradeRequired,
}) {
  final client = Client(
    userId: userId,
    sessionId: sessionId,
    sessionPrivateKey: Key.fromBase64(privateKey),
    scp: loginByPhoneNumber ? scpFull : scp,
    dioOptions: BaseOptions(
      connectTimeout: tenSecond,
      receiveTimeout: tenSecond,
      sendTimeout: tenSecond,
      followRedirects: false,
    ),
    // httpLogLevel: HttpLogLevel.none,
    jsonDecodeCallback: jsonDecode,
    interceptors: [
      if (upgradeGate != null)
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (upgradeGate.isRequired) {
              handler.reject(upgradeGate.error(options));
              return;
            }
            handler.next(options);
          },
          onError: (error, handler) {
            final mixinError = error is MixinApiError ? error.error : null;
            if (mixinError is MixinError && mixinError.code == oldVersion) {
              if (upgradeGate.require()) onUpgradeRequired?.call();
            }
            handler.next(error);
          },
        ),
      ...interceptors,
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.extra[kRequestTimeStampKey] = DateTime.now();
          handler.next(options);
        },
        onError: (e, handler) {
          final requestTimeStamp =
              e.requestOptions.extra[kRequestTimeStampKey] as DateTime?;
          DateTime? serverTimeStamp;

          final serverTime = int.tryParse(
            e.response?.headers.value('x-server-time') ?? '',
          );
          if (serverTime != null) {
            serverTimeStamp = DateTime.fromMicrosecondsSinceEpoch(
              serverTime ~/ 1000,
            );
          }
          final requestId = e.response?.headers.value('x-request-id') ?? '';
          w(
            'request error ${e.requestOptions.uri}, x-request-id = $requestId\n'
            'requestTimeStamp = ${requestTimeStamp?.outputFormat()} '
            'serverTimeStamp = ${serverTimeStamp?.outputFormat()} '
            'now = ${DateTime.now().outputFormat()}',
          );
          handler.next(e);
        },
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['User-Agent'] = await _userAgent;
          options.headers['Mixin-Device-Id'] = await _deviceId;
          options.headers['Accept-Language'] =
              PlatformDispatcher.instance.locale.languageCode;
          handler.next(options);
        },
      ),
    ],
  );
  return client;
}

final _formatter = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

extension _DateTimeFormatter on DateTime {
  String outputFormat() => _formatter.format(this);
}

extension ClientExt on Client {
  void configProxySetting(SettingPropertyStorage settingProperties) {
    var proxyConfig = settingProperties.activatedProxy;
    settingProperties.addListener(() {
      final config = settingProperties.activatedProxy;
      if (config != proxyConfig) {
        proxyConfig = config;
        dio.applyProxy(config);
      }
    });
    dio.applyProxy(proxyConfig);
  }
}
