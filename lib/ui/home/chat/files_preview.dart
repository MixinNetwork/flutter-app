import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image/image.dart' as image;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:super_context_menu/super_context_menu.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

import '../../../constants/brightness_theme_data.dart';
import '../../../constants/constants.dart';
import '../../../constants/icon_fonts.dart';
import '../../../constants/resources.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/load_balancer_utils.dart';
import '../../../utils/logger.dart';
import '../../../utils/platform.dart';
import '../../../utils/system/clipboard.dart';
import '../../../utils/system/text_input.dart';
import '../../../utils/video.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/cache_image.dart';
import '../../../widgets/dash_path_border.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/high_light_text.dart';
import '../../../widgets/image.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/menu.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/quote_message_provider.dart';
import 'image_caption_input.dart';
import 'image_editor.dart';

Future<void> showFilesPreviewDialog(
    BuildContext context, List<XFile> files) async {
  await showMixinDialog(
    context: context,
    child: _FilesPreviewDialog(
      initialFiles: files.map(_File.auto).toList(),
    ),
  );
}

/// We need this view object to keep the value of file#length.
sealed class _File {
  const _File({
    required this.file,
  });

  factory _File.normal(String path) => _NormalFile._(file: File(path).xFile);

  factory _File.image(File file, [ImageEditorSnapshot? snapshot]) =>
      _ImageFile._(
        file: file.xFile,
        imageEditorSnapshot: snapshot,
      );

  factory _File.auto(XFile file) {
    if (file.mimeType == null) {
      e('mimeType is null');
      file = file.withMineType();
    }
    if (file.isImage) {
      return _ImageFile._(file: file);
    } else if (kPlatformIsDarwin && file.isVideo) {
      return _VideoFile._(file: file);
    } else {
      return _NormalFile._(file: file);
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
      (RootIsolateToken token, String videoPath) params) async {
    final (token, videoPath) = params;
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    final bytes = await customVideoCompress.getByteThumbnail(videoPath);
    final decodedImage = image.decodeImage(bytes!)!;
    return BlurHash.encode(
      image.copyResize(
        decodedImage,
        width: 100,
        maintainAspect: true,
      ),
    ).hash;
  }

  final _metadataCompleter = Completer<_VideoMetadata>();

  final _blurHashCompleter = Completer<String>();

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
      _metadataCompleter.completeError(error, stackTrace);
    }

    final stopwatch = Stopwatch()..start();
    try {
      final hash = await compute(
          _videoBlurHash, (ServicesBinding.rootIsolateToken!, file.path));
      _blurHashCompleter.complete(hash);
    } catch (error, stackTrace) {
      e('failed to load video thumbnail', error, stackTrace);
      _blurHashCompleter.completeError(error, stackTrace);
    }

    d('thumbnail cost: ${stopwatch.elapsedMilliseconds}ms');
  }

  @override
  bool get isVideo => true;
}

typedef _ImageEditedCallback = void Function(_File, ImageEditorSnapshot);

const _kDefaultArchiveName = 'Archive.zip';

enum _TabType { image, files, zip }

class _FilesPreviewDialog extends HookConsumerWidget {
  const _FilesPreviewDialog({
    required this.initialFiles,
  });

  final List<_File> initialFiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = useState(initialFiles);
    final quoteMessageCubit = ref.watch(quoteMessageProvider.notifier);

    final hasMedia = useMemoized(
      () => files.value.indexWhere((e) => e.isMedia) != -1,
      [identityHashCode(files.value)],
    );
    final isOneImage = files.value.length == 1 && files.value.first.isImage;

    final showZipTab = files.value.length > 1;

    final currentTab = useState(_TabType.files);

    final onFileAddedStream = useStreamController<int>();
    final onFileRemovedStream = useStreamController<(int, _File)>();

    void removeFile(_File file) {
      final index = files.value.indexOf(file);
      files.value = (files.value..removeAt(index)).toList();
      onFileRemovedStream.add((index, file));
      if (files.value.isEmpty) {
        Navigator.pop(context);
      }
    }

    final previousTab = usePrevious(currentTab.value);

    useEffect(() {
      if (previousTab == null && hasMedia) {
        currentTab.value = _TabType.image;
      } else if (previousTab == null && !hasMedia) {
        currentTab.value = _TabType.files;
      } else if (!hasMedia && currentTab.value == _TabType.image) {
        currentTab.value = _TabType.files;
      } else if (!showZipTab && currentTab.value == _TabType.zip) {
        currentTab.value = _TabType.files;
      }
    }, [hasMedia, showZipTab]);

