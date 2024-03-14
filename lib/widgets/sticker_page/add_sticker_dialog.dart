import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../db/dao/sticker_dao.dart';
import '../../db/mixin_database.dart';
import '../../utils/extension/extension.dart';
import '../app_bar.dart';
import '../buttons.dart';
import '../dash_path_border.dart';
import '../dialog.dart';
import '../toast.dart';

Future<void> showAddStickerDialog(
  BuildContext context, {
  required String filepath,
}) async {
  await showMixinDialog(
    context: context,
    child: ConstrainedBox(
      constraints: BoxConstraints.tight(const Size(480, 600)),
      child: _AddStickerDialog(filepath: filepath),
    ),
  );
}

class _AddStickerDialog extends StatelessWidget {
  const _AddStickerDialog({required this.filepath});

  final String filepath;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: MixinAppBar(
          backgroundColor: Colors.transparent,
          title: Text(context.l10n.addSticker),
          leading: const SizedBox(),
          actions: [
            MixinCloseButton(
              onTap: () =>
                  Navigator.maybeOf(context, rootNavigator: true)?.pop(),
            ),
          ],
        ),
        body: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: double.infinity),
          child: Column(
            children: [
              const Spacer(),
              SizedBox.square(
                dimension: 400,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    border: DashPathBorder.all(
                      borderSide: BorderSide(
                        color: context.theme.divider,
                        width: 2,
                      ),
                      dashArray: CircularIntervalList([8, 2]),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Image.file(
                      File(filepath),
                      fit: BoxFit.scaleDown,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: MixinButton(
                  child: Text(context.l10n.save),
                  onTap: () async {
                    final accountServer = context.accountServer;
                    final database = context.database;

                    try {
                      showToastLoading();
                      final bytes = await _imageToSticker(context, filepath);
                      if (bytes == null) {
                        return;
                      }

                      final response =
                          await accountServer.client.accountApi.addSticker(
                        StickerRequest(dataBase64: bytes.base64Encode()),
                      );
                      final sticker = response.data;

                      final personalAlbum = await database.stickerAlbumDao
                          .personalAlbum()
                          .getSingleOrNull();
                      if (personalAlbum == null) {
                        unawaited(
                            context.accountServer.refreshSticker(force: true));
                      } else {
                        await database.mixinDatabase.transaction(() async {
                          await database.stickerDao
                              .insert(sticker.asStickersCompanion);
                          await database.stickerRelationshipDao
                              .insert(StickerRelationship(
                            albumId: personalAlbum.albumId,
                            stickerId: sticker.stickerId,
                          ));
                        });
                      }
                      showToastSuccessful();
                      Navigator.pop(context);
                    } catch (error, stacktrace) {
                      e('($filepath) error: $error\n$stacktrace');
                      showToastFailed(error);
                      return;
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
}

const _kMinFileSize = 1024;
const _kMaxFileSize = 1024 * 1024;

const _kMinSize = 128;
const _kMaxSize = 1024;

Future<Uint8List?> _imageToSticker(
    BuildContext context, String filepath) async {
  final file = File(filepath).xFile;
  if (!file.isStickerSupport) {
    showToastFailed(context.l10n.invalidStickerFormat);
    return null;
  }

  final fileLength = await file.length();
  if (fileLength < _kMinFileSize || fileLength > _kMaxFileSize) {
    showToastFailed(context.l10n.stickerAddInvalidSize);
    return null;
  }

  final buffer = await ui.ImmutableBuffer.fromFilePath(filepath);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);

  d('sticker image size: ${descriptor.width}x${descriptor.height}');

  if (math.min(descriptor.width, descriptor.height) < _kMinSize ||
      math.max(descriptor.width, descriptor.height) > _kMaxSize) {
    showToastFailed(context.l10n.stickerAddInvalidSize);
    return null;
  }
  return file.readAsBytes();
}
