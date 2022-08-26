import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_app/utils/platform.dart';
import 'package:flutter_app/utils/system/package_info.dart';
import 'package:intl/intl.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../constants/constants.dart';
import 'logger.dart';

final tenSecond = const Duration(seconds: 10).inMilliseconds;

const kRequestTimeStampKey = 'requestTimeStamp';

Client createClient({
  required String userId,
  required String sessionId,
  required String privateKey,
  List<Interceptor> interceptors = const [],
}) =>
    Client(
      userId: userId,
      sessionId: sessionId,
      privateKey: privateKey,
      scp: scp,
      dioOptions: BaseOptions(
        connectTimeout: tenSecond,
        receiveTimeout: tenSecond,
        sendTimeout: tenSecond,
        followRedirects: false,
      ),
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
          final deviceId = await getDeviceId();
          final userAgent = await generateUserAgent(await getPackageInfo());
          options.headers['User-Agent'] = userAgent;
          options.headers['Mixin-Device-Id'] = deviceId;
          options.headers['Accept-Language'] = window.locale.languageCode;
          handler.next(options);
        })
      ],
      httpLogLevel: HttpLogLevel.all,
    );

final _formatter = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

extension _DateTimeFormatter on DateTime {
  String outputFormat() => _formatter.format(this);
}
