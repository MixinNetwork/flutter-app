import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/utils/file.dart';
import 'package:flutter_app/utils/string_extension.dart';
import 'package:flutter_app/widgets/action_button.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/dash_path_border.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:tuple/tuple.dart';

import '../../../widgets/dialog.dart';

Future<void> showFilesPreviewDialog(
    BuildContext context, List<XFile> files) async {
  await showMixinDialog(
    context: context,
    child: _FilesPreviewDialog(
      initialFiles: files,
    ),
  );
}

typedef _FileDeleteCallback = void Function(XFile);
typedef _FileAddCallback = void Function(List<XFile>);

enum _TabType { image, files, zip }

class _FilesPreviewDialog extends HookWidget {
  const _FilesPreviewDialog({Key? key, required this.initialFiles})
      : super(key: key);

  final List<XFile> initialFiles;

  @override
  Widget build(BuildContext context) {
    final files = useState(initialFiles);

    final hasImage = useMemoized(
      () => files.value.indexWhere((e) => e.isImage) != -1,
      [identityHashCode(files.value)],
    );

    final showZipTab = files.value.length > 1;

    final currentTab = useState(_TabType.files);

    final onFileAddedStream =
        useMemoized(() => StreamController<int>.broadcast());
    final onFileRemovedStream =
        useMemoized(() => StreamController<Tuple2<int, XFile>>.broadcast());

    void removeFile(XFile file) {
      final index = files.value.indexOf(file);
      files.value = (files.value..removeAt(index)).toList();
      onFileRemovedStream.add(Tuple2(index, file));
      if (files.value.isEmpty) {
        Navigator.pop(context);
      }
    }

    final previousIndex = usePrevious(currentTab.value);

    useEffect(() {
      if (previousIndex == null) {
        if (hasImage) {
          currentTab.value = _TabType.image;
          return;
        }
        currentTab.value = _TabType.files;
      } else if (!hasImage && currentTab.value == _TabType.image) {
        currentTab.value = _TabType.files;
      } else if (!showZipTab && currentTab.value == _TabType.zip) {
        currentTab.value = _TabType.files;
      }
    }, [hasImage, showZipTab]);

    final showAsBigImage = useState(hasImage);

    useEffect(() {
      if (hasImage && currentTab.value == _TabType.image) {
        showAsBigImage.value = true;
      } else {
        showAsBigImage.value = false;
      }
    }, [hasImage, currentTab.value]);

    return Material(
      child: Container(
          width: 480,
          height: 600,
          color: BrightnessData.themeOf(context).popUp,
          child: Column(
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
                      onTap: () => currentTab.value = _TabType.image,
                      selected: currentTab.value == _TabType.image,
                      show: hasImage,
                    ),
                    _Tab(
                      assetName: Resources.assetsImagesFilePreviewFilesSvg,
                      onTap: () => currentTab.value = _TabType.files,
                      selected: currentTab.value == _TabType.files,
                    ),
                    _Tab(
                      assetName: Resources.assetsImagesFilePreviewZipSvg,
                      onTap: () => currentTab.value = _TabType.zip,
                      selected: currentTab.value == _TabType.zip,
                      show: showZipTab,
                    )
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: _ChatDropOverlay(
                  onFileAdded: (fileAdded) {
                    final currentFiles = files.value.map((e) => e.path).toSet();
                    fileAdded.removeWhere((e) => currentFiles.contains(e.path));
                    files.value = (files.value..addAll(fileAdded)).toList();
                    for (var i = 0; i < fileAdded.length; i++) {
                      onFileAddedStream.add(currentFiles.length + i);
                    }
                  },
                  child: IndexedStack(
                    sizing: StackFit.expand,
                    index: currentTab.value == _TabType.zip ? 1 : 0,
                    children: [
                      _AnimatedListBuilder(
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
                              )),
                      const _PageZip(),
                    ],
                  ),
                ),
              ),
            ],
          )),
    );
  }
}

class _AnimatedFileTile extends HookWidget {
  const _AnimatedFileTile({
    Key? key,
    required this.file,
    required this.animation,
    this.onDelete,
    required this.showBigImage,
  }) : super(key: key);

  final XFile file;
  final Animation<double> animation;

  final _FileDeleteCallback? onDelete;

  final ValueNotifier<bool> showBigImage;

  @override
  Widget build(BuildContext context) {
    final big = useValueListenable(showBigImage);
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: file.isImage
              ? AnimatedCrossFade(
                  firstChild: _TileBigImage(
                    file: file,
                    onDelete: () => onDelete?.call(file),
                  ),
                  secondChild: _TileNormalFile(
                    file: file,
                    onDelete: () => onDelete?.call(file),
                  ),
                  crossFadeState: big
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstCurve: Curves.easeInOut,
                  secondCurve: Curves.easeInOut,
                  sizeCurve: Curves.easeInOut,
                  duration: const Duration(milliseconds: 150))
              : _TileNormalFile(
                  file: file,
                  onDelete: () => onDelete?.call(file),
                ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    Key? key,
    required this.assetName,
    required this.onTap,
    this.selected = false,
    this.show = true,
  }) : super(key: key);

  final String assetName;

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
                  child: SvgPicture.asset(
                    assetName,
                    color: selected
                        ? BrightnessData.themeOf(context).accent
                        : BrightnessData.themeOf(context).icon,
                    width: 24,
                    height: 24,
                  ),
                ),
              )
            : const SizedBox(),
      );
}

