import 'dart:async';
import 'dart:convert' as convert;

import 'package:flutter/foundation.dart';
import 'package:isolate/load_balancer.dart';

class LoadBalancerUtils {
  static LoadBalancer? loadBalancer;

  static Future<R> runLoadBalancer<R, P>(
      FutureOr<R> Function(P argument) function, P argument) {
    return loadBalancer != null
        ? loadBalancer!.run(function, argument)
        : compute(function, argument);
  }

  static dynamic _jsonDecode(String json) => convert.jsonDecode(json);

  static Future<dynamic> jsonDecode(String json) =>
      runLoadBalancer(_jsonDecode, json);

  static String _jsonEncode(Object? object) => convert.jsonEncode(object);

  static Future<String> jsonEncode(Object? object)  => runLoadBalancer(_jsonEncode, object);

}
