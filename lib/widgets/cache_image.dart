import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:http_client_helper/http_client_helper.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/extension/extension.dart';
import '../utils/logger.dart';
import '../utils/proxy.dart';

typedef PlaceholderWidgetBuilder = Widget Function();

typedef LoadingErrorWidgetBuilder = Widget Function();

class CacheImage extends StatelessWidget {
  const CacheImage(
    this.src, {
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.fit = BoxFit.cover,
    this.controller,
    super.key,
  });

  final String src;
  final double? width;
  final double? height;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final ValueNotifier<bool>? controller;

  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final proxyUrl = context.database.settingProperties.activatedProxy;
    return Image(
      image: MixinNetworkImageProvider(
        src,
        controller: controller,
        proxyConfig: proxyUrl,
      ),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          errorWidget?.call() ?? SizedBox(width: width, height: height),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return placeholder?.call() ?? SizedBox(width: width, height: height);
      },
    );
  }
}

// min frameDuration
// see also:
// https://nullsleep.tumblr.com/post/16524517190/animated-gif-minimum-frame-delay-browser
// https://qiita.com/razokulover/items/34962844e314bb4bfd04
const _defaultFrameDuration = Duration(milliseconds: 100);
const _minFrameDuration = Duration(milliseconds: 20);

class _MultiFrameImageStreamCompleter extends ImageStreamCompleter {
  /// Creates a image stream completer.
  ///
  /// Immediately starts decoding the first image frame when the codec is ready.
  ///
  /// The `codec` parameter is a future for an initialized [ui.Codec] that will
  /// be used to decode the image.
  ///
  /// The `scale` parameter is the linear scale factor for drawing this frames
  /// of this image at their intended size.
  ///
  /// The `tag` parameter is passed on to created [ImageInfo] objects to
  /// help identify the source of the image.
  ///
  /// The `chunkEvents` parameter is an optional stream of notifications about
  /// the loading progress of the image. If this stream is provided, the events
  /// produced by the stream will be delivered to registered [ImageChunkListener]s
  /// (see [addListener]).
  _MultiFrameImageStreamCompleter({
    required Future<ui.Codec> codec,
    required double scale,
    String? debugLabel,
    Stream<ImageChunkEvent>? chunkEvents,
    InformationCollector? informationCollector,
    this.controller,
  })  : _informationCollector = informationCollector,
        _scale = scale {
    this.debugLabel = debugLabel;
    codec.then<void>(_handleCodecReady,
        onError: (Object error, StackTrace stack) {
      reportError(
        context: ErrorDescription('resolving an image codec'),
        exception: error,
        stack: stack,
        informationCollector: informationCollector,
        silent: true,
      );
    });
    if (chunkEvents != null) {
      chunkEvents.listen(
        reportImageChunkEvent,
        onError: (Object error, StackTrace stack) {
          reportError(
            context: ErrorDescription('loading an image'),
            exception: error,
            stack: stack,
            informationCollector: informationCollector,
            silent: true,
          );
        },
      );
    }
  }

  final ValueNotifier<bool>? controller;

  ImageInfo? _currentImage;
  ui.Codec? _codec;
  final double _scale;
  final InformationCollector? _informationCollector;
  ui.FrameInfo? _nextFrame;

  // When the current was first shown.
  late Duration _shownTimestamp;

  // The requested duration for the current frame;
  Duration? _frameDuration;

  // How many frames have been emitted so far.
  // int _framesEmitted = 0;
  Timer? _timer;

  // Used to guard against registering multiple _handleAppFrame callbacks for the same frame.
  bool _frameCallbackScheduled = false;

  void _controllerListener() {
    if (controller?.value == false) return;
    _decodeNextFrameAndSchedule();
  }

  void _handleCodecReady(ui.Codec codec) {
    _codec = codec;
    assert(_codec != null);

    if (hasListeners) {
      try {
        controller?.addListener(_controllerListener);
      } catch (_) {}
      _decodeNextFrameAndSchedule();
    }
  }

