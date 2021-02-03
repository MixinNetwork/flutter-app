import 'package:bloc/bloc.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/db/dao/sticker_albums_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';

class SystemAlbumsCubit extends Cubit<List<StickerAlbum>> with SubscribeMixin {
  SystemAlbumsCubit(StickerAlbumsDao stickerAlbumsDao) : super(const []) {
    addSubscription(
      stickerAlbumsDao.systemAlbums().watch().distinct().listen(emit),
    );
  }
}
