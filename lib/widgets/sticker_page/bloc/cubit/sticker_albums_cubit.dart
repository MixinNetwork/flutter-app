import '../../../../bloc/stream_cubit.dart';
import '../../../../db/mixin_database.dart';

class StickerAlbumsCubit extends StreamCubit<List<StickerAlbum>> {
  StickerAlbumsCubit(Stream<List<StickerAlbum>> stream) : super([], stream);
}