    final showAsBigImage = useState(hasMedia);

    useEffect(() {
      showAsBigImage.value = hasMedia && currentTab.value == _TabType.image;
    }, [hasMedia, currentTab.value]);

    final zipPasswordController = useTextEditingController();
    final imageCaptionController = useMemoized(EmojiTextEditingController.new);

    useEffect(() {
      imageCaptionController.clear();
      return null;
    }, [isOneImage]);

    Future<void> send(bool silent) async {
      if (currentTab.value != _TabType.zip) {
        for (final file in files.value) {
          unawaited(_sendFile(
            context,
            file,
            quoteMessageCubit.state?.messageId,
            silent: silent,
            compress: currentTab.value == _TabType.image,
            imageCaption: isOneImage ? imageCaptionController.text : null,
          ));
        }
        quoteMessageCubit.state = null;
        Navigator.pop(context);
      } else {
        final zipFilePath = await runLoadBalancer(_archiveFiles, (
          (await getTemporaryDirectory()).path,
          zipPasswordController.text.trim(),
          files.value.map((e) => e.path).toList(),
        ));
        unawaited(_sendFile(
          context,
          _File.normal(zipFilePath),
          quoteMessageCubit.state?.messageId,
          silent: silent,
          compress: false,
        ));
        quoteMessageCubit.state = null;
        Navigator.pop(context);
      }
    }

    void addFile(List<_File> fileAdded) {
      final currentFiles = files.value.map((e) => e.path).toSet();
      fileAdded.removeWhere((e) => currentFiles.contains(e.path));
      files.value = (files.value..addAll(fileAdded)).toList();
      for (var i = 0; i < fileAdded.length; i++) {
        onFileAddedStream.add(currentFiles.length + i);
      }
    }

    return _Actions(
      onSend: () => send(false),
      onFileAdded: addFile,
      child: SizedBox(
          width: 480,
          height: 600,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Tab(
                          assetName: Resources.assetsImagesFilePreviewImagesSvg,
                          tooltip: context.l10n.sendQuickly,
                          onTap: () => currentTab.value = _TabType.image,
                          selected: currentTab.value == _TabType.image,
                          show: hasMedia,
                        ),
                        _Tab(
                          assetName: Resources.assetsImagesFilePreviewFilesSvg,
                          tooltip: context.l10n.sendWithoutCompression,
                          onTap: () => currentTab.value = _TabType.files,
                          selected: currentTab.value == _TabType.files,
                        ),
                        _Tab(
                          assetName: Resources.assetsImagesFilePreviewZipSvg,
                          tooltip: context.l10n.sendArchived,
                          onTap: () => currentTab.value = _TabType.zip,
                          selected: currentTab.value == _TabType.zip,
                          show: showZipTab,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: _FileListViewportProvider(
                      child: IndexedStack(
                        sizing: StackFit.expand,
                        index: currentTab.value == _TabType.zip ? 1 : 0,
                        children: [
                          _FileInputOverlay(
                            onFileAdded: addFile,
                            child: _AnimatedListBuilder(
                                files: files.value,
                                onFileAdded: onFileAddedStream.stream,
                                onFileDeleted: onFileRemovedStream.stream,
                                builder: (context, file, animation) =>
                                    _AnimatedFileTile(
                                      key: ValueKey(file),
                                      file: file,
                                      animation: animation,
                                      onDelete: removeFile,
                                      showBigImage: showAsBigImage,
                                      onImageEdited: (file, image) async {
                                        final index = files.value.indexOf(file);
                                        if (index == -1) {
                                          e('failed to found file');
                                          return;
                                        }
                                        final list = files.value.toList();
                                        final newFile = File(image.imagePath);
                                        list[index] =
                                            _File.image(newFile, image);
                                        files.value = list;
                                      },
                                    )),
                          ),
                          _PageZip(zipPasswordController),
                        ],
                      ),
                    ),
                  ),
                  _BottomActionWidget(
                    send: send,
                    imageCaptionController: imageCaptionController,
                    showImageCaption: isOneImage,
                  ),
                ],
              ),
              const Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: EdgeInsets.all(22),
                  child: MixinCloseButton(),
                ),
              )
            ],
          )),
    );
  }
}

