import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:archive/archive_io.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mime/mime.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../../../account/account_server.dart';
import '../../../constants/brightness_theme_data.dart';
import '../../../constants/resources.dart';
import '../../../generated/l10n.dart';
import '../../../utils/file.dart';
import '../../../utils/load_balancer_utils.dart';
import '../../../utils/platform.dart';
import '../../../utils/string_extension.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/brightness_observer.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/dash_path_border.dart';
import '../../../widgets/dialog.dart';
import '../bloc/conversation_cubit.dart';

Future<void> showFilesPreviewDialog(
    BuildContext context, List<XFile> files) async {
  await showMixinDialog(
    context: context,
    child: _FilesPreviewDialog(
      initialFiles: await Future.wait(files.map(
        (e) async => _File(e, await e.length()),
      )),
    ),
  );
}

/// We need this view object to keep the value of file#length.
class _File {
  _File(this.file, this.length);

  static Future<_File> createFromPath(String path) {
    final file = File(path);
    return createFromFile(file);
  }

  static Future<_File> createFromFile(File file) async =>
      _File(file.xFile, await file.length());

  final XFile file;

  String get path => file.path;

  String? get mimeType => file.mimeType;

  final int length;

  bool get isImage => file.isImage;
}

typedef _FileDeleteCallback = void Function(_File);
typedef _FileAddCallback = void Function(List<_File>);

const _kDefaultArchiveName = 'Archive.zip';

enum _TabType { image, files, zip }

class _FilesPreviewDialog extends HookWidget {
  const _FilesPreviewDialog({
    Key? key,
    required this.initialFiles,
  }) : super(key: key);

  final List<_File> initialFiles;

  @override
  Widget build(BuildContext context) {
    final files = useState(initialFiles);

    final hasImage = useMemoized(
      () => files.value.indexWhere((e) => e.isImage) != -1,
      [identityHashCode(files.value)],
    );

    final showZipTab = files.value.length > 1;

    final currentTab = useState(_TabType.files);

    final onFileAddedStream = useStreamController<int>();
    final onFileRemovedStream = useStreamController<Tuple2<int, _File>>();

    void removeFile(_File file) {
      final index = files.value.indexOf(file);
      files.value = (files.value..removeAt(index)).toList();
      onFileRemovedStream.add(Tuple2(index, file));
      if (files.value.isEmpty) {
        Navigator.pop(context);
      }
    }

    final previousTab = usePrevious(currentTab.value);

    useEffect(() {
      if (previousTab == null && hasImage) {
        currentTab.value = _TabType.image;
      } else if (previousTab == null && !hasImage) {
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
                          tooltip: Localization.of(context).sendQuick,
                          onTap: () => currentTab.value = _TabType.image,
                          selected: currentTab.value == _TabType.image,
                          show: hasImage,
                        ),
                        _Tab(
                          assetName: Resources.assetsImagesFilePreviewFilesSvg,
                          tooltip:
                              Localization.of(context).sendWithoutCompression,
                          onTap: () => currentTab.value = _TabType.files,
                          selected: currentTab.value == _TabType.files,
                        ),
                        _Tab(
                          assetName: Resources.assetsImagesFilePreviewZipSvg,
                          tooltip: Localization.of(context).sendArchived,
                          onTap: () => currentTab.value = _TabType.zip,
                          selected: currentTab.value == _TabType.zip,
                          show: showZipTab,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: _FileInputOverlay(
                      onFileAdded: (fileAdded) {
                        final currentFiles =
                            files.value.map((e) => e.path).toSet();
                        fileAdded
                            .removeWhere((e) => currentFiles.contains(e.path));
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
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (currentTab.value != _TabType.zip) {
                          for (final file in files.value) {
                            unawaited(_sendFile(context, file));
                          }
                          Navigator.pop(context);
                        } else {
                          final zipFilePath =
                              await runLoadBalancer(_archiveFiles, [
                            (await getTemporaryDirectory()).path,
                            ...files.value.map((e) => e.path),
                          ]);
                          unawaited(_sendFile(
                            context,
                            await _File.createFromPath(zipFilePath),
                          ));
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.only(
                            left: 32, top: 18, bottom: 18, right: 32),
                      ),
                      child: Text(Localization.of(context).send.toUpperCase()),
                    ),
                  ),
                  const SizedBox(height: 32),
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

Future<String> _archiveFiles(List<String> paths) async {
  assert(paths.length > 1, 'paths[0] should be temp file dir');
  final outPath = path.join(
      paths[0], 'mixin_archive_${DateTime.now().millisecondsSinceEpoch}.zip');
  final encoder = ZipFileEncoder()..create(outPath);
  paths.removeAt(0);
  for (final filePath in paths) {
    encoder.addFile(File(filePath), path.basename(filePath));
  }
  encoder.close();
  return outPath;
}

Future<void> _sendFile(BuildContext context, _File file) async {
  final conversationItem = context.read<ConversationCubit>().state;
  if (conversationItem == null) return;
  final xFile = file.file;
  if (xFile.isImage) {
    return Provider.of<AccountServer>(context, listen: false).sendImageMessage(
      conversationItem.isPlainConversation,
      file: xFile,
      conversationId: conversationItem.conversationId,
      recipientId: conversationItem.userId,
    );
  } else if (xFile.isVideo) {
    return Provider.of<AccountServer>(context, listen: false).sendVideoMessage(
      xFile,
      conversationItem.isPlainConversation,
      conversationId: conversationItem.conversationId,
      recipientId: conversationItem.userId,
    );
  }
  await Provider.of<AccountServer>(context, listen: false).sendDataMessage(
    xFile,
    conversationItem.isPlainConversation,
    conversationId: conversationItem.conversationId,
    recipientId: conversationItem.userId,
  );
}

class _AnimatedFileTile extends HookWidget {
  const _AnimatedFileTile({
    Key? key,
    required this.file,
    required this.animation,
    this.onDelete,
    required this.showBigImage,
  }) : super(key: key);

  final _File file;
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
                  duration: const Duration(milliseconds: 300))
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
    required this.tooltip,
    required this.onTap,
    this.selected = false,
    this.show = true,
  }) : super(key: key);

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
                        color: selected
                            ? BrightnessData.themeOf(context).accent
                            : BrightnessData.themeOf(context).icon,
                        width: 24,
                        height: 24,
                      )),
                ),
              )
            : const SizedBox(),
      );
}

