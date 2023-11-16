import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../../constants/brightness_theme_data.dart';
import '../../../constants/icon_fonts.dart';
import '../../../constants/resources.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/load_balancer_utils.dart';
import '../../../utils/logger.dart';
import '../../../utils/platform.dart';
import '../../../utils/system/clipboard.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/cache_image.dart';
import '../../../widgets/dash_path_border.dart';
import '../../../widgets/dialog.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/quote_message_provider.dart';
import 'image_editor.dart';

Future<void> showFilesPreviewDialog(
    BuildContext context, List<XFile> files) async {
  await showMixinDialog(
    context: context,
    child: _FilesPreviewDialog(
      initialFiles: await Future.wait(files.map(
        (e) async => _File.createFromXFile(e),
      )),
    ),
  );
}

/// We need this view object to keep the value of file#length.
class _File {
  _File._(this.file, this.length, this.isImage, this.imageEditorSnapshot);

  static Future<_File> createFromPath(String path) {
    final file = File(path);
    return createFromFile(file);
  }

  static Future<_File> createFromFile(File file,
          [ImageEditorSnapshot? imageEditorSnapshot]) =>
      _File.createFromXFile(file.xFile, imageEditorSnapshot);

  static Future<_File> createFromXFile(XFile file,
          [ImageEditorSnapshot? imageEditorSnapshot]) async =>
      _File._(
        file,
        await file.length(),
        file.isImage,
        imageEditorSnapshot,
      );

  final XFile file;

  final ImageEditorSnapshot? imageEditorSnapshot;
  final bool isImage;
  final int length;

  String get path => file.path;

  String? get mimeType => file.mimeType;
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

    final hasImage = useMemoized(
      () => files.value.indexWhere((e) => e.isImage) != -1,
      [identityHashCode(files.value)],
    );

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
      showAsBigImage.value = hasImage && currentTab.value == _TabType.image;
    }, [hasImage, currentTab.value]);

    Future<void> send(bool silent) async {
      if (currentTab.value != _TabType.zip) {
        for (final file in files.value) {
          unawaited(_sendFile(
            context,
            file,
            quoteMessageCubit.state?.messageId,
            silent: silent,
          ));
        }
        quoteMessageCubit.state = null;
        Navigator.pop(context);
      } else {
        final zipFilePath = await runLoadBalancer(_archiveFiles, [
          (await getTemporaryDirectory()).path,
          ...files.value.map((e) => e.path),
        ]);
        unawaited(_sendFile(
          context,
          await _File.createFromPath(zipFilePath),
          quoteMessageCubit.state?.messageId,
          silent: silent,
        ));
        quoteMessageCubit.state = null;
        Navigator.pop(context);
      }
    }

    return SizedBox(
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
                        show: hasImage,
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
                    child: _FileInputOverlay(
                      onSend: () => send(false),
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
                                    onImageEdited: (file, image) async {
                                      final index = files.value.indexOf(file);
                                      if (index == -1) {
                                        e('failed to found file');
                                        return;
                                      }
                                      final list = files.value.toList();
                                      final newFile = File(image.imagePath);
                                      list[index] = await _File.createFromFile(
                                          newFile, image);
                                      files.value = list;
                                    },
                                  )),
                          const _PageZip(),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Align(
                  child: ContextMenuWidget(
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
                ),
                const SizedBox(height: 24),
                Align(
                  child: Text(
                    context.l10n.enterToSend,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
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
        ));
  }
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

Future<String> _archiveFiles(List<String> paths) async {
  assert(paths.length > 1, 'paths[0] should be temp file dir');
  final outPath = path.join(paths.first,
      'mixin_archive_${DateTime.now().millisecondsSinceEpoch}.zip');
  final encoder = ZipFileEncoder()..create(outPath);
  paths.removeAt(0);
  for (final filePath in paths) {
    await encoder.addFile(File(filePath), path.basename(filePath));
  }
  encoder.close();
  return outPath;
}

Future<void> _sendFile(
  BuildContext context,
  _File file,
  String? quoteMessageId, {
  required bool silent,
}) async {
  final conversationItem = context.providerContainer.read(conversationProvider);
  if (conversationItem == null) return;
  final xFile = file.file;
  if (file.isImage) {
    return context.accountServer.sendImageMessage(
      conversationItem.encryptCategory,
      file: xFile,
      conversationId: conversationItem.conversationId,
      recipientId: conversationItem.userId,
      quoteMessageId: quoteMessageId,
      silent: silent,
    );
  } else if (xFile.isVideo) {
    return context.accountServer.sendVideoMessage(
      xFile,
      conversationItem.encryptCategory,
      conversationId: conversationItem.conversationId,
      recipientId: conversationItem.userId,
      quoteMessageId: quoteMessageId,
      silent: silent,
    );
  }
  await context.accountServer.sendDataMessage(
    xFile,
    conversationItem.encryptCategory,
    conversationId: conversationItem.conversationId,
    recipientId: conversationItem.userId,
    quoteMessageId: quoteMessageId,
    silent: silent,
  );
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
                    onEdited: (file, snapshot) =>
                        onImageEdited?.call(file, snapshot),
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
  const _PageZip();

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
          )
        ],
      );
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

class _TileBigImage extends HookConsumerWidget {
  const _TileBigImage({
    required this.file,
    required this.onDelete,
    required this.onEdited,
  });

  final _File file;

  final VoidCallback onDelete;

  final _ImageEditedCallback onEdited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(file.isImage);
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
                  filesize(file.length, 0),
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

class _FileInputOverlay extends HookConsumerWidget {
  const _FileInputOverlay({
    required this.child,
    required this.onFileAdded,
    required this.onSend,
  });

  final Widget child;

  final void Function(List<_File>) onFileAdded;
  final void Function() onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragging = useState(false);
    return FocusableActionDetector(
      autofocus: true,
      shortcuts: {
        SingleActivator(
          LogicalKeyboardKey.keyV,
          meta: kPlatformIsDarwin,
          control: !kPlatformIsDarwin,
        ): const _PasteFileOrImageIntent(),
        const SingleActivator(
          LogicalKeyboardKey.enter,
        ): const _SendFilesIntent(),
      },
      actions: {
        _PasteFileOrImageIntent: CallbackAction<Intent>(onInvoke: (_) async {
          final files = await getClipboardFiles();
          onFileAdded(await Future.wait(files.map(_File.createFromFile)));
        }),
        _SendFilesIntent: CallbackAction<Intent>(onInvoke: (_) {
          onSend();
        }),
      },
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
          onFileAdded(await Future.wait(
            files.map((file) async => _File.createFromXFile(file)),
          ));
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
