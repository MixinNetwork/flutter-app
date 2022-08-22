// ignore_for_file: implementation_imports

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:extended_image/extended_image.dart';
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
  Future<LottieComposition> load() {
    final key = 'network-$url';
    return sharedLottieCache.putIfAbsent(key, () async {
      final resolved = Uri.base.resolve(url);

      final cacheKey = keyToMd5(url);

      var bytes = await _loadCache(cacheKey);

      if (bytes == null) {
        bytes = await network.loadHttp(resolved, headers: headers);
        await _saveCache(cacheKey, bytes);
      }

      final composition = await LottieComposition.fromBytes(
        bytes,
        name: p.url.basenameWithoutExtension(url),
        imageProviderFactory: imageProviderFactory,
      );
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
      imageProvider = MixinExtendedNetworkImageProvider(imageUrl.toString());
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

Future<Uint8List?> _loadCache(String key) async {
  final cacheDir = await _getCacheDir();
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
  final cacheDir = await _getCacheDir();
  if (!cacheDir.existsSync()) {
    await cacheDir.create(recursive: true);
  }
  final file = File(p.join(cacheDir.path, cacheKey));
  await file.writeAsBytes(bytes);
}
