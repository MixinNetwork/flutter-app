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

Client createClient({
  required String userId,
  required String sessionId,
  required String privateKey,
  // Hive didn't support multi isolate.
  required bool loginByPhoneNumber,
  List<Interceptor> interceptors = const [],
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
