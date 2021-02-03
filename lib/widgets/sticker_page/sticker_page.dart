import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/bloc/int_cubit.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/constants/resources.dart';

import '../brightness_observer.dart';
import '../cache_image.dart';
import '../interacter_decorated_box.dart';
import 'bloc/cubit/system_albums_cubit.dart';

class StickerPage extends StatelessWidget {
  const StickerPage({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stickerAlbumsDao =
        Provider.of<AccountServer>(context).database.stickerAlbumsDao;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SystemAlbumsCubit(stickerAlbumsDao),
        ),
        BlocProvider(
          create: (context) => IntCubit(0),
        ),
      ],
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
              const Expanded(child: SizedBox()),
              Container(
                width: double.infinity,
                height: 60,
                color: BrightnessData.dynamicColor(
                  context,
                  const Color.fromRGBO(0, 0, 0, 0.05),
                  darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
                ),
                child: Center(
                  child:
                      BlocConverter<SystemAlbumsCubit, List<StickerAlbum>, int>(
                    converter: (state) => state?.length ?? 0,
                    builder: (context, systemAlbumsCount) => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3 + systemAlbumsCount,
                      itemBuilder: (BuildContext context, int index) =>
                          SizedBox.fromSize(
                        size: const Size.square(50),
                        child: Center(
                          child: SizedBox.fromSize(
                            size: const Size.square(40),
                            child: BlocConverter<IntCubit, int, bool>(
                              converter: (state) => state == index,
                              builder: (context, selected) =>
                                  InteractableDecoratedBox(
                                onTap: () => BlocProvider.of<IntCubit>(context)
                                    .emit(index),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? BrightnessData.dynamicColor(
                                          context,
                                          const Color.fromRGBO(
                                              229, 231, 235, 1),
                                          darkColor: const Color.fromRGBO(
                                              255, 255, 255, 0.06),
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Builder(
                                    builder: (context) {
                                      if (index < 3) {
                                        return SvgPicture.asset(
                                          {
                                            0: Resources
                                                .assetsImagesRecentStickerSvg,
                                            1: Resources
                                                .assetsImagesPersonalStickerSvg,
                                            2: Resources
                                                .assetsImagesGifStickerSvg
                                          }[index],
                                        );
                                      }

                                      return BlocConverter<SystemAlbumsCubit,
                                          List<StickerAlbum>, String>(
                                        converter: (state) =>
                                            state[index - 3].iconUrl,
                                        builder: (context, iconUrl) {
                                          return CacheImage(iconUrl);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