class _PageZip extends StatelessWidget {
  const _PageZip({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

typedef FileItemBuilder = Widget Function(
    BuildContext, XFile, Animation<double>);

class _AnimatedListBuilder extends HookWidget {
  const _AnimatedListBuilder({
    Key? key,
    required this.files,
    required this.onFileAdded,
    required this.onFileDeleted,
    required this.builder,
  }) : super(key: key);

  final List<XFile> files;
  final Stream<int> onFileAdded;
  final Stream<Tuple2<int, XFile>> onFileDeleted;

  final FileItemBuilder builder;

  @override
  Widget build(BuildContext context) {
    final animatedListKey = useMemoized(() => GlobalKey<AnimatedListState>(
          debugLabel: 'file_preview_dialog',
        ));
    useEffect(() {
      final subscription = onFileAdded.listen((event) {
        animatedListKey.currentState?.insertItem(event);
      });
      return subscription.cancel;
    }, [onFileAdded]);
    useEffect(() {
      final subscription = onFileDeleted.listen((event) {
        animatedListKey.currentState?.removeItem(
          event.item1,
          (context, animation) => builder(context, event.item2, animation),
        );
      });
      return subscription.cancel;
    }, [onFileDeleted]);
    return AnimatedList(
      initialItemCount: files.length,
      key: animatedListKey,
      itemBuilder: (context, index, animation) =>
          builder(context, files[index], animation),
    );
  }
}

class _TileBigImage extends HookWidget {
  const _TileBigImage({
    Key? key,
    required this.file,
    required this.onDelete,
  }) : super(key: key);

  final XFile file;

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    assert(file.isImage);

    final showDelete = useState(false);

    return MouseRegion(
      onEnter: (_) => showDelete.value = true,
      onExit: (_) => showDelete.value = false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(file.path),
              fit: BoxFit.fitWidth,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedCrossFade(
                firstChild: const SizedBox(),
                alignment: Alignment.center,
                secondChild: Container(
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
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: ActionButton(
                      color: Colors.white,
                      name: Resources.assetsImagesDeleteSvg,
                      padding: const EdgeInsets.all(10.0),
                      size: 24,
                      onTap: onDelete,
                    ),
                  ),
                ),
                crossFadeState: !showDelete.value
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 150),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _FileIcon extends StatelessWidget {
  const _FileIcon({Key? key, required this.file}) : super(key: key);

  final XFile file;

  String _getFileExtension() {
    var extension = path.extension(file.path).toUpperCase();
    if (extension.isNotEmpty) {
      return extension.substring(1);
    }
    extension = extensionFromMime(file.mimeType!).toUpperCase();
    if (extension.isNotEmpty) {
      return extension;
    }
    return 'FILE';
  }

  @override
  Widget build(BuildContext context) => Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: BrightnessData.themeOf(context).statusBackground,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            _getFileExtension(),
            style: TextStyle(
              fontSize: 16,
              // force light style
              color: lightBrightnessThemeData.secondaryText,
            ),
          ),
        ),
      );
}

class _TileNormalFile extends HookWidget {
  const _TileNormalFile({
    Key? key,
    required this.file,
    this.enableHorizontalPadding = true,
    required this.onDelete,
  }) : super(key: key);

  final XFile file;

  final bool enableHorizontalPadding;

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final showDelete = useState(false);
    return MouseRegion(
      onEnter: (_) => showDelete.value = true,
      onExit: (_) => showDelete.value = false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (enableHorizontalPadding) const SizedBox(width: 30),
          _FileIcon(file: file),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path.basename(file.path).overflow,
                  style: TextStyle(
                    color: BrightnessData.themeOf(context).text,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FutureBuilder<int>(
                    future: file.length(),
                    builder: (context, length) =>
                        Text(filesize(length.data ?? 0, 0),
                            style: TextStyle(
                              color:
                                  BrightnessData.themeOf(context).secondaryText,
                              fontSize: 14,
                            ))),
              ],
            ),
          ),
          if (showDelete.value)
            ActionButton(
              color: BrightnessData.themeOf(context).secondaryText,
              name: Resources.assetsImagesDeleteSvg,
              padding: const EdgeInsets.all(10.0),
              size: 24,
              onTap: onDelete,
            ),
          if (showDelete.value) const SizedBox(width: 10),
          if (!showDelete.value) const SizedBox(width: 30),
        ],
      ),
    );
  }
}

class _ChatDropOverlay extends HookWidget {
  const _ChatDropOverlay({
    Key? key,
    required this.child,
    required this.onFileAdded,
  }) : super(key: key);

  final Widget child;

  final _FileAddCallback onFileAdded;

  @override
  Widget build(BuildContext context) {
    final dragging = useState(false);
    return DropTarget(
      onDragEntered: () => dragging.value = true,
      onDragExited: () => dragging.value = false,
      onDragDone: (urls) async {
        final files = <XFile>[];
        for (final uri in urls) {
          final file = File(uri.toFilePath(windows: Platform.isWindows));
          if (!await file.exists()) {
            continue;
          }
          files.add(file.xFile);
        }
        if (files.isEmpty) {
          return;
        }
        onFileAdded(files);
      },
      child: Stack(
        children: [
          child,
          if (dragging.value) const _ChatDragIndicator(),
        ],
      ),
    );
  }
}

class _ChatDragIndicator extends StatelessWidget {
  const _ChatDragIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: BrightnessData.themeOf(context).popUp),
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: BrightnessData.themeOf(context).listSelected,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              border: DashPathBorder.all(
                borderSide: BorderSide(
                  color: BrightnessData.themeOf(context).accent,
                ),
                dashArray: CircularIntervalList([4, 4]),
              )),
          child: Center(
            child: Text(
              Localization.of(context).chatDragMoreFile,
              style: TextStyle(
                fontSize: 14,
                color: BrightnessData.themeOf(context).text,
              ),
            ),
          ),
        ),
      );
}
