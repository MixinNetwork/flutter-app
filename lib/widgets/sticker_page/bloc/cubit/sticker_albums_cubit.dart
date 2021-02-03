import 'package:flutter_app/bloc/stream_cubit.dart';
import 'package:flutter_app/db/mixin_database.dart';

class StickerAlbumsCubit extends StreamCubit<List<StickerAlbum>> {
  StickerAlbumsCubit(Stream<List<StickerAlbum>> stream) : super([], stream);
}
