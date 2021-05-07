import '../../../../bloc/stream_cubit.dart';
import '../../../../db/mixin_database.dart';

class StickerCubit extends StreamCubit<List<Sticker>> {
  StickerCubit(Stream<List<Sticker>> stream) : super([], stream);
}
