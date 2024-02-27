// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:lottie/lottie.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/proxy.dart';
import 'cache_image.dart';

/// Cache Lottie to local storage
@immutable
class CachedNetworkLottie extends NetworkLottie {
  CachedNetworkLottie(
    super.url, {
    super.headers,
    this.proxyConfig,
  }) : super(client: _LottieClient(proxyConfig));

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

class _LottieClient extends BaseClient {
  _LottieClient(ProxyConfig? proxyConfig) {
    if (proxyConfig != null) {
      _client = IOClient(HttpClient()..setProxy(proxyConfig));
    } else {
      _client = Client();
    }
  }

  late Client _client;

  @override
  Future<Response> get(Uri url, {Map<String, String>? headers}) async {
    final cacheKey = keyToMd5(url.toString());

    final cache = await _loadCache(cacheKey);
    if (cache != null) {
      i('load response from cache: $url $cacheKey');
      return Response.bytes(cache, 200);
    }

    final response = await super.get(url, headers: headers);
    if (response.statusCode == 200) {
      i('save response(${response.statusCode}) to cache: $url $cacheKey');
      await _saveCache(cacheKey, response.bodyBytes);
    }
    return response;
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) => _client.send(request);
}

Future<Directory> _getCacheDir() async {
  final appTempDirectory = await getTemporaryDirectory();
  return Directory(p.join(appTempDirectory.path, 'mixin', 'lottie_cache'));
}

Future<Uint8List?> _loadCache(String key) async {
  final cacheDirPath = (await _getCacheDir()).path;
  final cacheDir = Directory(cacheDirPath);
  Uint8List? data;
  if (cacheDir.existsSync()) {
    final file = File(p.join(cacheDir.path, key));
    if (file.existsSync()) {
      data = await file.readAsBytes();
    }
  }
  return data;
}

Future<void> _saveCache(String cacheKey, Uint8List bytes) async {
  final cacheDirPath = (await _getCacheDir()).path;
  final cacheDir = Directory(cacheDirPath);
  if (!cacheDir.existsSync()) {
    await cacheDir.create(recursive: true);
  }
  final file = File(p.join(cacheDir.path, cacheKey));
  await file.writeAsBytes(bytes);
}