class _BottomActionWidget extends StatelessWidget {
  const _BottomActionWidget({
    required this.send,
    required this.imageCaptionController,
    required this.showImageCaption,
  });

  final Future<void> Function(bool silent) send;
  final TextEditingController imageCaptionController;
  final bool showImageCaption;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: double.infinity),
        child: Column(
          children: [
            const SizedBox(height: 16),
            if (showImageCaption)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: ImageCaptionInputWidget(
                  textEditingController: imageCaptionController,
                ),
              ),
            const SizedBox(height: 16),
            CustomContextMenuWidget(
              desktopMenuWidgetBuilder: CustomDesktopMenuWidgetBuilder(),
              menuProvider: (_) => Menu(children: [
                MenuAction(
                  image: MenuImage.icon(IconFonts.mute),
                  title: context.l10n.sendWithoutSound,
                  callback: () => send(true),
                )
              ]),
              child: ElevatedButton(
                onPressed: () => send(false),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.only(
                      left: 32, top: 18, bottom: 18, right: 32),
                  backgroundColor: context.theme.accent,
                ),
                child: Text(
                  context.l10n.send.toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.enterToSend,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
}

class _FileListViewportProvider extends StatelessWidget {
  const _FileListViewportProvider({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => _FileListViewport(
          height: constraints.maxHeight,
          child: child,
        ),
      );
}

class _FileListViewport extends StatelessWidget {
  const _FileListViewport({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) => child;
}

Future<String> _archiveFiles(
    (String zipFileFolder, String password, List<String> files) params) async {
  final (zipFileFolder, password, files) = params;
  assert(files.isNotEmpty, 'files should not be empty');
  final outPath = path.join(zipFileFolder,
      'mixin_archive_${DateTime.now().millisecondsSinceEpoch}.zip');
  final encoder = ZipFileEncoder(password: password.isEmpty ? null : password)
    ..create(outPath);
  for (final filePath in files) {
    await encoder.addFile(File(filePath), path.basename(filePath));
  }
  await encoder.close();
  return outPath;
}

Future<void> _sendFile(
  BuildContext context,
  _File file,
  String? quoteMessageId, {
  required bool silent,
  required bool compress,
  String? imageCaption,
}) async {
  final conversationItem = context.providerContainer.read(conversationProvider);
  if (conversationItem == null) return;
  final accountServer = context.accountServer;
  final xFile = file.file;
  switch (file) {
    case _ImageFile():
      return accountServer.sendImageMessage(
        conversationItem.encryptCategory,
        file: xFile,
        conversationId: conversationItem.conversationId,
        recipientId: conversationItem.userId,
        quoteMessageId: quoteMessageId,
        silent: silent,
        compress: compress,
        caption: imageCaption,
      );
    case _NormalFile():
      await accountServer.sendDataMessage(
        xFile,
        conversationItem.encryptCategory,
        conversationId: conversationItem.conversationId,
        recipientId: conversationItem.userId,
        quoteMessageId: quoteMessageId,
        silent: silent,
      );
    case _VideoFile():
      final metadata = await file._metadataCompleter.future;
      final blurHash = await file._blurHashCompleter.future;
      await accountServer.sendVideoMessage(
        xFile,
        conversationItem.encryptCategory,
        conversationId: conversationItem.conversationId,
        recipientId: conversationItem.userId,
        quoteMessageId: quoteMessageId,
        silent: silent,
        mediaHeight: metadata.height,
        mediaWidth: metadata.width,
        mediaDuration: metadata.duration.toString(),
        thumbImage: blurHash,
      );
  }
}

class _AnimatedFileTile extends HookConsumerWidget {
  const _AnimatedFileTile({
    required this.file,
    required this.animation,
    required this.showBigImage,
    super.key,
    this.onDelete,
    this.onImageEdited,
  });

  final _File file;
  final Animation<double> animation;

  final void Function(_File)? onDelete;

  final _ImageEditedCallback? onImageEdited;

  final ValueNotifier<bool> showBigImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final big = useValueListenable(showBigImage);

    final normalItem = _TileNormalFile(
      file: file,
      onDelete: () => onDelete?.call(file),
    );

    final Widget child = switch (file) {
      _ImageFile() => AnimatedCrossFade(
          firstChild: _TileBigImage(
            file: file as _ImageFile,
            onDelete: () => onDelete?.call(file),
            onEdited: (file, snapshot) => onImageEdited?.call(file, snapshot),
          ),
          secondChild: normalItem,
          crossFadeState:
              big ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstCurve: Curves.easeInOut,
          secondCurve: Curves.easeInOut,
          sizeCurve: Curves.easeInOut,
          duration: const Duration(milliseconds: 300),
        ),
      _VideoFile() => AnimatedCrossFade(
          firstChild: _TileBigVideo(
            file: file as _VideoFile,
            onDelete: () => onDelete?.call(file),
          ),
          secondChild: normalItem,
          crossFadeState:
              big ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstCurve: Curves.easeInOut,
          secondCurve: Curves.easeInOut,
          sizeCurve: Curves.easeInOut,
          duration: const Duration(milliseconds: 300),
        ),
      _NormalFile() => normalItem,
    };
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: child,
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.assetName,
    required this.tooltip,
    required this.onTap,
    this.selected = false,
    this.show = true,
  });

  final String assetName;

  final String tooltip;

  final VoidCallback onTap;

  final bool selected;

  final bool show;

  @override
  Widget build(BuildContext context) => AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: show
            ? GestureDetector(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Tooltip(
                      message: tooltip,
                      textStyle: const TextStyle(
                        color: Colors.white,
                      ),
                      child: SvgPicture.asset(
                        assetName,
                        colorFilter: ColorFilter.mode(
                          selected ? context.theme.accent : context.theme.icon,
                          BlendMode.srcIn,
                        ),
                        width: 24,
                        height: 24,
                      )),
                ),
              )
            : const SizedBox(),
      );
}

