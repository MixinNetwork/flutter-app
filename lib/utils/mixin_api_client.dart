import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../constants/constants.dart';
import 'logger.dart';
import 'platform.dart';
import 'system/package_info.dart';

const tenSecond = Duration(seconds: 10);

const kRequestTimeStampKey = 'requestTimeStamp';

Future<String?> _userAgent = generateUserAgent();
Future<String?> _deviceId = getDeviceId();

Client createClient({
  required String userId,
  required String sessionId,
  required String privateKey,
  List<Interceptor> interceptors = const [],
  // Hive didn't support multi isolate.
  required bool loginByPhoneNumber,
}) =>
    Client(
      userId: userId,
      sessionId: sessionId,
      privateKey: privateKey,
      scp: loginByPhoneNumber ? scpFull : scp,
      dioOptions: BaseOptions(
        connectTimeout: tenSecond,
        receiveTimeout: tenSecond,
        sendTimeout: tenSecond,
        followRedirects: false,
        contentType: 'application/json; charset=utf-8',
      ),
      httpLogLevel: HttpLogLevel.none,
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

            final serverTime =
                int.tryParse(e.response?.headers.value('x-server-time') ?? '');
            if (serverTime != null) {
              serverTimeStamp =
                  DateTime.fromMicrosecondsSinceEpoch(serverTime ~/ 1000);
            }
            w('request error ${e.requestOptions.uri}: '
                'requestTimeStamp = ${requestTimeStamp?.outputFormat()} '
                'serverTimeStamp = ${serverTimeStamp?.outputFormat()} '
                'now = ${DateTime.now().outputFormat()}');
            handler.next(e);
          },
        ),
        InterceptorsWrapper(onRequest: (options, handler) async {
          options.headers['User-Agent'] = await _userAgent;
          options.headers['Mixin-Device-Id'] = await _deviceId;
          options.headers['Accept-Language'] = window.locale.languageCode;
          handler.next(options);
        }),
      ],
    );

final _formatter = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

extension _DateTimeFormatter on DateTime {
  String outputFormat() => _formatter.format(this);
}
