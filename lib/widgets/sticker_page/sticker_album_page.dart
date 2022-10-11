import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../db/mixin_database.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../app_bar.dart';
import '../buttons.dart';
import '../dialog.dart';
import 'sticker_item.dart';
import 'sticker_store.dart';

class StickerAlbumPage extends HookWidget {
  const StickerAlbumPage({
    super.key,
    required this.albumId,
    this.album,
    this.stickers,
  });

  final StickerAlbum? album;
  final List<Sticker>? stickers;
  final String albumId;

  @override
  Widget build(BuildContext context) {
    final album = useMemoizedStream(
          () => context.database.stickerAlbumDao
              .album(albumId)
              .watchSingleThrottle(kVerySlowThrottleDuration),
          keys: [albumId],
        ).data ??
        this.album;

    if (album == null) {
      return Column(
        children: [
          _StickerAlbumHeader(album: album),
          const Expanded(child: SizedBox()),
        ],
      );
    }

    return Column(
      children: [
        _StickerAlbumHeader(album: album),
        Expanded(
          child: _StickerAlbumDetail(
            album: album,
            stickers: stickers,
          ),
        ),
      ],
    );
  }
}

class _StickerAlbumHeader extends StatelessWidget {
  const _StickerAlbumHeader({this.album});

  final StickerAlbum? album;

  @override
  Widget build(BuildContext context) => MixinAppBar(
        backgroundColor: Colors.transparent,
        title: Text(album == null
            ? context.l10n.stickerAlbumDetail
            : (album?.name ?? '')),
        leading: navigatorKey.currentState?.canPop() == true
            ? null
            : const SizedBox(),
        actions: [
          MixinCloseButton(
            onTap: () => Navigator.maybeOf(context, rootNavigator: true)?.pop(),
          ),
        ],
      );
}

class _StickerAlbumDetail extends HookWidget {
  const _StickerAlbumDetail({
    this.stickers,
    required this.album,
  });

  final StickerAlbum album;
  final List<Sticker>? stickers;

  @override
  Widget build(BuildContext context) {
    final stickers = useMemoizedFuture(() async {
          if (this.stickers != null) return this.stickers;
          return context.database.stickerDao
              .stickerByAlbumId(album.albumId)
              .get();
        }, <Sticker>[], keys: [album.albumId]).data ??
        [];
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomScrollView(
          slivers: [
            _StickerAlbumDetailBody(stickers: stickers),
            const SliverPadding(padding: EdgeInsets.only(bottom: 112)),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          height: 93,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.theme.popUp.withOpacity(0),
                  context.theme.popUp.withOpacity(0.36),
                  context.theme.popUp.withOpacity(1),
                ],
              ),
            ),
            child: Column(
              children: [
                const Spacer(),
                MixinButton(
                  backgroundColor: album.added == true
                      ? context.theme.red
                      : context.theme.accent,
                  child: Text(
                    album.added == true
                        ? context.l10n.removeStickers
                        : context.l10n.addStickers,
                  ),
                  onTap: () => context.database.stickerAlbumDao
                      .updateAdded(album.albumId, !(album.added == true)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StickerAlbumDetailBody extends StatelessWidget {
  const _StickerAlbumDetailBody({
    required this.stickers,
  });

  final List<Sticker> stickers;

  @override
  Widget build(BuildContext context) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 8,
          ),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => StickerItem(
              assetType: stickers[index].assetType,
              assetUrl: stickers[index].assetUrl,
            ),
            childCount: stickers.length,
          ),
        ),
      );
}