class _PageZip extends StatelessWidget {
  const _PageZip(this.zipPasswordController);

  final TextEditingController zipPasswordController;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 30),
              const _FileIcon(extension: 'ZIP'),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _kDefaultArchiveName,
                      style: TextStyle(
                        color: context.theme.text,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.archivedFolder,
                      style: TextStyle(
                        color: context.theme.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 30),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: SizedBox(
              width: 300,
              child: _ZipPasswordInputEditText(
                controller: zipPasswordController,
              ),
            ),
          ),
        ],
      );
}

class _ZipPasswordInputEditText extends HookWidget {
  const _ZipPasswordInputEditText({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();

    final hasText = useListenable(controller).text.isNotEmpty;

    final obscureText = useState(true);

    return InteractiveDecoratedBox(
      decoration: ShapeDecoration(
        color: context.dynamicColor(
          const Color.fromRGBO(245, 247, 250, 1),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
        ),
        shape: const StadiumBorder(),
      ),
      cursor: SystemMouseCursors.text,
      onTap: focusNode.requestFocus,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 36,
          child: Row(
            children: [
              SvgPicture.asset(
                Resources.assetsImagesLockSvg,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  hasText ? context.theme.text : context.theme.secondaryText,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  focusNode: focusNode,
                  autofocus: true,
                  controller: controller,
                  style: TextStyle(
                    color: context.theme.text,
                    fontSize: 14,
                  ),
                  obscureText: obscureText.value,
                  scrollPadding: EdgeInsets.zero,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    border: InputBorder.none,
                    fillColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    contentPadding: EdgeInsets.zero,
                    hintText: context.l10n.encryptZipFileWithPassword,
                    hintStyle: TextStyle(
                      color: context.theme.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      kDefaultTextInputLimit,
                    ),
                  ],
                  contextMenuBuilder: (context, state) =>
                      MixinAdaptiveSelectionToolbar(editableTextState: state),
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    obscureText.value = !obscureText.value;
                  },
                  child: Icon(
                    obscureText.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: hasText
                        ? context.theme.text
                        : context.theme.secondaryText,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedListBuilder extends HookConsumerWidget {
  const _AnimatedListBuilder({
    required this.files,
    required this.onFileAdded,
    required this.onFileDeleted,
    required this.builder,
  });

  final List<_File> files;
  final Stream<int> onFileAdded;
  final Stream<(int, _File)> onFileDeleted;

  final Widget Function(BuildContext, _File, Animation<double>) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animatedListKey = useMemoized(() => GlobalKey<AnimatedListState>(
          debugLabel: 'file_preview_dialog',
        ));
    final controller = useScrollController();
    useEffect(() {
      final subscription = onFileAdded.listen((event) {
        animatedListKey.currentState?.insertItem(event);
        // auto scroll to bottom.
        scheduleMicrotask(() async {
          await Future.delayed(350.milliseconds);
          await controller.animateTo(
            controller.position.maxScrollExtent,
            duration: 200.milliseconds,
            curve: Curves.fastOutSlowIn,
          );
        });
      });
      return subscription.cancel;
    }, [onFileAdded]);
    useEffect(() {
      final subscription = onFileDeleted.listen((event) {
        animatedListKey.currentState?.removeItem(
          event.$1,
          (context, animation) => builder(context, event.$2, animation),
        );
      });
      return subscription.cancel;
    }, [onFileDeleted]);
    return AnimatedList(
      controller: controller,
      initialItemCount: files.length,
      key: animatedListKey,
      itemBuilder: (context, index, animation) =>
          builder(context, files[index], animation),
    );
  }
}

final _videoControllerProvider = ChangeNotifierProvider.autoDispose
    .family<VideoPlayerController, _VideoFile>(
  (ref, file) => VideoPlayerController.file(File(file.path))
    ..initialize()
    ..setVolume(0)
    ..setLooping(true),
);

final _videoBlurHashProvider =
    FutureProvider.autoDispose.family<String, _VideoFile>(
  (ref, file) => file._blurHashCompleter.future,
);

class _TileBigVideo extends HookConsumerWidget {
  const _TileBigVideo({
    required this.onDelete,
    required this.file,
  });

  final VoidCallback onDelete;
  final _VideoFile file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller =
        ref.watch(_videoControllerProvider(file).select((value) => value));
    final blurHash = ref.watch(_videoBlurHashProvider(file)).valueOrNull;
    useEffect(() {
      Future(controller.play);
      return () => Future(controller.pause);
    }, [controller]);

    useOnAppLifecycleStateChange((previous, current) {
      if (current != AppLifecycleState.resumed) {
        controller.pause();
      } else {
        controller.play();
      }
    });

    final aspectRatio = ref.watch(_videoControllerProvider(file)
        .select((value) => value.value.aspectRatio));
    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(
                color: Colors.black,
                child: SizedBox.expand(),
              ),
              if (blurHash != null)
                ImageByBlurHashOrBase64(imageData: blurHash),
              Center(
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
              Positioned(
                left: 6,
                top: 6,
                child: _VideoPositionText(file: file),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.28),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )),
                  child: Row(
                    children: [
                      const Spacer(),
                      ActionButton(
                        color: Colors.white,
                        name: Resources.assetsImagesDeleteSvg,
                        padding: const EdgeInsets.all(10),
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoPositionText extends ConsumerWidget {
  const _VideoPositionText({required this.file});

  final _VideoFile file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = ref.watch(_videoControllerProvider(file).select(
      (value) => value.value.duration,
    ));
    final position = ref.watch(_videoControllerProvider(file).select(
      (value) => value.value.position,
    ));
    final left = duration - position;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color.fromRGBO(0, 0, 0, 0.3),
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Text(
          left.asMinutesSeconds,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _TileBigImage extends HookConsumerWidget {
  const _TileBigImage({
    required this.file,
    required this.onDelete,
    required this.onEdited,
  });

  final _ImageFile file;

  final VoidCallback onDelete;

  final _ImageEditedCallback onEdited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewport = context.findAncestorWidgetOfExactType<_FileListViewport>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    (viewport?.height ?? 270) - 30 /* vertical padding */,
                minWidth: 420,
                maxWidth: 420,
              ),
              child: Image(
                image: MixinFileImage(File(file.path)),
                fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
            Container(
              height: 50,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.28),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )),
              child: Row(
                children: [
                  const Spacer(),
                  ActionButton(
                    color: Colors.white,
                    name: Resources.assetsImagesEditImageSvg,
                    padding: const EdgeInsets.all(10),
                    onTap: () async {
                      final snapshot = file.imageEditorSnapshot != null
                          ? await showImageEditor(context,
                              path: file.imageEditorSnapshot!.rawImagePath,
                              snapshot: file.imageEditorSnapshot)
                          : await showImageEditor(context, path: file.path);
                      if (snapshot == null) {
                        return;
                      }
                      onEdited.call(file, snapshot);
                    },
                  ),
                  ActionButton(
                    color: Colors.white,
                    name: Resources.assetsImagesDeleteSvg,
                    padding: const EdgeInsets.all(10),
                    onTap: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileIcon extends StatelessWidget {
  const _FileIcon({required this.extension});

  final String extension;

  @override
  Widget build(BuildContext context) => Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: context.theme.statusBackground,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            extension,
            style: TextStyle(
              fontSize: 16,
              // force light style
              color: lightBrightnessThemeData.secondaryText,
            ),
          ),
        ),
      );
}

final _fileSizeProvider = FutureProvider.autoDispose.family<int, XFile>(
  (ref, file) => file.length(),
);

class _TileNormalFile extends HookConsumerWidget {
  const _TileNormalFile({
    required this.file,
    required this.onDelete,
  });

  final _File file;

  final VoidCallback onDelete;

  static String _getFileExtension(_File file) {
    var extension = '';
    final mimeType = lookupMimeType(file.path);
    // Only show the extension which is valid.
    if (mimeType != null) {
      extension = path.extension(file.path).trim().replaceFirst('.', '');
    }
    return extension.isEmpty ? 'FILE' : extension.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
        children: [
          const SizedBox(width: 30),
          _FileIcon(extension: _getFileExtension(file)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path.basename(file.path).overflow,
                  style: TextStyle(
                    color: context.theme.text,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  filesize(
                      ref.watch(_fileSizeProvider(file.file)).valueOrNull ?? 0,
                      0),
                  style: TextStyle(
                    color: context.theme.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ActionButton(
            color: context.theme.secondaryText,
            name: Resources.assetsImagesDeleteSvg,
            padding: const EdgeInsets.all(10),
            onTap: onDelete,
          ),
          const SizedBox(width: 10),
        ],
      );
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.child,
    required this.onSend,
    required this.onFileAdded,
  });

  final Widget child;
  final VoidCallback onSend;
  final void Function(List<_File>) onFileAdded;

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
        autofocus: true,
        shortcuts: {
          const SingleActivator(LogicalKeyboardKey.enter):
              const _SendFilesIntent(),
          SingleActivator(
            LogicalKeyboardKey.keyV,
            meta: kPlatformIsDarwin,
            control: !kPlatformIsDarwin,
          ): const PasteTextIntent(SelectionChangedCause.keyboard),
        },
        actions: {
          PasteTextIntent: _PasteContextAction(
            context,
            (files) => onFileAdded(
                files.map((file) => _File.auto(file.xFile)).toList()),
          ),
          _SendFilesIntent: CallbackAction<_SendFilesIntent>(onInvoke: (_) {
            onSend();
          }),
        },
        child: child,
      );
}

class _FileInputOverlay extends HookConsumerWidget {
  const _FileInputOverlay({
    required this.child,
    required this.onFileAdded,
  });

  final Widget child;

  final void Function(List<_File>) onFileAdded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragging = useState(false);
    return FocusableActionDetector(
      child: DropTarget(
        onDragEntered: (_) => dragging.value = true,
        onDragExited: (_) => dragging.value = false,
        onDragDone: (details) async {
          final files = details.files.where((xFile) {
            final file = File(xFile.path);
            return file.existsSync();
          });
          if (files.isEmpty) {
            return;
          }
          onFileAdded(files.map(_File.auto).toList());
        },
        child: Stack(
          children: [
            child,
            if (dragging.value) const _ChatDragIndicator(),
          ],
        ),
      ),
    );
  }
}

class _PasteFileOrImageIntent extends Intent {
  const _PasteFileOrImageIntent();
}

class _SendFilesIntent extends Intent {
  const _SendFilesIntent();
}

class _ChatDragIndicator extends StatelessWidget {
  const _ChatDragIndicator();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: context.theme.popUp),
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: context.theme.listSelected,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              border: DashPathBorder.all(
                borderSide: BorderSide(
                  color: context.theme.accent,
                ),
                dashArray: CircularIntervalList([4, 4]),
              )),
          child: Center(
            child: Text(
              context.l10n.addFile,
              style: TextStyle(
                fontSize: 14,
                color: context.theme.text,
              ),
            ),
          ),
        ),
      );
}

class _PasteContextAction extends Action<PasteTextIntent> {
  _PasteContextAction(this.context, this.onPasteFiles);

  final BuildContext context;
  final void Function(Iterable<File> files) onPasteFiles;

  @override
  Object? invoke(PasteTextIntent intent) {
    final callingAction = this.callingAction;
    scheduleMicrotask(() async {
      final files = await getClipboardFiles();
      if (files.isNotEmpty) {
        onPasteFiles(files);
      } else if (callingAction != null) {
        callingAction.invoke(intent);
      }
    });
  }
}
