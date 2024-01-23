// ignore_for_file: implementation_imports

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';
import 'package:lottie/src/providers/load_image.dart';
import 'package:lottie/src/providers/lottie_provider.dart';
import 'package:lottie/src/providers/provider_io.dart'
    if (dart.library.html) 'package:lottie/src/providers/provider_web.dart'
    as network;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'cache_image.dart';

/// Cache Lottie to local storage
@immutable
class CachedNetworkLottie extends LottieProvider {
  CachedNetworkLottie(this.url, {this.headers});

  final String url;
  final Map<String, String>? headers;

  @override
  Future<LottieComposition> load({BuildContext? context}) {
    final key = 'network-$url';
    return sharedLottieCache.putIfAbsent(key, () async {
      final resolved = Uri.base.resolve(url);
      final cacheDir = await _getCacheDir();
      final composition = await compute(
          _downloadAndParse, (resolved, headers, decoder, cacheDir.path));

      for (final image in composition.images.values) {
        image.loadedImage ??= await _loadImage(resolved, composition, image);
      }
      return composition;
    });
  }

  Future<ui.Image?> _loadImage(Uri jsonUri, LottieComposition composition,
      LottieImageAsset lottieImage) {
    var imageProvider = getImageProvider(lottieImage);

    if (imageProvider == null) {
      final imageUrl = jsonUri
          .resolve(p.url.join(lottieImage.dirName, lottieImage.fileName));
      imageProvider = MixinNetworkImageProvider(imageUrl.toString());
    }

    return loadImage(composition, lottieImage, imageProvider);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedNetworkLottie &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'CachedNetworkLottie{url: $url}';
}

Future<Directory> _getCacheDir() async {
  final appTempDirectory = await getTemporaryDirectory();
  return Directory(p.join(appTempDirectory.path, 'mixin', 'lottie_cache'));
}

Future<Uint8List?> _loadCache(String key, String cacheDirPath) async {
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

Future<LottieComposition> _downloadAndParse(
    (Uri, Map<String, String>?, LottieDecoder?, String) args) async {
  final (uri, headers, decoder, cacheDir) = args;

  final cacheKey = keyToMd5(uri.toString());

  var bytes = await _loadCache(cacheKey, cacheDir);

  if (bytes == null) {
    bytes = await network.loadHttp(uri, headers: headers);
    await _saveCache(cacheKey, cacheDir, bytes);
  }

  return LottieComposition.fromBytes(bytes, decoder: decoder);
}

Future<void> _saveCache(
    String cacheKey, String cacheDirPath, Uint8List bytes) async {
  final cacheDir = Directory(cacheDirPath);
  if (!cacheDir.existsSync()) {
    await cacheDir.create(recursive: true);
  }
  final file = File(p.join(cacheDir.path, cacheKey));
  await file.writeAsBytes(bytes);
}