  void _handleAppFrame(Duration timestamp) {
    _frameCallbackScheduled = false;
    if (!hasListeners) return;
    assert(_nextFrame != null);
    if (_isFirstFrame() || _hasFrameDurationPassed(timestamp)) {
      _emitFrame(ImageInfo(
        image: _nextFrame!.image.clone(),
        scale: _scale,
        debugLabel: debugLabel,
      ));
      _shownTimestamp = timestamp;
      _frameDuration = _nextFrame!.duration;
      if (_frameDuration! < _minFrameDuration) {
        _frameDuration = _defaultFrameDuration;
      }
      _nextFrame!.image.dispose();
      _nextFrame = null;
      if (controller?.value == false) return;
      // ignore gif's repetition count
      _decodeNextFrameAndSchedule();
      return;
    }
    final delay = _frameDuration! - (timestamp - _shownTimestamp);
    _timer = Timer(delay, _scheduleAppFrame);
  }

  bool _isFirstFrame() => _frameDuration == null;

  bool _hasFrameDurationPassed(Duration timestamp) =>
      timestamp - _shownTimestamp >= _frameDuration!;

  Future<void> _decodeNextFrameAndSchedule() async {
    // This will be null if we gave it away. If not, it's still ours and it
    // must be disposed of.
    _nextFrame?.image.dispose();
    _nextFrame = null;
    try {
      _nextFrame = await _codec!.getNextFrame();
    } catch (exception, stack) {
      reportError(
        context: ErrorDescription('resolving an image frame'),
        exception: exception,
        stack: stack,
        informationCollector: _informationCollector,
        silent: true,
      );
      return;
    }
    if (_codec!.frameCount == 1) {
      // ImageStreamCompleter listeners removed while waiting for next frame to
      // be decoded.
      // There's no reason to emit the frame without active listeners.
      if (!hasListeners) {
        return;
      }
      // This is not an animated image, just return it and don't schedule more
      // frames.
      _emitFrame(ImageInfo(
        image: _nextFrame!.image.clone(),
        scale: _scale,
        debugLabel: debugLabel,
      ));
      _nextFrame!.image.dispose();
      _nextFrame = null;
      return;
    }
    _scheduleAppFrame();
  }

  void _scheduleAppFrame() {
    if (_frameCallbackScheduled) {
      return;
    }
    _frameCallbackScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback(_handleAppFrame);
  }

  void _emitFrame(ImageInfo imageInfo) {
    setImage(imageInfo);
    // _framesEmitted += 1;
  }

  @override
  void addListener(ImageStreamListener listener) {
    if (!hasListeners &&
        _codec != null &&
        (_currentImage == null || _codec!.frameCount > 1)) {
      _decodeNextFrameAndSchedule();
    }
    super.addListener(listener);
  }

  @override
  void removeListener(ImageStreamListener listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _timer?.cancel();
      _timer = null;
    }
  }
}

class MixinFileImage extends FileImage {
  MixinFileImage(
    super.file, {
    super.scale,
    this.controller,
  }) : _lastModified = _fileLastModified(file);

  final ValueNotifier<bool>? controller;

  // used to check if the file has been modified.
  final int _lastModified;

  static int _fileLastModified(File file) {
    try {
      return file.lastModifiedSync().millisecondsSinceEpoch;
    } catch (_) {
      return 0;
    }
  }

  @override
  @protected
  ImageStreamCompleter loadImage(FileImage key, ImageDecoderCallback decode) =>
      _MultiFrameImageStreamCompleter(
        codec: _loadAsync(key, decode: decode),
        scale: key.scale,
        debugLabel: key.file.path,
        informationCollector: () => <DiagnosticsNode>[
          ErrorDescription('Path: ${file.path}'),
        ],
        controller: controller,
      );

