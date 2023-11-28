import 'dart:ui';

import 'package:video_compress/video_compress.dart';

final IVideoCompress customVideoCompress = _CustomVideoCompress();

class _CustomVideoCompress extends IVideoCompress {
  _CustomVideoCompress() {
    if (RootIsolateToken.instance != null) {
      initProcessCallback();
    }
  }
}
