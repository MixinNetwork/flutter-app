import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../widgets/mixin_image.dart';
import 'mixin_api_client.dart';
import 'proxy.dart';

class CacheClient extends BaseClient {
  CacheClient(ProxyConfig? proxyConfig, this.folderName) {
    if (proxyConfig != null) {
      _client = IOClient(HttpClient()..setProxy(proxyConfig));
    } else {
      _client = globalRHttpClient;
    }
  }

  late Client _client;
  final String folderName;

  String get logTag => '[CacheClient][folderName: $folderName]';

  @override
  Future<Response> get(Uri url, {Map<String, String>? headers}) async {
    final cacheKey = keyToMd5(url.toString());

    final cache = await _loadCache(cacheKey);
    if (cache != null) {
      i('$logTag: load response from cache: $url $cacheKey');
      return Response.bytes(cache, 200);
    }

    final response = await super.get(url, headers: headers);
    if (response.statusCode == 200) {
      i('$logTag: save response(${response.statusCode}) to cache: $url $cacheKey');
      await _saveCache(cacheKey, response.bodyBytes);
    }
    return response;
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) => _client.send(request);

  Future<Directory> _getCacheDir() async {
    final appTempDirectory = await getTemporaryDirectory();
    return Directory(p.join(appTempDirectory.path, folderName));
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
}