  Future<ui.Codec> _loadAsync(
    FileImage key, {
    ImageDecoderCallback? decode,
    // ignore: deprecated_member_use
    DecoderBufferCallback? decodeBufferDeprecated,
  }) async {
    assert(key == this);

    if (file.path.isEmpty) {
      throw StateError('file path is empty');
    }

    if (!file.existsSync()) {
      throw StateError('file is not exists. ${file.path}');
    }

    final bytes = await file.readAsBytes();

    if (bytes.lengthInBytes == 0) {
      // The file may become available later.
      PaintingBinding.instance.imageCache.evict(key);
      throw StateError('$file is empty and cannot be loaded as an image.');
    }

    if (decodeBufferDeprecated != null) {
      return decodeBufferDeprecated(
          await ui.ImmutableBuffer.fromUint8List(bytes));
    } else {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return decode!(buffer);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is MixinFileImage &&
      super == other &&
      _lastModified == other._lastModified;

  @override
  int get hashCode => Object.hash(super.hashCode, _lastModified);
}

const String cacheImageFolderName = 'cacheimage';

@immutable
class MixinNetworkImageProvider
    extends ImageProvider<MixinNetworkImageProvider> {
  const MixinNetworkImageProvider(
    this.url, {
    this.scale = 1.0,
    this.headers,
    this.cache = true,
    this.retries = 3,
    this.timeLimit,
    this.timeRetry = const Duration(milliseconds: 100),
    this.cacheKey,
    this.printError = true,
    this.cancelToken,
    this.imageCacheName,
    this.cacheMaxAge,
    this.controller,
    this.proxyConfig,
  });

  final ValueNotifier<bool>? controller;

  /// The name of [ImageCache], you can define custom [ImageCache] to store this provider.
  final String? imageCacheName;

  /// The time limit to request image
  final Duration? timeLimit;

  /// The time to retry to request
  final int retries;

  /// The time duration to retry to request
  final Duration timeRetry;

  /// Whether cache image to local
  final bool cache;

  /// The URL from which the image will be fetched.
  final String url;

  final ProxyConfig? proxyConfig;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  /// The HTTP headers that will be used with [HttpClient.get] to fetch image from network.
  final Map<String, String>? headers;

  /// The token to cancel network request
  final CancellationToken? cancelToken;

  /// Custom cache key
  final String? cacheKey;

  /// print error
  final bool printError;

  /// The max duration to cache image.
  /// After this time the cache is expired and the image is reloaded.
  final Duration? cacheMaxAge;

  @override
  ImageStreamCompleter loadImage(
      MixinNetworkImageProvider key, ImageDecoderCallback decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();

    return _MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode: decode),
      scale: key.scale,
      chunkEvents: chunkEvents.stream,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<MixinNetworkImageProvider>('Image key', key),
      ],
      controller: controller,
    );
  }

  /// Override this method, so that you can handle raw image data,
  /// for example, compress
  Future<ui.Codec> instantiateImageCodec(
    Uint8List data, {
    ImageDecoderCallback? decode,
    // ignore: deprecated_member_use
    DecoderBufferCallback? decodeBufferDeprecated,
  }) async {
    if (decodeBufferDeprecated != null) {
      return decodeBufferDeprecated(
          await ui.ImmutableBuffer.fromUint8List(data));
    } else {
      return decode!(await ui.ImmutableBuffer.fromUint8List(data));
    }
  }

  @override
  Future<MixinNetworkImageProvider> obtainKey(
          ImageConfiguration configuration) =>
      SynchronousFuture<MixinNetworkImageProvider>(this);

  Future<ui.Codec> _loadAsync(
    MixinNetworkImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents, {
    ImageDecoderCallback? decode,
    // ignore: deprecated_member_use
    DecoderBufferCallback? decodeBufferDeprecated,
  }) async {
    assert(key == this);
    final md5Key = cacheKey ?? keyToMd5(key.url);
    ui.Codec? result;
    if (cache) {
      try {
        final data = await _loadCache(key, chunkEvents, md5Key);
        if (data != null) {
          result = await instantiateImageCodec(
            data,
            decode: decode,
            decodeBufferDeprecated: decodeBufferDeprecated,
          );
        }
      } catch (e) {
        if (printError) {
          i('load cache error $e');
        }
      }
    }

    if (result == null) {
      try {
        final data = await _loadNetwork(key, chunkEvents);
        if (data != null) {
          result = await instantiateImageCodec(
            data,
            decode: decode,
            decodeBufferDeprecated: decodeBufferDeprecated,
          );
        }
      } catch (e) {
        i('load network error $e');
      }
    }

    if (result == null) {
      // The image failed to load, so we should evict it from the cache.
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
      return Future<ui.Codec>.error(StateError('Failed to load $url.'));
    }
    return result;
  }

  /// Get the image from cache folder.
  Future<Uint8List?> _loadCache(
    MixinNetworkImageProvider key,
    StreamController<ImageChunkEvent>? chunkEvents,
    String md5Key,
  ) async {
    final _cacheImagesDirectory = Directory(
        join((await getTemporaryDirectory()).path, cacheImageFolderName));
    Uint8List? data;
    // exist, try to find cache image file
    if (_cacheImagesDirectory.existsSync()) {
      final cacheFile = File(join(_cacheImagesDirectory.path, md5Key));
      if (cacheFile.existsSync()) {
        if (key.cacheMaxAge != null) {
          final now = DateTime.now();
          final fs = cacheFile.statSync();
          if (now.subtract(key.cacheMaxAge!).isAfter(fs.changed)) {
            i('cache expired, reload. $url');
            cacheFile.deleteSync(recursive: true);
          } else {
            data = await cacheFile.readAsBytes();
          }
        } else {
          data = await cacheFile.readAsBytes();
        }
      }
    }
    // create folder
    else {
      await _cacheImagesDirectory.create();
    }

    // load from network
    if (data == null) {
      data = await _loadNetwork(
        key,
        chunkEvents,
      );
      if (data != null) {
        // cache image file
        await File(join(_cacheImagesDirectory.path, md5Key)).writeAsBytes(data);
      }
    }

    return data;
  }

  /// Get the image from network.
  Future<Uint8List?> _loadNetwork(
    MixinNetworkImageProvider key,
    StreamController<ImageChunkEvent>? chunkEvents,
  ) async {
    try {
      final resolved = Uri.base.resolve(key.url);
      final response = await _tryGetResponse(resolved, key.proxyConfig);
      if (response == null || response.statusCode != HttpStatus.ok) {
        return null;
      }

      final bytes = await consolidateHttpClientResponseBytes(
        response,
        onBytesReceived: chunkEvents != null
            ? (int cumulative, int? total) {
                chunkEvents.add(ImageChunkEvent(
                  cumulativeBytesLoaded: cumulative,
                  expectedTotalBytes: total,
                ));
              }
            : null,
      );
      if (bytes.lengthInBytes == 0) {
        return Future<Uint8List>.error(
            StateError('NetworkImage is an empty file: $resolved'));
      }

      return bytes;
      // ignore: avoid_catching_errors
    } on OperationCanceledError catch (_) {
      if (printError) {
        i('User cancel request.');
      }
      return Future<Uint8List>.error(StateError('User cancel request $url.'));
    } catch (e) {
      if (printError) {
        i('Failed to load image. $e');
      }
    } finally {
      await chunkEvents?.close();
    }
    return null;
  }

  Future<HttpClientResponse> _getResponse(
      Uri resolved, ProxyConfig? proxy) async {
    if (proxy != _imageClientProxyConfig) {
      _httpClient.setProxy(proxy);
      _imageClientProxyConfig = proxy;
    }
    final request = await _httpClient.getUrl(resolved);
    headers?.forEach((String name, String value) {
      request.headers.add(name, value);
    });
    final response = await request.close();
    if (timeLimit != null) {
      response.timeout(
        timeLimit!,
      );
    }
    return response;
  }

  // Http get with cancel, delay try again
  Future<HttpClientResponse?> _tryGetResponse(
    Uri resolved,
    ProxyConfig? proxy,
  ) async {
    cancelToken?.throwIfCancellationRequested();
    return RetryHelper.tryRun<HttpClientResponse>(
      () => CancellationTokenSource.register(
        cancelToken,
        _getResponse(resolved, proxy),
      ),
      cancelToken: cancelToken,
      timeRetry: timeRetry,
      retries: retries,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is MixinNetworkImageProvider &&
        url == other.url &&
        scale == other.scale &&
        timeLimit == other.timeLimit &&
        cancelToken == other.cancelToken &&
        timeRetry == other.timeRetry &&
        cache == other.cache &&
        cacheKey == other.cacheKey &&
        headers == other.headers &&
        retries == other.retries &&
        imageCacheName == other.imageCacheName &&
        cacheMaxAge == other.cacheMaxAge &&
        controller == other.controller;
  }

  @override
  int get hashCode => Object.hash(
        controller,
        url,
        scale,
        timeLimit,
        cancelToken,
        timeRetry,
        cache,
        cacheKey,
        headers,
        retries,
        imageCacheName,
        cacheMaxAge,
      );

  @override
  String toString() =>
      'MixinExtendedNetworkImageProvider("$url", scale: $scale)';

  /// Get network image data from cached
  Future<Uint8List?> getNetworkImageData({
    StreamController<ImageChunkEvent>? chunkEvents,
  }) {
    final uId = cacheKey ?? keyToMd5(url);

    if (cache) {
      return _loadCache(
        this,
        chunkEvents,
        uId,
      );
    }

    return _loadNetwork(
      this,
      chunkEvents,
    );
  }

  // Do not access this field directly; use [_httpClient] instead.
  // We set `autoUncompress` to false to ensure that we can trust the value of
  // the `Content-Length` HTTP header. We automatically uncompress the content
  // in our call to [consolidateHttpClientResponseBytes].
  static final HttpClient _sharedHttpClient = HttpClient()
    ..autoUncompress = false;

  static HttpClient get _httpClient {
    var client = _sharedHttpClient;
    assert(() {
      if (debugNetworkImageHttpClientProvider != null) {
        client = debugNetworkImageHttpClientProvider!();
      }
      return true;
    }());
    return client;
  }

  /// proxy config for [_httpClient]
  static ProxyConfig? _imageClientProxyConfig;
}

