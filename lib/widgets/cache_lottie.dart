// ignore_for_file: implementation_imports

import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

import '../utils/cache_client.dart';
import '../utils/proxy.dart';

const String cacheLottieFolderName = 'cache_lottie';

/// Cache Lottie to local storage
@immutable
class CachedNetworkLottie extends NetworkLottie {
  CachedNetworkLottie(super.url, {super.headers, this.proxyConfig})
    : super(client: CacheClient(proxyConfig, cacheLottieFolderName));

  final ProxyConfig? proxyConfig;
}
