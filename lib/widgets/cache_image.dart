import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
// ignore: implementation_imports
import 'package:cached_network_image/src/image_provider/_image_loader.dart'
    as cached_network_image;
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:octo_image/octo_image.dart';

class CacheImage extends StatelessWidget {
  const CacheImage(
    this.src, {
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    Key? key,
  }) : super(key: key);

  final String src;
  final double? width;
  final double? height;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;

  @override
  Widget build(BuildContext context) => _CachedNetworkImage(
        imageUrl: src,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: placeholder,
        errorWidget: errorWidget,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 400),
      );
}

// min frameDuration
// see also:
// https://nullsleep.tumblr.com/post/16524517190/animated-gif-minimum-frame-delay-browser
// https://qiita.com/razokulover/items/34962844e314bb4bfd04
const _defaultFrameDuration = Duration(milliseconds: 100);
const _minFrameDuration = Duration(milliseconds: 20);

class _MultiImageStreamCompleter extends ImageStreamCompleter {
  /// The constructor to create an MultiImageStreamCompleter. The [codec]
  /// should be a stream with the images that should be shown. The
  /// [chunkEvents] should indicate the [ImageChunkEvent]s of the first image
  /// to show.
  _MultiImageStreamCompleter({
    required Stream<ui.Codec> codec,
    required double scale,
    Stream<ImageChunkEvent>? chunkEvents,
    InformationCollector? informationCollector,
  })  : _informationCollector = informationCollector,
        _scale = scale {
    codec.listen((event) {
      if (_timer != null) {
        _nextImageCodec = event;
      } else {
        _handleCodecReady(event);
      }
    }, onError: (Object error, StackTrace stack) {
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

  ui.Codec? _codec;
  ui.Codec? _nextImageCodec;
  final double _scale;
  final InformationCollector? _informationCollector;
  ui.FrameInfo? _nextFrame;

  // When the current was first shown.
  Duration? _shownTimestamp;

  // The requested duration for the current frame;
  Duration? _frameDuration;

  // How many frames have been emitted so far.
  int _framesEmitted = 0;
  Timer? _timer;

  // Used to guard against registering multiple _handleAppFrame callbacks for the same frame.
  bool _frameCallbackScheduled = false;

  void _switchToNewCodec() {
    _framesEmitted = 0;
    _timer = null;
    _handleCodecReady(_nextImageCodec!);
    _nextImageCodec = null;
  }

  void _handleCodecReady(ui.Codec codec) {
    _codec = codec;

    if (hasListeners) {
      _decodeNextFrameAndSchedule();
    }
  }

  void _handleAppFrame(Duration timestamp) {
    _frameCallbackScheduled = false;
    if (!hasListeners) return;
    if (_isFirstFrame() || _hasFrameDurationPassed(timestamp)) {
      _emitFrame(ImageInfo(image: _nextFrame!.image, scale: _scale));
      _shownTimestamp = timestamp;
      _frameDuration = _nextFrame!.duration;
      if (_frameDuration! < _minFrameDuration) {
        _frameDuration = _defaultFrameDuration;
      }
      _nextFrame = null;
      if (_framesEmitted % _codec!.frameCount == 0 && _nextImageCodec != null) {
        _switchToNewCodec();
      } else {
        final completedCycles = _framesEmitted ~/ _codec!.frameCount;
        if (_codec!.repetitionCount == -1 ||
            completedCycles <= _codec!.repetitionCount) {
          _decodeNextFrameAndSchedule();
        }
      }
      return;
    }
    final delay = _frameDuration! - (timestamp - _shownTimestamp!);
    _timer = Timer(delay, _scheduleAppFrame);
  }

  bool _isFirstFrame() => _frameDuration == null;

  bool _hasFrameDurationPassed(Duration timestamp) =>
      timestamp - _shownTimestamp! >= _frameDuration!;

  Future<void> _decodeNextFrameAndSchedule() async {
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
      _emitFrame(ImageInfo(image: _nextFrame!.image, scale: _scale));
      return;
    }
    _scheduleAppFrame();
  }

  void _scheduleAppFrame() {
    if (_frameCallbackScheduled) {
      return;
    }
    _frameCallbackScheduled = true;
    SchedulerBinding.instance?.scheduleFrameCallback(_handleAppFrame);
  }

  void _emitFrame(ImageInfo imageInfo) {
    setImage(imageInfo);
    _framesEmitted += 1;
  }

  @override
  void addListener(ImageStreamListener listener) {
    if (!hasListeners && _codec != null) _decodeNextFrameAndSchedule();
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

class MultiFrameImageStreamCompleter extends ImageStreamCompleter {
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
  MultiFrameImageStreamCompleter({
    required Future<ui.Codec> codec,
    required double scale,
    String? debugLabel,
    Stream<ImageChunkEvent>? chunkEvents,
    InformationCollector? informationCollector,
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
  int _framesEmitted = 0;
  Timer? _timer;

  // Used to guard against registering multiple _handleAppFrame callbacks for the same frame.
  bool _frameCallbackScheduled = false;

  void _handleCodecReady(ui.Codec codec) {
    _codec = codec;
    assert(_codec != null);

    if (hasListeners) {
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
      final completedCycles = _framesEmitted ~/ _codec!.frameCount;
      if (_codec!.repetitionCount == -1 ||
          completedCycles <= _codec!.repetitionCount) {
        _decodeNextFrameAndSchedule();
      }
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
    SchedulerBinding.instance!.scheduleFrameCallback(_handleAppFrame);
  }

  void _emitFrame(ImageInfo imageInfo) {
    setImage(imageInfo);
    _framesEmitted += 1;
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
  const MixinFileImage(File file, {double scale = 1.0})
      : super(file, scale: scale);

  @override
  ImageStreamCompleter load(FileImage key, DecoderCallback decode) =>
      MultiFrameImageStreamCompleter(
        codec: _loadAsync(key, decode),
        scale: key.scale,
        debugLabel: key.file.path,
        informationCollector: () sync* {
          yield ErrorDescription('Path: ${file.path}');
        },
      );

  Future<ui.Codec> _loadAsync(FileImage key, DecoderCallback decode) async {
    assert(key == this);

    final bytes = await file.readAsBytes();

    if (bytes.lengthInBytes == 0) {
      // The file may become available later.
      PaintingBinding.instance!.imageCache!.evict(key);
      throw StateError('$file is empty and cannot be loaded as an image.');
    }

    return decode(bytes);
  }
}

class _CachedNetworkImageProvider extends CachedNetworkImageProvider {
  const _CachedNetworkImageProvider(
    String url, {
    int? maxHeight,
    int? maxWidth,
    double scale = 1.0,
    ErrorListener? errorListener,
    Map<String, String>? headers,
    BaseCacheManager? cacheManager,
    String? cacheKey,
    ImageRenderMethodForWeb imageRenderMethodForWeb =
        ImageRenderMethodForWeb.HtmlImage,
  }) : super(
          url,
          maxHeight: maxHeight,
          maxWidth: maxWidth,
          scale: scale,
          errorListener: errorListener,
          headers: headers,
          cacheManager: cacheManager,
          cacheKey: cacheKey,
          imageRenderMethodForWeb: imageRenderMethodForWeb,
        );

  @override
  ImageStreamCompleter load(
      CachedNetworkImageProvider key, DecoderCallback decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return _MultiImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      informationCollector: () sync* {
        yield DiagnosticsProperty<ImageProvider>(
          'Image provider: $this \n Image key: $key',
          this,
          style: DiagnosticsTreeStyle.errorProperty,
        );
      },
    );
  }

  Stream<ui.Codec> _loadAsync(
    CachedNetworkImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderCallback decode,
  ) {
    assert(key == this);
    return cached_network_image.ImageLoader().loadAsync(
      url,
      cacheKey,
      chunkEvents,
      decode,
      cacheManager ?? DefaultCacheManager(),
      maxHeight,
      maxWidth,
      headers,
      errorListener,
      imageRenderMethodForWeb,
      () => PaintingBinding.instance?.imageCache?.evict(key),
    );
  }
}

class _CachedNetworkImage extends StatelessWidget {
  /// CachedNetworkImage shows a network image using a caching mechanism. It also
  /// provides support for a placeholder, showing an error and fading into the
  /// loaded image. Next to that it supports most features of a default Image
  /// widget.
  _CachedNetworkImage({
    Key? key,
    required this.imageUrl,
    this.httpHeaders,
    this.imageBuilder,
    this.placeholder,
    this.progressIndicatorBuilder,
    this.errorWidget,
    this.fadeOutDuration = const Duration(milliseconds: 1000),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    this.cacheManager,
    this.useOldImageOnUrlChange = false,
    this.color,
    this.filterQuality = FilterQuality.low,
    this.colorBlendMode,
    this.placeholderFadeInDuration,
    this.memCacheWidth,
    this.memCacheHeight,
    this.cacheKey,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
    ImageRenderMethodForWeb imageRenderMethodForWeb =
        ImageRenderMethodForWeb.HtmlImage,
  })  : _image = _CachedNetworkImageProvider(
          imageUrl,
          headers: httpHeaders,
          cacheManager: cacheManager,
          cacheKey: cacheKey,
          imageRenderMethodForWeb: imageRenderMethodForWeb,
          maxWidth: maxWidthDiskCache,
          maxHeight: maxHeightDiskCache,
        ),
        super(key: key);

  final CachedNetworkImageProvider _image;

  /// Option to use cachemanager with other settings
  final BaseCacheManager? cacheManager;

  /// The target image that is displayed.
  final String imageUrl;

  /// The target image's cache key.
  final String? cacheKey;

  /// Optional builder to further customize the display of the image.
  final ImageWidgetBuilder? imageBuilder;

  /// Widget displayed while the target [imageUrl] is loading.
  final PlaceholderWidgetBuilder? placeholder;

  /// Widget displayed while the target [imageUrl] is loading.
  final ProgressIndicatorBuilder? progressIndicatorBuilder;

  /// Widget displayed while the target [imageUrl] failed loading.
  final LoadingErrorWidgetBuilder? errorWidget;

  /// The duration of the fade-in animation for the [placeholder].
  final Duration? placeholderFadeInDuration;

  /// The duration of the fade-out animation for the [placeholder].
  final Duration? fadeOutDuration;

  /// The curve of the fade-out animation for the [placeholder].
  final Curve fadeOutCurve;

  /// The duration of the fade-in animation for the [imageUrl].
  final Duration fadeInDuration;

  /// The curve of the fade-in animation for the [imageUrl].
  final Curve fadeInCurve;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder widget does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double? width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder widget does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double? height;

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit? fit;

  /// How to align the image within its bounds.
  ///
  /// The alignment aligns the given position in the image to the given position
  /// in the layout bounds. For example, a [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while a
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// image with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
  /// [AlignmentDirectional]), then an ambient [Directionality] widget
  /// must be in scope.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final Alignment alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// Whether to paint the image in the direction of the [TextDirection].
  ///
  /// If this is true, then in [TextDirection.ltr] contexts, the image will be
  /// drawn with its origin in the top left (the "normal" painting direction for
  /// children); and in [TextDirection.rtl] contexts, the image will be drawn with
  /// a scaling factor of -1 in the horizontal direction so that the origin is
  /// in the top right.
  ///
  /// This is occasionally used with children in right-to-left environments, for
  /// children that were designed for left-to-right locales. Be careful, when
  /// using this, to not flip children with integral shadows, text, or other
  /// effects that will look incorrect when flipped.
  ///
  /// If this is true, there must be an ambient [Directionality] widget in
  /// scope.
  final bool matchTextDirection;

  /// Optional headers for the http request of the image url
  final Map<String, String>? httpHeaders;

  /// When set to true it will animate from the old image to the new image
  /// if the url changes.
  final bool useOldImageOnUrlChange;

  /// If non-null, this color is blended with each image pixel using [colorBlendMode].
  final Color? color;

  /// Used to combine [color] with this image.
  ///
  /// The default is [BlendMode.srcIn]. In terms of the blend mode, [color] is
  /// the source and this image is the destination.
  ///
  /// See also:
  ///
  ///  * [BlendMode], which includes an illustration of the effect of each blend mode.
  final BlendMode? colorBlendMode;

  /// Target the interpolation quality for image scaling.
  ///
  /// If not given a value, defaults to FilterQuality.low.
  final FilterQuality filterQuality;

  /// Will resize the image in memory to have a certain width using [ResizeImage]
  final int? memCacheWidth;

  /// Will resize the image in memory to have a certain height using [ResizeImage]
  final int? memCacheHeight;

  /// Will resize the image and store the resized image in the disk cache.
  final int? maxWidthDiskCache;

  /// Will resize the image and store the resized image in the disk cache.
  final int? maxHeightDiskCache;

  @override
  Widget build(BuildContext context) {
    var octoPlaceholderBuilder =
        placeholder != null ? _octoPlaceholderBuilder : null;
    final octoProgressIndicatorBuilder =
        progressIndicatorBuilder != null ? _octoProgressIndicatorBuilder : null;

    ///If there is no placeholer OctoImage does not fade, so always set an
    ///(empty) placeholder as this always used to be the behaviour of
    ///CachedNetworkImage.
    if (octoPlaceholderBuilder == null &&
        octoProgressIndicatorBuilder == null) {
      octoPlaceholderBuilder = (context) => Container();
    }

    return OctoImage(
      image: _image,
      imageBuilder: imageBuilder != null ? _octoImageBuilder : null,
      placeholderBuilder: octoPlaceholderBuilder,
      progressIndicatorBuilder: octoProgressIndicatorBuilder,
      errorBuilder: errorWidget != null ? _octoErrorBuilder : null,
      fadeOutDuration: fadeOutDuration,
      fadeOutCurve: fadeOutCurve,
      fadeInDuration: fadeInDuration,
      fadeInCurve: fadeInCurve,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      matchTextDirection: matchTextDirection,
      color: color,
      filterQuality: filterQuality,
      colorBlendMode: colorBlendMode,
      placeholderFadeInDuration: placeholderFadeInDuration,
      gaplessPlayback: useOldImageOnUrlChange,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
    );
  }

  Widget _octoImageBuilder(BuildContext context, Widget child) =>
      imageBuilder!(context, _image);

  Widget _octoPlaceholderBuilder(BuildContext context) =>
      placeholder!(context, imageUrl);

  Widget _octoProgressIndicatorBuilder(
    BuildContext context,
    ImageChunkEvent? progress,
  ) {
    int? totalSize;
    var downloaded = 0;
    if (progress != null) {
      totalSize = progress.expectedTotalBytes;
      downloaded = progress.cumulativeBytesLoaded;
    }
    return progressIndicatorBuilder!(
        context, imageUrl, DownloadProgress(imageUrl, totalSize, downloaded));
  }

  Widget _octoErrorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) =>
      errorWidget!(context, imageUrl, error);
}
