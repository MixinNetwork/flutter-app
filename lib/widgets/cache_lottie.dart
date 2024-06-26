// ignore_for_file: implementation_imports

import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart' as p;

import '../utils/cache_client.dart';
import '../utils/proxy.dart';
import 'cache_image.dart';

const String cacheLottieFolderName = 'cache_lottie';

/// Cache Lottie to local storage
@immutable
class CachedNetworkLottie extends NetworkLottie {
  CachedNetworkLottie(
    super.url, {
    super.headers,
    this.proxyConfig,
  }) : super(client: CacheClient(proxyConfig, cacheLottieFolderName));

  final ProxyConfig? proxyConfig;

  @override
  ImageProvider<Object>? getImageProvider(LottieImageAsset lottieImage) {
    final imageProvider = super.getImageProvider(lottieImage);
    if (imageProvider != null) {
      return imageProvider;
    }
    final imageUrl = Uri.base
        .resolve(url)
        .resolve(p.url.join(lottieImage.dirName, lottieImage.fileName));
    return MixinNetworkImageProvider(
      imageUrl.toString(),
      proxyConfig: proxyConfig,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedNetworkLottie &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;
}
