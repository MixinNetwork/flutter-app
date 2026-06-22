part of 'files_preview.dart';

/// We need this view object to keep the value of file#length.
sealed class _File {
  const _File({required this.file});

  factory _File.normal(String path) => _NormalFile._(file: File(path).xFile);

  factory _File.image(File file, [ImageEditorSnapshot? snapshot]) =>
      _ImageFile._(file: file.xFile, imageEditorSnapshot: snapshot);

  factory _File.auto(XFile file) {
    final resolvedFile = file.mimeType == null ? file.withMineType() : file;
    if (file.mimeType == null) {
      e('mimeType is null');
    }
    if (resolvedFile.isImage) {
      return _ImageFile._(file: resolvedFile);
    } else if (kPlatformIsDarwin && resolvedFile.isVideo) {
      return _VideoFile._(file: resolvedFile);
    } else {
      return _NormalFile._(file: resolvedFile);
    }
  }

  final XFile file;

  bool get isImage => false;

  bool get isVideo => false;

  bool get isMedia => isImage || isVideo;

  String get path => file.path;

  String? get mimeType => file.mimeType;
}

class _NormalFile extends _File {
  const _NormalFile._({required super.file});
}

class _ImageFile extends _File {
  const _ImageFile._({required super.file, this.imageEditorSnapshot});

  final ImageEditorSnapshot? imageEditorSnapshot;

  @override
  bool get isImage => true;
}

class _VideoMetadata {
  _VideoMetadata({
    required this.width,
    required this.height,
    required this.duration,
  });

  final int width;
  final int height;
  final int duration;
}

class _VideoFile extends _File {
  _VideoFile._({required super.file}) {
    _loadMetadata();
  }

  static Future<String?> _videoBlurHash(
    (RootIsolateToken token, String videoPath) params,
  ) async {
    final (token, videoPath) = params;
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    final bytes = await customVideoCompress.getByteThumbnail(videoPath);
    final decodedImage = image.decodeImage(bytes!)!;
    return BlurHash.encode(
      image.copyResize(decodedImage, width: 100, maintainAspect: true),
    ).hash;
  }

  final _metadataCompleter = Completer<_VideoMetadata?>();

  final _blurHashCompleter = Completer<String?>();

  Future<void> _loadMetadata() async {
    try {
      final mediaInfo = await customVideoCompress.getMediaInfo(file.path);
      final duration = mediaInfo.duration ?? 0.0;
      _metadataCompleter.complete(
        _VideoMetadata(
          width: mediaInfo.width ?? 0,
          height: mediaInfo.height ?? 0,
          duration: duration.floor(),
        ),
      );
    } catch (error, stackTrace) {
      e('failed to load video metadata', error, stackTrace);
      _metadataCompleter.complete(null);
    }

    final stopwatch = Stopwatch()..start();
    try {
      final hash = await compute(_videoBlurHash, (
        ServicesBinding.rootIsolateToken!,
        file.path,
      ));
      _blurHashCompleter.complete(hash);
    } catch (error, stackTrace) {
      e('failed to load video thumbnail', error, stackTrace);
      _blurHashCompleter.complete(null);
    }

    d('thumbnail cost: ${stopwatch.elapsedMilliseconds}ms');
  }

  @override
  bool get isVideo => true;
}

typedef _ImageEditedCallback = void Function(_File, ImageEditorSnapshot);

const _kDefaultArchiveName = 'Archive.zip';

enum _TabType { image, files, zip }
