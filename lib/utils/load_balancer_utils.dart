import 'dart:async';
import 'dart:convert' as convert;
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:isolate/isolate.dart';

LoadBalancer? loadBalancer;

Future<R> runLoadBalancer<R, P>(
        FutureOr<R> Function(P argument) function, P argument) =>
    loadBalancer != null
        ? loadBalancer!.run(function, argument)
        : compute(function, argument);

dynamic _jsonDecode(String json) => convert.jsonDecode(json);

Future<dynamic> jsonDecodeWithIsolate(String json) =>
    runLoadBalancer(_jsonDecode, json);

String _jsonEncode(Object? object) => convert.jsonEncode(object);

Future<String> jsonEncodeWithIsolate(Object? object) =>
    runLoadBalancer(_jsonEncode, object);

List<int> _utf8Encode(String input) => utf8.encode(input);

Future<List<int>> utf8EncodeWithIsolate(String input) =>
    runLoadBalancer(_utf8Encode, input);

String _utf8Decode(List<int> codeUnits) => utf8.decode(codeUnits);

Future<String> utf8DecodeWithIsolate(List<int> codeUnits) =>
    runLoadBalancer(_utf8Decode, codeUnits);

Future<String> base64EncodeWithIsolate(List<int> input) =>
    runLoadBalancer(base64Encode, input);

Future<Uint8List> base64DecodeWithIsolate(String encoded) =>
    runLoadBalancer(base64Decode, encoded);
