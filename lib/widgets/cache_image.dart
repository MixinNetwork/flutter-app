import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http_client_helper/http_client_helper.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/extension/extension.dart';
import '../utils/hook.dart';
import '../utils/logger.dart';
import '../utils/proxy.dart';

typedef PlaceholderWidgetBuilder = Widget Function();

// min frameDuration
// see also:
// https://nullsleep.tumblr.com/post/16524517190/animated-gif-minimum-frame-delay-browser
// https://qiita.com/razokulover/items/34962844e314bb4bfd04
const _defaultFrameDuration = Duration(milliseconds: 100);
const _minFrameDuration = Duration(milliseconds: 20);

const String cacheImageFolderName = 'cacheimage';

final _sharedHttpClient = HttpClient()..autoUncompress = false;

HttpClient get _httpClient {
  var client = _sharedHttpClient;
  assert(() {
    if (debugNetworkImageHttpClientProvider != null) {
      client = debugNetworkImageHttpClientProvider!();
    }
    return true;
  }());
  return client;
}

ProxyConfig? _imageClientProxyConfig;

Future<ui.ImmutableBuffer?> _loadCacheBuffer(
  ImageProvider<Object> provider,
  ProxyConfig? proxyConfig,
) async {
  final key = _getKeyImage(provider);
  final md5Key = key != null ? keyToMd5(key) : null;

  final _cacheImagesDirectory = Directory(
      join((await getTemporaryDirectory()).path, cacheImageFolderName));
  ui.ImmutableBuffer? data;

  if (_cacheImagesDirectory.existsSync() && md5Key != null) {
    try {
      data = await ui.ImmutableBuffer.fromFilePath(
        join(_cacheImagesDirectory.path, md5Key),
      );
    } catch (_) {
      // Throws an Exception if the asset does not exist.
    }
  } else {
    await _cacheImagesDirectory.create();
  }

  if (data == null) {
    final (buffer, bytes) = await _loadBuffer(provider, proxyConfig);
    data = buffer;
    if (bytes != null) {
      await File(join(_cacheImagesDirectory.path, md5Key)).writeAsBytes(bytes);
    }
  }

  return data;
}

String? _getKeyImage(Object provider) =>
    provider is NetworkImage ? provider.url : null;

Future<(ui.ImmutableBuffer?, Uint8List?)> _loadBuffer(
  ImageProvider<Object> provider,
  ProxyConfig? proxyConfig,
) async {
  if (provider is NetworkImage) {
    final resolved = Uri.base.resolve(provider.url);
    final Uint8List bytes;

    final response = await _tryGetResponse(resolved, proxyConfig);
    if (response == null || response.statusCode != HttpStatus.ok) {
      return (null, null);
    }

    bytes = await consolidateHttpClientResponseBytes(response);

    if (bytes.lengthInBytes == 0) {
      throw StateError('NetworkImage is an empty file: $resolved');
    }
    return (await ui.ImmutableBuffer.fromUint8List(bytes), bytes);
  } else if (provider is AssetImage) {
    return (await ui.ImmutableBuffer.fromAsset(provider.assetName), null);
  } else if (provider is FileImage) {
    return (await ui.ImmutableBuffer.fromFilePath(provider.file.path), null);
  } else if (provider is MemoryImage) {
    return (
      await ui.ImmutableBuffer.fromUint8List(provider.bytes),
      provider.bytes
    );
  }
  return (null, null);
}

Future<HttpClientResponse?> _tryGetResponse(
  Uri resolved,
  ProxyConfig? proxy,
) async {
  if (proxy != _imageClientProxyConfig) {
    _httpClient.setProxy(proxy);
    _imageClientProxyConfig = proxy;
  }
  final request = await _httpClient.getUrl(resolved);
  final response = await request.close();

  return response;
}

Future<Uint8List?> _loadCacheBytes(
  Object provider,
  ProxyConfig? proxyConfig,
) async {
  final key = _getKeyImage(provider);
  final md5Key = key != null ? keyToMd5(key) : null;

  final _cacheImagesDirectory = Directory(
      join((await getTemporaryDirectory()).path, cacheImageFolderName));
  Uint8List? data;

  if (_cacheImagesDirectory.existsSync() && md5Key != null) {
    try {
      data = await File(join(_cacheImagesDirectory.path, md5Key)).readAsBytes();
    } catch (_) {
      // Throws an Exception if the asset does not exist.
    }
  } else {
    await _cacheImagesDirectory.create();
  }

  if (data == null) {
    data = await _loadBytes(provider, proxyConfig);
    if (data != null) {
      await File(join(_cacheImagesDirectory.path, md5Key)).writeAsBytes(data);
    }
  }

  return data;
}

Future<Uint8List?> _loadBytes(
  Object provider,
  ProxyConfig? proxyConfig,
) async {
  if (provider is NetworkLottie) {
    final resolved = Uri.base.resolve(provider.url);
    final response = await _tryGetResponse(resolved, proxyConfig);
    if (response == null || response.statusCode != HttpStatus.ok) {
      return null;
    }
    final bytes = await consolidateHttpClientResponseBytes(response);
    if (bytes.lengthInBytes == 0) {
      throw StateError('NetworkImage is an empty file: $resolved');
    }
    return bytes;
  } else if (provider is NetworkImage) {
    final resolved = Uri.base.resolve(provider.url);
    final response = await _tryGetResponse(resolved, proxyConfig);
    if (response == null || response.statusCode != HttpStatus.ok) {
      return null;
    }

    final bytes = await consolidateHttpClientResponseBytes(response);
    if (bytes.lengthInBytes == 0) {
      throw StateError('NetworkImage is an empty file: $resolved');
    }
    return bytes;
  } else if (provider is AssetImage) {
    final data = await provider.bundle?.load(provider.assetName);
    return data?.buffer.asUint8List();
  } else if (provider is FileImage) {
    return provider.file.readAsBytes();
  } else if (provider is MemoryImage) {
    return provider.bytes;
  }
  return null;
}

