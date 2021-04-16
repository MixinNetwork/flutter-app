import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
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
    Key? key,
    this.tabController,
    required this.stickerAlbumsCubit,
  }) : super(key: key);

  final TabController? tabController;
  final StickerAlbumsCubit stickerAlbumsCubit;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: Builder(
          builder: (context) => Container(
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
              child: BlocConverter<StickerAlbumsCubit, List<StickerAlbum>, int>(
                converter: (state) => (state.length) + 2,
                builder: (context, tabLength) => Column(
                  children: [
                    Expanded(
                      child: TabBarView(
                        controller: tabController,
                        children: List.generate(
                          tabLength,
                          (index) => _StickerAlbumPage(index: index),
                        ),
                      ),
                    ),
                    _StickerAlbumBar(
                      tabLength: tabLength,
                      tabController: tabController,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _StickerAlbumPage extends StatelessWidget {
  const _StickerAlbumPage({
    Key? key,
    required this.index,
  }) : super(key: key);

  final int index;

  @override
  Widget build(BuildContext context) {
    final stickerDao = Provider.of<AccountServer>(context).database.stickerDao;
    if (index == 1) {
      // todo can add or delete
    }
    final updateUsedAt = index != 0;
    final rightClickDelete = index == 1;
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
          default:
            stream = stickerDao
                .stickerByAlbumId(BlocProvider.of<StickerAlbumsCubit>(context)
                    .state[index - 2]
                    .albumId)
                .watch();
        }
        return StickerCubit(stream);
      },
      child: Builder(
        builder: (context) => BlocConverter<StickerCubit, List<Sticker>, int>(
          converter: (state) => state.length,
          builder: (context, itemCount) => GridView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: itemCount,
            itemBuilder: (BuildContext context, int index) =>
                _StickerAlbumPageItem(
              index: index,
              updateUsedAt: updateUsedAt,
              rightClickDelete: rightClickDelete,
            ),
          ),
        ),
      ),
    );
  }
}

class _StickerAlbumPageItem extends StatelessWidget {
  const _StickerAlbumPageItem({
    Key? key,
    required this.index,
    required this.updateUsedAt,
    this.rightClickDelete = false,
  }) : super(key: key);

  final int index;
  final bool updateUsedAt;
  final bool rightClickDelete;

  @override
  Widget build(BuildContext context) =>
      BlocConverter<StickerCubit, List<Sticker>, Sticker>(
        converter: (state) => state[index],
        builder: (BuildContext context, Sticker sticker) =>
            InteractableDecoratedBox(
          child: CacheImage(sticker.assetUrl),
          onTap: () async {
            final accountServer =
                Provider.of<AccountServer>(context, listen: false);
            final conversationItem =
                context.read<ConversationCubit>().state;
            if (conversationItem == null) return;

            await Future.wait([
              if (updateUsedAt)
                accountServer.database.stickerDao
                    .updateUsedAt(sticker.stickerId, DateTime.now()),
              accountServer.sendStickerMessage(
                sticker.stickerId,
                conversationId: conversationItem.conversationId,
              ),
            ]);
          },
          onRightClick: (pointerUpEvent) async {
            if (!rightClickDelete) return;
            // todo use native context menu.
          },
        ),
      );
}

class _StickerAlbumBar extends StatelessWidget {
  const _StickerAlbumBar({
    Key? key,
    required this.tabLength,
    this.tabController,
  }) : super(key: key);

  final int tabLength;
  final TabController? tabController;

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
          controller: tabController,
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
    Key? key,
    required this.index,
  }) : super(key: key);

  final int index;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
        size: const Size.square(50),
        child: Center(
          child: Center(
            child: Builder(
              builder: (context) {
                if (index < 2) {
                  return SvgPicture.asset(
                    {
                      0: Resources.assetsImagesRecentStickerSvg,
                      1: Resources.assetsImagesPersonalStickerSvg,
                      // todo
                      // 2: Resources.assetsImagesGifStickerSvg
                    }[index]!,
                    width: 24,
                    height: 24,
                  );
                }

                return BlocConverter<StickerAlbumsCubit, List<StickerAlbum>,
                    String>(
                  converter: (state) => state[index - 2].iconUrl,
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