class _PageZip extends StatelessWidget {
  const _PageZip({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                        color: BrightnessData.themeOf(context).text,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Localization.of(context).archivedFolder,
                      style: TextStyle(
                        color: BrightnessData.themeOf(context).secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 30),
            ],
          )
        ],
      );
}

typedef FileItemBuilder = Widget Function(
    BuildContext, _File, Animation<double>);

class _AnimatedListBuilder extends HookWidget {
  const _AnimatedListBuilder({
    Key? key,
    required this.files,
    required this.onFileAdded,
    required this.onFileDeleted,
    required this.builder,
  }) : super(key: key);

  final List<_File> files;
  final Stream<int> onFileAdded;
  final Stream<Tuple2<int, _File>> onFileDeleted;

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

  final _File file;

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    assert(file.isImage);

    final showDelete = useState(false);

    return MouseRegion(
      onEnter: (_) => showDelete.value = true,
      onExit: (_) => showDelete.value = false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 420,
                  minWidth: 420,
                  maxWidth: 420,
                ),
                child: Image.file(
                  File(file.path),
                  fit: BoxFit.fitWidth,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
              AnimatedCrossFade(
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
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _FileIcon extends StatelessWidget {
  const _FileIcon({Key? key, required this.extension}) : super(key: key);

  final String extension;

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

class _TileNormalFile extends HookWidget {
  const _TileNormalFile({
    Key? key,
    required this.file,
    required this.onDelete,
  }) : super(key: key);

  final _File file;

  final VoidCallback onDelete;

  static String _getFileExtension(_File file) {
    var extension = 'FILE';
    final fileName = path.basename(file.path);
    if (fileName.isNotEmpty) {
      final _lookupMimeType = lookupMimeType(fileName);
      if (_lookupMimeType != null) {
        extension = extensionFromMime(_lookupMimeType).toUpperCase();
      }
    }
    return extension;
  }

  @override
  Widget build(BuildContext context) {
    final showDelete = useState(false);
    return MouseRegion(
      onEnter: (_) => showDelete.value = true,
      onExit: (_) => showDelete.value = false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                    color: BrightnessData.themeOf(context).text,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  filesize(file.length, 0),
                  style: TextStyle(
                    color: BrightnessData.themeOf(context).secondaryText,
                    fontSize: 14,
                  ),
                ),
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

class _FileInputOverlay extends HookWidget {
  const _FileInputOverlay({
    Key? key,
    required this.child,
    required this.onFileAdded,
  }) : super(key: key);

  final Widget child;

  final _FileAddCallback onFileAdded;

  @override
  Widget build(BuildContext context) {
    final dragging = useState(false);
    return FocusableActionDetector(
      autofocus: true,
      shortcuts: {
        SingleActivator(
          LogicalKeyboardKey.keyV,
          meta: kPlatformIsDarwin,
          control: !kPlatformIsDarwin,
        ): const _PasteFileOrImageIntent(),
      },
      actions: {
        _PasteFileOrImageIntent: CallbackAction<Intent>(onInvoke: (_) async {
          final uri = await Pasteboard.uri;
          if (uri != null) {
            final file = File(uri.toFilePath(windows: Platform.isWindows));
            if (!await file.exists()) return;
            onFileAdded([await _File.createFromFile(file)]);
          } else {
            final bytes = await Pasteboard.image;
            if (bytes == null) return;
            final file = await saveBytesToTempFile(
                bytes, 'mixin_paste_board_image', '.png');
            if (file == null) return;
            onFileAdded([await _File.createFromFile(file)]);
          }
        })
      },
      child: DropTarget(
        onDragEntered: () => dragging.value = true,
        onDragExited: () => dragging.value = false,
        onDragDone: (urls) async {
          final files = <_File>[];
          for (final uri in urls) {
            final file = File(uri.toFilePath(windows: Platform.isWindows));
            if (!await file.exists()) {
              continue;
            }
            files.add(await _File.createFromFile(file));
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
      ),
    );
  }
}

class _PasteFileOrImageIntent extends Intent {
  const _PasteFileOrImageIntent();
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
