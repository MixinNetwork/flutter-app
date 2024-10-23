import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:dio_compatibility_layer/dio_compatibility_layer.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:rhttp/rhttp.dart' as rhttp;

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
        options.headers['Accept-Language'] =
            PlatformDispatcher.instance.locale.languageCode;
        handler.next(options);
      }),
    ],
  );
  client.dio.userCustomAdapter();
  return client;
}

extension DioNativeAdapter on Dio {
  void userCustomAdapter() {
    final client = rhttp.RhttpCompatibleClient.createSync(
        settings: const rhttp.ClientSettings(
            // dnsSettings: rhttp.DnsSettings.static(fallback: '8.8.8.8'),
            ));
    httpClientAdapter =
        _CustomHttpClientAdapterWrapper(ConversionLayerAdapter(client));
  }
}

class _CustomHttpClientAdapterWrapper implements HttpClientAdapter {
  _CustomHttpClientAdapterWrapper(this.client);

  final HttpClientAdapter client;

  @override
  void close({bool force = false}) {
    client.close(force: force);
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    try {
      final resp = await client.fetch(options, requestStream, cancelFuture);
      return resp;
    } on rhttp.RhttpWrappedClientException catch (error, stackTrace) {
      // RhttpException.request can not send to other isolate by SendPort
      Error.throwWithStackTrace(
          http.ClientException(error.message, error.uri), stackTrace);
    }
  }
}

final _formatter = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

extension _DateTimeFormatter on DateTime {
  String outputFormat() => _formatter.format(this);
}
