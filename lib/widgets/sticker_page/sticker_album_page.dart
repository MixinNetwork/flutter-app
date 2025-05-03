import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../app_bar.dart';
import '../buttons.dart';
import '../dialog.dart';
import 'sticker_item.dart';
import 'sticker_store.dart';

class StickerAlbumPage extends HookConsumerWidget {
  const StickerAlbumPage({
    required this.albumId,
    super.key,
    this.album,
    this.stickers,
  });

  final StickerAlbum? album;
  final List<Sticker>? stickers;
  final String albumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final album =
        useMemoizedStream(
          () => context.database.stickerAlbumDao
              .album(albumId)
              .watchSingleWithStream(
                eventStreams: [
                  DataBaseEventBus.instance.watchUpdateStickerStream(
                    albumIds: [albumId],
                  ),
                ],
                duration: kVerySlowThrottleDuration,
              ),
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
        Expanded(child: _StickerAlbumDetail(album: album, stickers: stickers)),
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
    title: Text(
      album == null ? context.l10n.stickerAlbumDetail : (album?.name ?? ''),
    ),
    leading:
        navigatorKey.currentState?.canPop() == true ? null : const SizedBox(),
    actions: [
      MixinCloseButton(
        onTap: () => Navigator.maybeOf(context, rootNavigator: true)?.pop(),
      ),
    ],
  );
}

class _StickerAlbumDetail extends HookConsumerWidget {
  const _StickerAlbumDetail({required this.album, this.stickers});

  final StickerAlbum album;
  final List<Sticker>? stickers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stickers =
        useMemoizedFuture(
          () async {
            if (this.stickers != null) return this.stickers;
            return context.database.stickerDao
                .stickerByAlbumId(album.albumId)
                .get();
          },
          <Sticker>[],
          keys: [album.albumId],
        ).data ??
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
                  context.theme.popUp.withValues(alpha: 0),
                  context.theme.popUp.withValues(alpha: 0.36),
                  context.theme.popUp.withValues(alpha: 1),
                ],
              ),
            ),
            child: Column(
              children: [
                const Spacer(),
                MixinButton(
                  backgroundColor:
                      album.added == true
                          ? context.theme.red
                          : context.theme.accent,
                  child: Text(
                    album.added == true
                        ? context.l10n.removeStickers
                        : context.l10n.addStickers,
                  ),
                  onTap:
                      () => context.database.stickerAlbumDao.updateAdded(
                        album.albumId,
                        !(album.added == true),
                      ),
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
  const _StickerAlbumDetailBody({required this.stickers});

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