/// download image from network to cache. return the cache image file.
/// [url] is the image url.
Future<Uint8List?> downloadImage(String url) async =>
    _loadCacheBytes(NetworkImage(url), null);

/// get md5 from key
String keyToMd5(String key) => md5.convert(utf8.encode(key)).toString();

class MixinImage extends HookWidget {
  const MixinImage({
    required this.image,
    super.key,
    this.placeholder,
    this.errorBuilder,
    this.width,
    this.height,
    this.cancelToken,
    this.fit,
    this.isAntiAlias = false,
    this.controller,
  });

  MixinImage.network(
    String url, {
    super.key,
    this.placeholder,
    this.errorBuilder,
    this.width,
    this.height,
    this.cancelToken,
    this.fit,
    this.isAntiAlias = false,
    this.controller,
  }) : image = NetworkImage(url);

  MixinImage.file(
    File file, {
    super.key,
    this.placeholder,
    this.errorBuilder,
    this.width,
    this.height,
    this.cancelToken,
    this.fit,
    this.isAntiAlias = false,
    this.controller,
  }) : image = FileImage(file);

  MixinImage.asset(
    String assetName, {
    super.key,
    this.placeholder,
    this.errorBuilder,
    this.width,
    this.height,
    this.cancelToken,
    this.fit,
    this.isAntiAlias = false,
    this.controller,
  }) : image = AssetImage(assetName);

  MixinImage.memory(
    Uint8List bytes, {
    super.key,
    this.placeholder,
    this.errorBuilder,
    this.width,
    this.height,
    this.cancelToken,
    this.fit,
    this.isAntiAlias = false,
    this.controller,
  }) : image = MemoryImage(bytes);

  final ImageProvider image;
  final PlaceholderWidgetBuilder? placeholder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final double? width;
  final double? height;
  final CancellationToken? cancelToken;
  final BoxFit? fit;
  final bool isAntiAlias;
  final ValueNotifier<bool>? controller;

  @override
  Widget build(BuildContext context) {
    final proxyUrl = context.database.settingProperties.activatedProxy;

    final frameInfo = useState<ui.FrameInfo?>(null);
    final timer = useState<Timer?>(null);
    final error = useState<(Object, StackTrace?)?>(null);
    final isImageLoading = useState(false);

    final codec = useMemoizedFuture(
      () async {
        try {
          error.value = null;
          final buffer = await _loadCacheBuffer(image, proxyUrl);
          return buffer != null
              ? PaintingBinding.instance.instantiateImageCodecWithSize(buffer)
              : null;
        } catch (e, stack) {
          error.value = (e, stack);
          return null;
        }
      },
      null,
      keys: [image, proxyUrl],
    ).data;

    useEffect(() {
      timer.value?.cancel();
      timer.value = null;
      frameInfo.value?.image.dispose();
      frameInfo.value = null;
      error.value = null;
      isImageLoading.value = false;
    }, [codec]);

    useEffect(() {
      if (codec == null) return null;

      Future<void> getNextFrame() async {
        if (isImageLoading.value || !context.mounted) return;

        try {
          error.value = null;

          isImageLoading.value = true;

          final frame = await codec.getNextFrame();
          if (!context.mounted) return;

          final oldFrame = frameInfo.value;
          oldFrame?.image.dispose();

          frameInfo.value = frame;

          final shouldContinueAnimation =
              codec.frameCount > 1 && (controller?.value ?? true);

          if (shouldContinueAnimation) {
            var duration = frame.duration;
            if (duration < _minFrameDuration) {
              duration = _defaultFrameDuration;
            }

            timer.value?.cancel();
            timer.value = Timer(duration, () {
              SchedulerBinding.instance.scheduleFrameCallback((_) {
                getNextFrame();
              });
            });
          }
        } catch (e, s) {
          error.value = (e, s);
        } finally {
          isImageLoading.value = false;
        }
      }

      getNextFrame();

      void onControllerChanged() {
        if (controller!.value) {
          if (codec.frameCount > 1) {
            getNextFrame();
          }
        } else {
          timer.value?.cancel();
          timer.value = null;
        }
      }

      controller?.addListener(onControllerChanged);

      return () {
        timer.value?.cancel();

        frameInfo.value?.image.dispose();
        if (context.mounted) {
          timer.value = null;
          frameInfo.value = null;
        }
        controller?.removeListener(onControllerChanged);
      };
    }, [codec, controller]);

    switch (error.value) {
      case (final Object e, final StackTrace? stack):
        final widget = errorBuilder?.call(context, e, stack);
        if (widget != null) {
          return widget;
        }
      default:
        break;
    }

    if (frameInfo.value == null) {
      return placeholder?.call() ?? SizedBox(width: width, height: height);
    }

    final currentFrame = frameInfo.value;
    if (currentFrame == null) {
      return placeholder?.call() ?? SizedBox(width: width, height: height);
    }

    return RawImage(
      image: currentFrame.image,
      width: width,
      height: height,
      fit: fit,
      isAntiAlias: isAntiAlias,
    );
  }
}
