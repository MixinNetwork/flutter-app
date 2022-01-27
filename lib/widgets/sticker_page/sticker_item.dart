import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lottie/lottie.dart';

import '../../utils/app_lifecycle.dart';
import '../cache_image.dart';

class StickerItem extends HookWidget {
  const StickerItem({
    Key? key,
    required this.assetUrl,
    required this.assetType,
    this.placeholder,
    this.width,
    this.height,
  }) : super(key: key);

  final String assetUrl;
  final String? assetType;
  final Widget? placeholder;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    late Widget child;
    final playing = useState(false);
    final isJson = useMemoized(() => assetType == 'json', [assetType]);
    final controller = useAnimationController();

    final listener = useCallback(() {
      if (isJson && controller.duration == null) return;
      if (isAppActive) {
        if (isJson) controller.repeat();
        playing.value = true;
      } else {
        if (isJson) controller.stop();
        playing.value = false;
      }
    }, [controller]);

    useEffect(() {
      listener();
      appActiveListener.addListener(listener);
      return () => appActiveListener.removeListener(listener);
    }, [controller, appActiveListener]);

    if (isJson) {
      child = Lottie.network(
        assetUrl,
        controller: controller,
        height: height,
        width: width,
        fit: BoxFit.cover,
        onLoaded: (composition) {
          controller.duration = composition.duration;
          listener();
        },
      );
    } else {
      child = CacheImage(
        assetUrl,
        height: height,
        width: width,
        controller: playing,
        placeholder: () => placeholder ?? const SizedBox(),
      );
    }

    if (width == null || height == null) {
      return AspectRatio(aspectRatio: 1, child: child);
    }

    return child;
  }
}
