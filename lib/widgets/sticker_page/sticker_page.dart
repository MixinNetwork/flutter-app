import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/bloc/stream_cubit.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/widgets/interacter_decorated_box.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/constants/resources.dart';

import '../brightness_observer.dart';
import '../cache_image.dart';
import 'bloc/cubit/sticker_albums_cubit.dart';
import 'bloc/cubit/sticker_cubit.dart';

class StickerPage extends StatelessWidget {
  const StickerPage({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stickerAlbumsDao =
        Provider.of<AccountServer>(context).database.stickerAlbumsDao;

    return Material(
      color: Colors.transparent,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                StickerAlbumsCubit(stickerAlbumsDao.systemAlbums().watch()),
          ),
        ],
        child: Builder(
          builder: (context) =>
              BlocConverter<StickerAlbumsCubit, List<StickerAlbum>, int>(
            converter: (state) => (state?.length ?? 0) + 3,
            builder: (context, tabLength) => DefaultTabController(
              length: tabLength,
              child: Container(
                width: 464,
                height: 407,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: BrightnessData.dynamicColor(
                    context,
                    const Color.fromRGBO(255, 255, 255, 1),
                    darkColor: const Color.fromRGBO(62, 65, 72, 1),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Column(
                    children: [
                      Expanded(
                        child: TabBarView(
                          children: List.generate(
                            tabLength,
                            (index) => _StickerAlbumPage(index: index),
                          ),
                        ),
                      ),
                      _StickerAlbumBar(tabLength: tabLength),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StickerAlbumPage extends StatelessWidget {
  const _StickerAlbumPage({
    Key key,
    this.index,
  }) : super(key: key);

  final int index;

  @override
  Widget build(BuildContext context) {
    final stickerDao = Provider.of<AccountServer>(context).database.stickerDao;
    if (index == 1) {
      // todo can add or delete
    }
    if (index == 2) {
      // todo
    }
    return BlocProvider(
      create: (context) {
        Stream<List<Sticker>> stream;
        switch (index) {
          case 0:
            stream = stickerDao.recentUsedStickers().watch();
            break;
          case 1:
            stream = stickerDao.personalStickers().watch();
            break;
          case 2:
            stream = stickerDao.personalStickers().watch();
            break;
          default:
            stream = stickerDao
                .stickerByAlbumId(BlocProvider.of<StickerAlbumsCubit>(context)
                    .state[index - 3]
                    .albumId)
                .watch();
        }
        return StickerCubit(stream);
      },
      child: Builder(
        builder: (context) => BlocConverter<StickerCubit, List<Sticker>, int>(
          converter: (state) => state?.length ?? 0,
          builder: (context, itemCount) => GridView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: itemCount,
            itemBuilder: (BuildContext context, int index) =>
                _StickerAlbumPageItem(index: index),
          ),
        ),
      ),
    );
  }
}

class _StickerAlbumPageItem extends StatelessWidget {
  const _StickerAlbumPageItem({
    Key key,
    this.index,
  }) : super(key: key);

  final int index;

  @override
  Widget build(BuildContext context) =>
      BlocConverter<StickerCubit, List<Sticker>, Sticker>(
        converter: (state) => state[index],
        builder: (BuildContext context, Sticker sticker) =>
            InteractableDecoratedBox(
          child: CacheImage(sticker.assetUrl),
          onTap: () {
            // todo send sticker
          },
        ),
      );
}

class _StickerAlbumBar extends StatelessWidget {
  const _StickerAlbumBar({
    Key key,
    this.tabLength,
  }) : super(key: key);

  final int tabLength;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: 50,
        color: BrightnessData.dynamicColor(
          context,
          const Color.fromRGBO(0, 0, 0, 0.05),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
        ),
        child: TabBar(
          isScrollable: true,
          indicator: BoxDecoration(
            color: BrightnessData.dynamicColor(
              context,
              const Color.fromRGBO(229, 231, 235, 1),
              darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          labelPadding: EdgeInsets.zero,
          indicatorPadding: const EdgeInsets.all(5),
          tabs: List.generate(
            tabLength,
            (index) => _StickerAlbumBarItem(index: index),
          ),
        ),
      );
}

class _StickerAlbumBarItem extends StatelessWidget {
  const _StickerAlbumBarItem({
    Key key,
    this.index,
  }) : super(key: key);

  final int index;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
        size: const Size.square(50),
        child: Center(
          child: Center(
            child: Builder(
              builder: (context) {
                if (index < 3) {
                  return SvgPicture.asset(
                    {
                      0: Resources.assetsImagesRecentStickerSvg,
                      1: Resources.assetsImagesPersonalStickerSvg,
                      2: Resources.assetsImagesGifStickerSvg
                    }[index],
                    width: 24,
                    height: 24,
                  );
                }

                return BlocConverter<StickerAlbumsCubit, List<StickerAlbum>,
                    String>(
                  converter: (state) => state[index - 3].iconUrl,
                  builder: (context, iconUrl) => CacheImage(
                    iconUrl,
                    width: 28,
                    height: 28,
                  ),
                );
              },
            ),
          ),
        ),
      );
}