/// download image from network to cache. return the cache image file.
/// [url] is the image url.
Future<Uint8List?> downloadImage(String url) async {
  final imageProvider = MixinNetworkImageProvider(url);
  return imageProvider._loadCache(imageProvider, null, keyToMd5(url));
}

/// get md5 from key
String keyToMd5(String key) => md5.convert(utf8.encode(key)).toString();

class MixinAssetImage extends AssetImage {
  const MixinAssetImage(
    super.assetName, {
    super.bundle,
    super.package,
    this.controller,
  });

  final ValueNotifier<bool>? controller;

  @protected
  Future<ui.Codec> _loadAsync(
    AssetBundleImageKey key, {
    required Future<ui.Codec> Function(ui.ImmutableBuffer buffer) decode,
  }) async {
    final ui.ImmutableBuffer buffer;
    // Hot reload/restart could change whether an asset bundle or key in a
    // bundle are available, or if it is a network backed bundle.
    try {
      buffer = await key.bundle.loadBuffer(key.name);
      // ignore: avoid_catching_errors
    } on FlutterError {
      PaintingBinding.instance.imageCache.evict(key);
      rethrow;
    }
    return decode(buffer);
  }

  @override
  ImageStreamCompleter loadImage(
      AssetBundleImageKey key, ImageDecoderCallback decode) {
    InformationCollector? collector;
    assert(() {
      collector = () => <DiagnosticsNode>[
            DiagnosticsProperty<ImageProvider>('Image provider', this),
            DiagnosticsProperty<AssetBundleImageKey>('Image key', key),
          ];
      return true;
    }());
    return _MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode: decode),
      scale: key.scale,
      debugLabel: key.name,
      informationCollector: collector,
      controller: controller,
    );
  }
}
